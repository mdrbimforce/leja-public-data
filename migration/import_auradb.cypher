// ============================================================================
// LEJA AURADB IMPORT SCRIPT
// ============================================================================
// Deze script importeert de Leja-kennisgraaf van GitHub naar AuraDB Free.
//
// BENADERING:
// 1. Alle nodes worden eerst als :_Import geladen met properties
// 2. Labels worden dinamisch toegekend o.b.v. _labels kolom
// 3. Relaties worden per type aangemaakt (mét transactionele batching)
// 4. Cleanup: _Import label en temp properties verwijderen
// 5. Verificatie: Schema en statistieken controleren
//
// CSV BRONNEN:
// - Nodes: https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/nodes.csv
// - Rels: https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv
//
// CONSTRAINTS:
// - AuraDB Free: APOC Core beschikbaar (apoc.convert.fromJsonMap)
// - GEEN APOC Extended (geen apoc.create.addLabels, apoc.create.relationship)
// - Puur Cypher voor labels en relaties
// - Transactionele batching: 500 rows per batch
// ============================================================================


// ============================================================================
// STAP 0: CONSTRAINTS INSTELLEN
// ============================================================================
CREATE CONSTRAINT node_id_unique IF NOT EXISTS FOR (n:_Import) REQUIRE n._nodeId IS UNIQUE;


