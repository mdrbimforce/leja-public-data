// ============================================================
// LEJA BRAIN - AuraDB Import Script
// Source: nodes.csv + relationships.csv via leja-public-data repo
// Requires: APOC Core (apoc.convert.fromJsonMap)
// ============================================================

// --- STAP 0: Constraints aanmaken ---
// Uniek constraint op _nodeId voor LOAD CSV matching
CREATE CONSTRAINT node_id_unique IF NOT EXISTS
FOR (n:_Import) REQUIRE n._nodeId IS UNIQUE;

// --- STAP 1: Alle nodes importeren ---
// Eerst alle nodes als :_Import aanmaken met _nodeId property
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/nodes.csv' AS row
CALL {
  WITH row
  CREATE (n:_Import {_nodeId: row._nodeId})
  WITH n, row, apoc.convert.fromJsonMap(row._properties) AS props
  SET n += props
  WITH n, row
  CALL apoc.create.addLabels(n, split(row._labels, ';')) YIELD node
  RETURN node
} IN TRANSACTIONS OF 500 ROWS
RETURN count(*) AS nodes_imported;

// --- STAP 2: Constraint verwijderen, cleanup label ---
// Na import: verwijder het _Import label en constraint
// (eerst relaties aanmaken in stap 3, dan cleanup in stap 4)

// --- STAP 3: Alle relaties importeren ---
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  WITH a, b, row, apoc.convert.fromJsonMap(row._properties) AS props
  CALL apoc.create.relationship(a, row._type, props, b) YIELD rel
  RETURN rel
} IN TRANSACTIONS OF 500 ROWS
RETURN count(*) AS rels_imported;

// --- STAP 4: Cleanup import labels ---
MATCH (n:_Import)
REMOVE n:_Import
REMOVE n._nodeId
RETURN count(n) AS cleaned;

// Drop het import constraint
DROP CONSTRAINT node_id_unique IF EXISTS;

// --- STAP 5: Verificatie ---
// Tel nodes per domain
MATCH (n) RETURN n.domain AS domain, count(n) AS nodes ORDER BY nodes DESC;

// Tel relaties
MATCH ()-[r]->() RETURN count(r) AS total_rels;

// Bootstrap test
MATCH (leja:LejaIdentity {name: "Leja"})
OPTIONAL MATCH (leja)-[:HAS_STATE]->(state:LejaState {is_current: true})
RETURN leja.name, state.active_focus, state.session_count;