// ============================================================================
// STAP 1: ALLE NODES IMPORTEREN ALS :_Import
// ============================================================================
// Laad alle nodes van GitHub, parse JSON properties, bewaar labels voor stap 2
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/nodes.csv' AS row
CALL {
  WITH row
  CREATE (n:_Import)
  SET n._nodeId = row._nodeId, n._labels = row._labels
  WITH n, row
  SET n += apoc.convert.fromJsonMap(row._properties)
  RETURN count(n) AS imported
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(imported) AS total_nodes_imported;


// ============================================================================
// STAP 2: LABELS TOEKENNEN (99 Labels)
// ============================================================================
// Voor elk label: match alle nodes waar dit label in _labels voorkomt,
// en voeg het label toe

MATCH (n:_Import) WHERE 'Actor' IN split(n._labels, ';') SET n:Actor;
MATCH (n:_Import) WHERE 'AssetSet' IN split(n._labels, ';') SET n:AssetSet;
MATCH (n:_Import) WHERE 'AssetTemplate' IN split(n._labels, ';') SET n:AssetTemplate;
MATCH (n:_Import) WHERE 'Assets' IN split(n._labels, ';') SET n:Assets;
MATCH (n:_Import) WHERE 'Check' IN split(n._labels, ';') SET n:Check;
MATCH (n:_Import) WHERE 'CheckItem' IN split(n._labels, ';') SET n:CheckItem;
MATCH (n:_Import) WHERE 'Classification' IN split(n._labels, ';') SET n:Classification;
MATCH (n:_Import) WHERE 'Classificationset' IN split(n._labels, ';') SET n:Classificationset;
MATCH (n:_Import) WHERE 'ClassificationsetSet' IN split(n._labels, ';') SET n:ClassificationsetSet;
MATCH (n:_Import) WHERE 'ClassificationsetTemplate' IN split(n._labels, ';') SET n:ClassificationsetTemplate;
MATCH (n:_Import) WHERE 'Classificationsets' IN split(n._labels, ';') SET n:Classificationsets;
MATCH (n:_Import) WHERE 'Company' IN split(n._labels, ';') SET n:Company;
MATCH (n:_Import) WHERE 'Compliance' IN split(n._labels, ';') SET n:Compliance;
MATCH (n:_Import) WHERE 'ComplianceTemplate' IN split(n._labels, ';') SET n:ComplianceTemplate;
MATCH (n:_Import) WHERE 'Department' IN split(n._labels, ';') SET n:Department;
MATCH (n:_Import) WHERE 'Document' IN split(n._labels, ';') SET n:Document;
MATCH (n:_Import) WHERE 'DocumentSet' IN split(n._labels, ';') SET n:DocumentSet;
MATCH (n:_Import) WHERE 'DocumentTemplate' IN split(n._labels, ';') SET n:DocumentTemplate;
MATCH (n:_Import) WHERE 'Documents' IN split(n._labels, ';') SET n:Documents;
MATCH (n:_Import) WHERE 'Export' IN split(n._labels, ';') SET n:Export;
MATCH (n:_Import) WHERE 'ExportSet' IN split(n._labels, ';') SET n:ExportSet;
MATCH (n:_Import) WHERE 'ExportTemplate' IN split(n._labels, ';') SET n:ExportTemplate;
MATCH (n:_Import) WHERE 'Exports' IN split(n._labels, ';') SET n:Exports;
MATCH (n:_Import) WHERE 'File' IN split(n._labels, ';') SET n:File;
MATCH (n:_Import) WHERE 'Filter' IN split(n._labels, ';') SET n:Filter;
MATCH (n:_Import) WHERE 'FilterSet' IN split(n._labels, ';') SET n:FilterSet;
MATCH (n:_Import) WHERE 'FilterTemplate' IN split(n._labels, ';') SET n:FilterTemplate;
MATCH (n:_Import) WHERE 'Filters' IN split(n._labels, ';') SET n:Filters;
MATCH (n:_Import) WHERE 'FrameworkSet' IN split(n._labels, ';') SET n:FrameworkSet;
MATCH (n:_Import) WHERE 'Frameworks' IN split(n._labels, ';') SET n:Frameworks;
MATCH (n:_Import) WHERE 'GRiDS' IN split(n._labels, ';') SET n:GRiDS;
MATCH (n:_Import) WHERE 'IfcAttribute' IN split(n._labels, ';') SET n:IfcAttribute;
MATCH (n:_Import) WHERE 'IfcClass' IN split(n._labels, ';') SET n:IfcClass;
MATCH (n:_Import) WHERE 'IfcClassification' IN split(n._labels, ';') SET n:IfcClassification;
MATCH (n:_Import) WHERE 'IfcClassifications' IN split(n._labels, ';') SET n:IfcClassifications;
MATCH (n:_Import) WHERE 'IfcMaterials' IN split(n._labels, ';') SET n:IfcMaterials;
MATCH (n:_Import) WHERE 'IfcProperties' IN split(n._labels, ';') SET n:IfcProperties;
MATCH (n:_Import) WHERE 'IfcProperty' IN split(n._labels, ';') SET n:IfcProperty;
MATCH (n:_Import) WHERE 'IfcPropertyset' IN split(n._labels, ';') SET n:IfcPropertyset;
MATCH (n:_Import) WHERE 'IfcUnits' IN split(n._labels, ';') SET n:IfcUnits;
MATCH (n:_Import) WHERE 'Image' IN split(n._labels, ';') SET n:Image;
MATCH (n:_Import) WHERE 'InitialCost' IN split(n._labels, ';') SET n:InitialCost;
MATCH (n:_Import) WHERE 'Label' IN split(n._labels, ';') SET n:Label;
MATCH (n:_Import) WHERE 'LabelSet' IN split(n._labels, ';') SET n:LabelSet;
MATCH (n:_Import) WHERE 'LabelTemplate' IN split(n._labels, ';') SET n:LabelTemplate;
MATCH (n:_Import) WHERE 'Labels' IN split(n._labels, ';') SET n:Labels;
MATCH (n:_Import) WHERE 'LegalFramework' IN split(n._labels, ';') SET n:LegalFramework;
MATCH (n:_Import) WHERE 'LejaAgent' IN split(n._labels, ';') SET n:LejaAgent;
MATCH (n:_Import) WHERE 'LejaAgentConfig' IN split(n._labels, ';') SET n:LejaAgentConfig;
MATCH (n:_Import) WHERE 'LejaAgentMessage' IN split(n._labels, ';') SET n:LejaAgentMessage;
MATCH (n:_Import) WHERE 'LejaAgentThread' IN split(n._labels, ';') SET n:LejaAgentThread;
MATCH (n:_Import) WHERE 'LejaAgents' IN split(n._labels, ';') SET n:LejaAgents;
MATCH (n:_Import) WHERE 'LejaBootstrapStep' IN split(n._labels, ';') SET n:LejaBootstrapStep;
MATCH (n:_Import) WHERE 'LejaBrainstormSpace' IN split(n._labels, ';') SET n:LejaBrainstormSpace;
MATCH (n:_Import) WHERE 'LejaConcept' IN split(n._labels, ';') SET n:LejaConcept;
MATCH (n:_Import) WHERE 'LejaConcepts' IN split(n._labels, ';') SET n:LejaConcepts;
MATCH (n:_Import) WHERE 'LejaConfigFile' IN split(n._labels, ';') SET n:LejaConfigFile;
MATCH (n:_Import) WHERE 'LejaContainer' IN split(n._labels, ';') SET n:LejaContainer;
MATCH (n:_Import) WHERE 'LejaDecision' IN split(n._labels, ';') SET n:LejaDecision;
MATCH (n:_Import) WHERE 'LejaDecisions' IN split(n._labels, ';') SET n:LejaDecisions;
MATCH (n:_Import) WHERE 'LejaDocument' IN split(n._labels, ';') SET n:LejaDocument;
MATCH (n:_Import) WHERE 'LejaHandoff' IN split(n._labels, ';') SET n:LejaHandoff;
MATCH (n:_Import) WHERE 'LejaHandoffStep' IN split(n._labels, ';') SET n:LejaHandoffStep;
MATCH (n:_Import) WHERE 'LejaIdea' IN split(n._labels, ';') SET n:LejaIdea;
MATCH (n:_Import) WHERE 'LejaIdeas' IN split(n._labels, ';') SET n:LejaIdeas;
MATCH (n:_Import) WHERE 'LejaIdentity' IN split(n._labels, ';') SET n:LejaIdentity;
MATCH (n:_Import) WHERE 'LejaInsight' IN split(n._labels, ';') SET n:LejaInsight;
MATCH (n:_Import) WHERE 'LejaInsights' IN split(n._labels, ';') SET n:LejaInsights;
MATCH (n:_Import) WHERE 'LejaKnowledge' IN split(n._labels, ';') SET n:LejaKnowledge;
MATCH (n:_Import) WHERE 'LejaKnowledgeBase' IN split(n._labels, ';') SET n:LejaKnowledgeBase;
MATCH (n:_Import) WHERE 'LejaLinkedInPost' IN split(n._labels, ';') SET n:LejaLinkedInPost;
MATCH (n:_Import) WHERE 'LejaMistake' IN split(n._labels, ';') SET n:LejaMistake;
MATCH (n:_Import) WHERE 'LejaMistakes' IN split(n._labels, ';') SET n:LejaMistakes;
MATCH (n:_Import) WHERE 'LejaPerson' IN split(n._labels, ';') SET n:LejaPerson;
MATCH (n:_Import) WHERE 'LejaPrinciple' IN split(n._labels, ';') SET n:LejaPrinciple;
MATCH (n:_Import) WHERE 'LejaPrinciples' IN split(n._labels, ';') SET n:LejaPrinciples;
MATCH (n:_Import) WHERE 'LejaProductSchema' IN split(n._labels, ';') SET n:LejaProductSchema;
MATCH (n:_Import) WHERE 'LejaProject' IN split(n._labels, ';') SET n:LejaProject;
MATCH (n:_Import) WHERE 'LejaProjects' IN split(n._labels, ';') SET n:LejaProjects;
MATCH (n:_Import) WHERE 'LejaProtocol' IN split(n._labels, ';') SET n:LejaProtocol;
MATCH (n:_Import) WHERE 'LejaProtocols' IN split(n._labels, ';') SET n:LejaProtocols;
MATCH (n:_Import) WHERE 'LejaQuest' IN split(n._labels, ';') SET n:LejaQuest;
MATCH (n:_Import) WHERE 'LejaQuestStep' IN split(n._labels, ';') SET n:LejaQuestStep;
MATCH (n:_Import) WHERE 'LejaQuests' IN split(n._labels, ';') SET n:LejaQuests;
MATCH (n:_Import) WHERE 'LejaRepositories' IN split(n._labels, ';') SET n:LejaRepositories;
MATCH (n:_Import) WHERE 'LejaRepository' IN split(n._labels, ';') SET n:LejaRepository;
MATCH (n:_Import) WHERE 'LejaResearchPaper' IN split(n._labels, ';') SET n:LejaResearchPaper;
MATCH (n:_Import) WHERE 'LejaSession' IN split(n._labels, ';') SET n:LejaSession;
MATCH (n:_Import) WHERE 'LejaSessionLog' IN split(n._labels, ';') SET n:LejaSessionLog;
MATCH (n:_Import) WHERE 'LejaSessionStep' IN split(n._labels, ';') SET n:LejaSessionStep;
MATCH (n:_Import) WHERE 'LejaSessions' IN split(n._labels, ';') SET n:LejaSessions;
MATCH (n:_Import) WHERE 'LejaSkill' IN split(n._labels, ';') SET n:LejaSkill;
MATCH (n:_Import) WHERE 'LejaState' IN split(n._labels, ';') SET n:LejaState;
MATCH (n:_Import) WHERE 'LejaTeamMember' IN split(n._labels, ';') SET n:LejaTeamMember;
MATCH (n:_Import) WHERE 'LejaTheme' IN split(n._labels, ';') SET n:LejaTheme;
MATCH (n:_Import) WHERE 'LejaThemes' IN split(n._labels, ';') SET n:LejaThemes;
MATCH (n:_Import) WHERE 'LejaTool' IN split(n._labels, ';') SET n:LejaTool;
MATCH (n:_Import) WHERE 'LejaTools' IN split(n._labels, ';') SET n:LejaTools;
MATCH (n:_Import) WHERE 'ManualOverride' IN split(n._labels, ';') SET n:ManualOverride;
MATCH (n:_Import) WHERE 'Mapping' IN split(n._labels, ';') SET n:Mapping;
MATCH (n:_Import) WHERE 'MappingSet' IN split(n._labels, ';') SET n:MappingSet;
MATCH (n:_Import) WHERE 'MappingTemplate' IN split(n._labels, ';') SET n:MappingTemplate;
MATCH (n:_Import) WHERE 'Mappings' IN split(n._labels, ';') SET n:Mappings;
MATCH (n:_Import) WHERE 'Model' IN split(n._labels, ';') SET n:Model;
MATCH (n:_Import) WHERE 'ModelSet' IN split(n._labels, ';') SET n:ModelSet;
MATCH (n:_Import) WHERE 'ModelTemplate' IN split(n._labels, ';') SET n:ModelTemplate;
MATCH (n:_Import) WHERE 'Models' IN split(n._labels, ';') SET n:Models;
MATCH (n:_Import) WHERE 'Object' IN split(n._labels, ';') SET n:Object;
MATCH (n:_Import) WHERE 'ObjectSet' IN split(n._labels, ';') SET n:ObjectSet;
MATCH (n:_Import) WHERE 'ObjectTemplate' IN split(n._labels, ';') SET n:ObjectTemplate;
MATCH (n:_Import) WHERE 'Objects' IN split(n._labels, ';') SET n:Objects;
MATCH (n:_Import) WHERE 'Observation' IN split(n._labels, ';') SET n:Observation;
MATCH (n:_Import) WHERE 'OperationalEnergyCost' IN split(n._labels, ';') SET n:OperationalEnergyCost;
MATCH (n:_Import) WHERE 'OperationalMaintenanceCost' IN split(n._labels, ';') SET n:OperationalMaintenanceCost;
MATCH (n:_Import) WHERE 'Phase' IN split(n._labels, ';') SET n:Phase;
MATCH (n:_Import) WHERE 'ProductSchema' IN split(n._labels, ';') SET n:ProductSchema;
MATCH (n:_Import) WHERE 'Projects' IN split(n._labels, ';') SET n:Projects;
MATCH (n:_Import) WHERE 'Properties' IN split(n._labels, ';') SET n:Properties;
MATCH (n:_Import) WHERE 'Property' IN split(n._labels, ';') SET n:Property;
MATCH (n:_Import) WHERE 'PropertySet' IN split(n._labels, ';') SET n:PropertySet;
MATCH (n:_Import) WHERE 'PropertyTemplate' IN split(n._labels, ';') SET n:PropertyTemplate;
MATCH (n:_Import) WHERE 'RenovationCost' IN split(n._labels, ';') SET n:RenovationCost;
MATCH (n:_Import) WHERE 'ReplacementCost' IN split(n._labels, ';') SET n:ReplacementCost;
MATCH (n:_Import) WHERE 'RequirementSet' IN split(n._labels, ';') SET n:RequirementSet;
MATCH (n:_Import) WHERE 'RequirementTemplate' IN split(n._labels, ';') SET n:RequirementTemplate;
MATCH (n:_Import) WHERE 'Requirements' IN split(n._labels, ';') SET n:Requirements;
MATCH (n:_Import) WHERE 'ResidualValue' IN split(n._labels, ';') SET n:ResidualValue;
MATCH (n:_Import) WHERE 'To' IN split(n._labels, ';') SET n:To;
MATCH (n:_Import) WHERE 'ToSet' IN split(n._labels, ';') SET n:ToSet;
MATCH (n:_Import) WHERE 'ToTemplate' IN split(n._labels, ';') SET n:ToTemplate;
MATCH (n:_Import) WHERE 'Tos' IN split(n._labels, ';') SET n:Tos;
MATCH (n:_Import) WHERE 'Unknown' IN split(n._labels, ';') SET n:Unknown;
MATCH (n:_Import) WHERE 'UserSet' IN split(n._labels, ';') SET n:UserSet;
MATCH (n:_Import) WHERE 'Users' IN split(n._labels, ';') SET n:Users;
MATCH (n:_Import) WHERE 'Value' IN split(n._labels, ';') SET n:Value;


// ============================================================================
// STAP 3: RELATIES AANMAKEN PER TYPE (130+ Types)
// ============================================================================
// Voor relaties met veel exemplaren: transactionele batching (500 rows)
// Voor relaties met weinig exemplaren: eenvoudige statements

// HAS_COST: 1038 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_COST'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_COST]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_COST;

// HAS_VALUE: 858 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_VALUE'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_VALUE]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_VALUE;

// HAS_PROPERTY: 812 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROPERTY'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_PROPERTY]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_PROPERTY;

// HAS_DOCUMENT: 250 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DOCUMENT'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_DOCUMENT]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_DOCUMENT;

// HAS_COMPLIANCE: 248 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_COMPLIANCE'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_COMPLIANCE]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_COMPLIANCE;

// HAS_CHECKITEM: 229 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CHECKITEM'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_CHECKITEM]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_CHECKITEM;

// HAS_ASSETSET: 192 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ASSETSET'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_ASSETSET]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_ASSETSET;

// HAS_LABEL: 184 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_LABEL'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_LABEL]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_LABEL;

// HAS_ASSETTEMPLATE: 179 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ASSETTEMPLATE'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_ASSETTEMPLATE]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_ASSETTEMPLATE;

// HAS_LEGALFRAMEWORK: 108 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_LEGALFRAMEWORK'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_LEGALFRAMEWORK]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_LEGALFRAMEWORK;

// HAS_ACTOR: 107 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ACTOR'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_ACTOR]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_ACTOR;

// HAS_STEP: 103 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_STEP'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_STEP]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_STEP;

// HAS_INSIGHT: 88 relaties -> batching
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_INSIGHT'
CALL {
  WITH row
  MATCH (a:_Import {_nodeId: row._startId})
  MATCH (b:_Import {_nodeId: row._endId})
  CREATE (a)-[:HAS_INSIGHT]->(b)
  RETURN count(*) AS created
} IN TRANSACTIONS OF 500 ROWS
RETURN sum(created) AS total_HAS_INSIGHT;

// HAS_PROPERTYTEMPLATE: 56 relaties -> geen batching nodig
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROPERTYTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROPERTYTEMPLATE]->(b)
RETURN count(*) AS total_HAS_PROPERTYTEMPLATE;

// HAS_IDEA: 52 relaties -> geen batching nodig
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_IDEA'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_IDEA]->(b)
RETURN count(*) AS total_HAS_IDEA;

// HAS_THEME: 50 relaties -> geen batching nodig
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_THEME'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_THEME]->(b)
RETURN count(*) AS total_HAS_THEME;

// RELATES_TO_PROJECT: 40 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'RELATES_TO_PROJECT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:RELATES_TO_PROJECT]->(b)
RETURN count(*) AS total_RELATES_TO_PROJECT;

// HAS_PRINCIPLE: 38 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PRINCIPLE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PRINCIPLE]->(b)
RETURN count(*) AS total_HAS_PRINCIPLE;

// HAS_COMPLIANCETEMPLATE: 34 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_COMPLIANCETEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_COMPLIANCETEMPLATE]->(b)
RETURN count(*) AS total_HAS_COMPLIANCETEMPLATE;

// HAS_ATTRIBUTE: 33 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ATTRIBUTE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_ATTRIBUTE]->(b)
RETURN count(*) AS total_HAS_ATTRIBUTE;

// LEARNED_IN: 31 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'LEARNED_IN'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:LEARNED_IN]->(b)
RETURN count(*) AS total_LEARNED_IN;

// HAS_CHECK: 31 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CHECK'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CHECK]->(b)
RETURN count(*) AS total_HAS_CHECK;

// HAS_REFERENCE: 31 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REFERENCE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REFERENCE]->(b)
RETURN count(*) AS total_HAS_REFERENCE;

// TRACKS: 30 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'TRACKS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:TRACKS]->(b)
RETURN count(*) AS total_TRACKS;

// HAS_QUEST: 30 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_QUEST'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_QUEST]->(b)
RETURN count(*) AS total_HAS_QUEST;

// NEXT: 29 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'NEXT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:NEXT]->(b)
RETURN count(*) AS total_NEXT;

// BELONGS_TO: 24 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'BELONGS_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:BELONGS_TO]->(b)
RETURN count(*) AS total_BELONGS_TO;

// CONTAINS: 22 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'CONTAINS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:CONTAINS]->(b)
RETURN count(*) AS total_CONTAINS;

// HAS_PROTOCOL: 16 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROTOCOL'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROTOCOL]->(b)
RETURN count(*) AS total_HAS_PROTOCOL;

// HAS_SESSION: 16 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_SESSION'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_SESSION]->(b)
RETURN count(*) AS total_HAS_SESSION;

// HAS_MISTAKE: 15 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MISTAKE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MISTAKE]->(b)
RETURN count(*) AS total_HAS_MISTAKE;

// ENABLES: 14 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'ENABLES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:ENABLES]->(b)
RETURN count(*) AS total_ENABLES;

// ILLUSTRATES: 14 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'ILLUSTRATES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:ILLUSTRATES]->(b)
RETURN count(*) AS total_ILLUSTRATES;

// HAS_FILTER: 14 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FILTER'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FILTER]->(b)
RETURN count(*) AS total_HAS_FILTER;

// LEARNED_FROM: 13 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'LEARNED_FROM'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:LEARNED_FROM]->(b)
RETURN count(*) AS total_LEARNED_FROM;

// HAS_TOOL: 12 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TOOL'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TOOL]->(b)
RETURN count(*) AS total_HAS_TOOL;

// RELATES_TO: 11 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'RELATES_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:RELATES_TO]->(b)
RETURN count(*) AS total_RELATES_TO;

// USES_CONFIG: 11 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'USES_CONFIG'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:USES_CONFIG]->(b)
RETURN count(*) AS total_USES_CONFIG;

// GENERALIZED_TO: 10 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'GENERALIZED_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:GENERALIZED_TO]->(b)
RETURN count(*) AS total_GENERALIZED_TO;

// HAS_CONCEPT: 10 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CONCEPT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CONCEPT]->(b)
RETURN count(*) AS total_HAS_CONCEPT;

// HAS_MAPPINGTEMPLATE: 9 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MAPPINGTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MAPPINGTEMPLATE]->(b)
RETURN count(*) AS total_HAS_MAPPINGTEMPLATE;

// USES: 8 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'USES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:USES]->(b)
RETURN count(*) AS total_USES;

// RELATED_TO: 7 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'RELATED_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:RELATED_TO]->(b)
RETURN count(*) AS total_RELATED_TO;

// HAS_FILTERTEMPLATE: 7 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FILTERTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FILTERTEMPLATE]->(b)
RETURN count(*) AS total_HAS_FILTERTEMPLATE;

// HAS_CLASSIFICATION: 7 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CLASSIFICATION'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CLASSIFICATION]->(b)
RETURN count(*) AS total_HAS_CLASSIFICATION;

// FOLLOWED_BY: 6 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'FOLLOWED_BY'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:FOLLOWED_BY]->(b)
RETURN count(*) AS total_FOLLOWED_BY;

// HAS_MAPPING: 6 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MAPPING'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MAPPING]->(b)
RETURN count(*) AS total_HAS_MAPPING;

// HAS_MANUALOVERRIDE: 6 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MANUALOVERRIDE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MANUALOVERRIDE]->(b)
RETURN count(*) AS total_HAS_MANUALOVERRIDE;

// HAS_MAPPINGSET: 5 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MAPPINGSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MAPPINGSET]->(b)
RETURN count(*) AS total_HAS_MAPPINGSET;

// HAS_LABELTEMPLATE: 5 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_LABELTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_LABELTEMPLATE]->(b)
RETURN count(*) AS total_HAS_LABELTEMPLATE;

// HAS_AGENT: 5 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_AGENT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_AGENT]->(b)
RETURN count(*) AS total_HAS_AGENT;

// HAS_CONFIG: 5 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CONFIG'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CONFIG]->(b)
RETURN count(*) AS total_HAS_CONFIG;

// HAS_MESSAGE: 5 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MESSAGE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MESSAGE]->(b)
RETURN count(*) AS total_HAS_MESSAGE;

// USED: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'USED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:USED]->(b)
RETURN count(*) AS total_USED;

// PRODUCED: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'PRODUCED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:PRODUCED]->(b)
RETURN count(*) AS total_PRODUCED;

// HAS_KNOWLEDGE: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_KNOWLEDGE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_KNOWLEDGE]->(b)
RETURN count(*) AS total_HAS_KNOWLEDGE;

// POSTED: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'POSTED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:POSTED]->(b)
RETURN count(*) AS total_POSTED;

// FEEDS_INTO: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'FEEDS_INTO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:FEEDS_INTO]->(b)
RETURN count(*) AS total_FEEDS_INTO;

// CONDUCTED: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'CONDUCTED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:CONDUCTED]->(b)
RETURN count(*) AS total_CONDUCTED;

// HAS_PROPERTYSET: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROPERTYSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROPERTYSET]->(b)
RETURN count(*) AS total_HAS_PROPERTYSET;

// HAS_TYPE: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TYPE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TYPE]->(b)
RETURN count(*) AS total_HAS_TYPE;

// HAS_PROJECT: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROJECT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROJECT]->(b)
RETURN count(*) AS total_HAS_PROJECT;

// HAS_DECISION: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DECISION'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DECISION]->(b)
RETURN count(*) AS total_HAS_DECISION;

// HAS_REPO: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REPO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REPO]->(b)
RETURN count(*) AS total_HAS_REPO;

// HAS_PHASE: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PHASE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PHASE]->(b)
RETURN count(*) AS total_HAS_PHASE;

// HAD_MISTAKE: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAD_MISTAKE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAD_MISTAKE]->(b)
RETURN count(*) AS total_HAD_MISTAKE;

// SPAWNED: 4 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'SPAWNED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:SPAWNED]->(b)
RETURN count(*) AS total_SPAWNED;

// PROMOTED_TO: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'PROMOTED_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:PROMOTED_TO]->(b)
RETURN count(*) AS total_PROMOTED_TO;

// HAS_CLASSIFICATIONSETTEMPLATE: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CLASSIFICATIONSETTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CLASSIFICATIONSETTEMPLATE]->(b)
RETURN count(*) AS total_HAS_CLASSIFICATIONSETTEMPLATE;

// HAS_FILTERSET: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FILTERSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FILTERSET]->(b)
RETURN count(*) AS total_HAS_FILTERSET;

// HAS_LABELSET: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_LABELSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_LABELSET]->(b)
RETURN count(*) AS total_HAS_LABELSET;

// HAS_CLASSIFICATIONSET: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CLASSIFICATIONSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CLASSIFICATIONSET]->(b)
RETURN count(*) AS total_HAS_CLASSIFICATIONSET;

// HAS_EXPORT: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_EXPORT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_EXPORT]->(b)
RETURN count(*) AS total_HAS_EXPORT;

// HAS_CLASSIFICATIONSETSET: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CLASSIFICATIONSETSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CLASSIFICATIONSETSET]->(b)
RETURN count(*) AS total_HAS_CLASSIFICATIONSETSET;

// HAS_EXPORTTEMPLATE: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_EXPORTTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_EXPORTTEMPLATE]->(b)
RETURN count(*) AS total_HAS_EXPORTTEMPLATE;

// HAS_FRAMEWORKSET: 3 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FRAMEWORKSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FRAMEWORKSET]->(b)
RETURN count(*) AS total_HAS_FRAMEWORKSET;

// DISCUSSED: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'DISCUSSED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:DISCUSSED]->(b)
RETURN count(*) AS total_DISCUSSED;

// ABOUT: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'ABOUT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:ABOUT]->(b)
RETURN count(*) AS total_ABOUT;

// HAS_PROJECTS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROJECTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROJECTS]->(b)
RETURN count(*) AS total_HAS_PROJECTS;

// IMPLEMENTED_BY: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'IMPLEMENTED_BY'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:IMPLEMENTED_BY]->(b)
RETURN count(*) AS total_IMPLEMENTED_BY;

// EXTENDS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'EXTENDS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:EXTENDS]->(b)
RETURN count(*) AS total_EXTENDS;

// FOR_PROJECT: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'FOR_PROJECT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:FOR_PROJECT]->(b)
RETURN count(*) AS total_FOR_PROJECT;

// HAS_THREAD: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_THREAD'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_THREAD]->(b)
RETURN count(*) AS total_HAS_THREAD;

// TARGETS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'TARGETS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:TARGETS]->(b)
RETURN count(*) AS total_TARGETS;

// HAS_DOCUMENTTEMPLATE: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DOCUMENTTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DOCUMENTTEMPLATE]->(b)
RETURN count(*) AS total_HAS_DOCUMENTTEMPLATE;

// HAS_MODELTEMPLATE: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MODELTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MODELTEMPLATE]->(b)
RETURN count(*) AS total_HAS_MODELTEMPLATE;

// HAS_TOTEMPLATE: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TOTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TOTEMPLATE]->(b)
RETURN count(*) AS total_HAS_TOTEMPLATE;

// HAS_DOCUMENTSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DOCUMENTSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DOCUMENTSET]->(b)
RETURN count(*) AS total_HAS_DOCUMENTSET;

// HAS_TOSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TOSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TOSET]->(b)
RETURN count(*) AS total_HAS_TOSET;

// HAS_REQUIREMENTSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REQUIREMENTSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REQUIREMENTSET]->(b)
RETURN count(*) AS total_HAS_REQUIREMENTSET;

// HAS_MODELSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MODELSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MODELSET]->(b)
RETURN count(*) AS total_HAS_MODELSET;

// REPLACED_BY: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'REPLACED_BY'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:REPLACED_BY]->(b)
RETURN count(*) AS total_REPLACED_BY;

// HAS_OBJECTSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_OBJECTSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_OBJECTSET]->(b)
RETURN count(*) AS total_HAS_OBJECTSET;

// HAS_EXPORTSET: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_EXPORTSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_EXPORTSET]->(b)
RETURN count(*) AS total_HAS_EXPORTSET;

// HAS_TOS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TOS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TOS]->(b)
RETURN count(*) AS total_HAS_TOS;

// HAS_LABELS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_LABELS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_LABELS]->(b)
RETURN count(*) AS total_HAS_LABELS;

// HAS_MODELS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MODELS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MODELS]->(b)
RETURN count(*) AS total_HAS_MODELS;

// HAS_DOCUMENTS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DOCUMENTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DOCUMENTS]->(b)
RETURN count(*) AS total_HAS_DOCUMENTS;

// HAS_PROPERTIES: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROPERTIES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROPERTIES]->(b)
RETURN count(*) AS total_HAS_PROPERTIES;

// HAS_EXPORTS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_EXPORTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_EXPORTS]->(b)
RETURN count(*) AS total_HAS_EXPORTS;

// HAS_FILTERS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FILTERS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FILTERS]->(b)
RETURN count(*) AS total_HAS_FILTERS;

// HAS_OBJECTS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_OBJECTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_OBJECTS]->(b)
RETURN count(*) AS total_HAS_OBJECTS;

// HAS_MAPPINGS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MAPPINGS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MAPPINGS]->(b)
RETURN count(*) AS total_HAS_MAPPINGS;

// HAS_REQUIREMENTS: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REQUIREMENTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REQUIREMENTS]->(b)
RETURN count(*) AS total_HAS_REQUIREMENTS;

// DEFINED_BY: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'DEFINED_BY'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:DEFINED_BY]->(b)
RETURN count(*) AS total_DEFINED_BY;

// HAS_SKILL: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_SKILL'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_SKILL]->(b)
RETURN count(*) AS total_HAS_SKILL;

// HAS_REPOSITORY: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REPOSITORY'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REPOSITORY]->(b)
RETURN count(*) AS total_HAS_REPOSITORY;

// SUPERSEDES: 2 relaties
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'SUPERSEDES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:SUPERSEDES]->(b)
RETURN count(*) AS total_SUPERSEDES;

// PART_OF: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'PART_OF'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:PART_OF]->(b)
RETURN count(*) AS total_PART_OF;

// HAS_STATE: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_STATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_STATE]->(b)
RETURN count(*) AS total_HAS_STATE;

// WORKS_FOR: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'WORKS_FOR'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:WORKS_FOR]->(b)
RETURN count(*) AS total_WORKS_FOR;

// HAS_INSIGHTS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_INSIGHTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_INSIGHTS]->(b)
RETURN count(*) AS total_HAS_INSIGHTS;

// HAS_QUESTS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_QUESTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_QUESTS]->(b)
RETURN count(*) AS total_HAS_QUESTS;

// HAS_MISTAKES: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MISTAKES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MISTAKES]->(b)
RETURN count(*) AS total_HAS_MISTAKES;

// HAS_PRINCIPLES: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PRINCIPLES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PRINCIPLES]->(b)
RETURN count(*) AS total_HAS_PRINCIPLES;

// HAS_DECISIONS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DECISIONS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DECISIONS]->(b)
RETURN count(*) AS total_HAS_DECISIONS;

// HAS_IDEAS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_IDEAS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_IDEAS]->(b)
RETURN count(*) AS total_HAS_IDEAS;

// HAS_TOOLS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TOOLS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TOOLS]->(b)
RETURN count(*) AS total_HAS_TOOLS;

// HAS_PROTOCOLS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PROTOCOLS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PROTOCOLS]->(b)
RETURN count(*) AS total_HAS_PROTOCOLS;

// HAS_AGENTS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_AGENTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_AGENTS]->(b)
RETURN count(*) AS total_HAS_AGENTS;

// HAS_SESSIONS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_SESSIONS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_SESSIONS]->(b)
RETURN count(*) AS total_HAS_SESSIONS;

// HAS_REPOSITORIES: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REPOSITORIES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REPOSITORIES]->(b)
RETURN count(*) AS total_HAS_REPOSITORIES;

// HAS_CONCEPTS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CONCEPTS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CONCEPTS]->(b)
RETURN count(*) AS total_HAS_CONCEPTS;

// HAS_THEMES: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_THEMES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_THEMES]->(b)
RETURN count(*) AS total_HAS_THEMES;

// CREATED: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'CREATED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:CREATED]->(b)
RETURN count(*) AS total_CREATED;

// NAMED: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'NAMED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:NAMED]->(b)
RETURN count(*) AS total_NAMED;

// CO_AUTHORED: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'CO_AUTHORED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:CO_AUTHORED]->(b)
RETURN count(*) AS total_CO_AUTHORED;

// WORKS_AT: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'WORKS_AT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:WORKS_AT]->(b)
RETURN count(*) AS total_WORKS_AT;

// INITIATED: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'INITIATED'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:INITIATED]->(b)
RETURN count(*) AS total_INITIATED;

// WORKS_ON: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'WORKS_ON'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:WORKS_ON]->(b)
RETURN count(*) AS total_WORKS_ON;

// VALIDATES: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'VALIDATES'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:VALIDATES]->(b)
RETURN count(*) AS total_VALIDATES;

// HAS_USERSET: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_USERSET'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_USERSET]->(b)
RETURN count(*) AS total_HAS_USERSET;

// HAS_FILE: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FILE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FILE]->(b)
RETURN count(*) AS total_HAS_FILE;

// HAS_TO: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_TO'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_TO]->(b)
RETURN count(*) AS total_HAS_TO;

// HAS_MODEL: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_MODEL'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_MODEL]->(b)
RETURN count(*) AS total_HAS_MODEL;

// HAS_ITEM: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ITEM'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_ITEM]->(b)
RETURN count(*) AS total_HAS_ITEM;

// HAS_CLASSIFICATIONSETS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_CLASSIFICATIONSETS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_CLASSIFICATIONSETS]->(b)
RETURN count(*) AS total_HAS_CLASSIFICATIONSETS;

// HAS_ASSETS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_ASSETS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_ASSETS]->(b)
RETURN count(*) AS total_HAS_ASSETS;

// HAS_IMAGE: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_IMAGE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_IMAGE]->(b)
RETURN count(*) AS total_HAS_IMAGE;

// HAS_USERS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_USERS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_USERS]->(b)
RETURN count(*) AS total_HAS_USERS;

// HAS_DEPARTMENT: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_DEPARTMENT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_DEPARTMENT]->(b)
RETURN count(*) AS total_HAS_DEPARTMENT;

// HAS_OBJECTTEMPLATE: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_OBJECTTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_OBJECTTEMPLATE]->(b)
RETURN count(*) AS total_HAS_OBJECTTEMPLATE;

// HAS_REQUIREMENTTEMPLATE: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_REQUIREMENTTEMPLATE'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_REQUIREMENTTEMPLATE]->(b)
RETURN count(*) AS total_HAS_REQUIREMENTTEMPLATE;

// HAS_OBJECT: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_OBJECT'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_OBJECT]->(b)
RETURN count(*) AS total_HAS_OBJECT;

// HAS_FRAMEWORKS: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_FRAMEWORKS'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_FRAMEWORKS]->(b)
RETURN count(*) AS total_HAS_FRAMEWORKS;

// HAS_SCHEMA: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_SCHEMA'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_SCHEMA]->(b)
RETURN count(*) AS total_HAS_SCHEMA;

// HAS_PRODUCT_DATA: 1 relatie
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/migration/relationships.csv' AS row
WITH row WHERE row._type = 'HAS_PRODUCT_DATA'
MATCH (a:_Import {_nodeId: row._startId})
MATCH (b:_Import {_nodeId: row._endId})
CREATE (a)-[:HAS_PRODUCT_DATA]->(b)
RETURN count(*) AS total_HAS_PRODUCT_DATA;


// ============================================================================
// STAP 4: CLEANUP
// ============================================================================
// Verwijder het :_Import label en temp properties van alle nodes
MATCH (n:_Import)
REMOVE n:_Import
REMOVE n._nodeId
REMOVE n._labels
RETURN count(n) AS cleaned_nodes;

// Verwijder de constraint
DROP CONSTRAINT node_id_unique IF EXISTS;


// ============================================================================
// STAP 5: VERIFICATIE
// ============================================================================
// Toon top 20 labels met aantal nodes
MATCH (n)
RETURN labels(n)[0] AS label, count(n) AS node_count
ORDER BY node_count DESC
LIMIT 20;

// Toon top 20 relatietype met aantal relaties
MATCH ()-[r]->()
RETURN type(r) AS relationship_type, count(r) AS rel_count
ORDER BY rel_count DESC
LIMIT 20;

// Verificatie: Controleer LejaIdentity en LejaState
MATCH (leja:LejaIdentity {name: "Leja"})
OPTIONAL MATCH (leja)-[:HAS_STATE]->(state:LejaState {is_current: true})
RETURN leja.name AS identity_name,
       state.active_focus AS current_focus,
       state.session_count AS session_count;

// Totaal aantal nodes en relaties
MATCH (n) RETURN count(n) AS total_nodes;
MATCH ()-[r]->() RETURN count(r) AS total_relationships;
