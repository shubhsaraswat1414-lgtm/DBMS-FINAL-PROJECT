// ============================================================================
// CASE STUDY 123 — NoSQL Part (MongoDB)
// Newspaper Vendor Delivery and Subscription
// ============================================================================

// Switch to project database
db = db.getSiblingDB('newspaper_vendor');

// Clean up
db.households_embedded.drop();
db.households_referenced.drop();
db.deliveries_referenced.drop();

// ============================================================================
// 1. EMBEDDED MODEL — One household with all its deliveries inside
//    The document is self-contained: a single read returns everything about
//    Household 1 (its details + all delivery records) without any secondary
//    lookups.  The trade-off is that household and publication information
//    must be duplicated inside every delivery sub-document.
// ============================================================================

db.households_embedded.insertOne({
  _id: 1,
  name: "Household - Kharadi Society",
  city: "Guwahati",
  monthly_bill_rs: 770,
  deliveries: [
    {
      delivery_id: 1,
      household_id: 1,          // DUPLICATED from parent document
      household_name: "Household - Kharadi Society",  // DUPLICATED from parent
      household_city: "Guwahati",                     // DUPLICATED from parent
      publication_id: 1,
      publication_name: "Times of India",              // DUPLICATED from publications
      price_per_copy_rs: 6,                            // DUPLICATED from publications
      frequency: "daily",                              // DUPLICATED from publications
      papers_delivered: 4,
      delivery_date: "2024-01-08"
    },
    {
      delivery_id: 2,
      household_id: 1,
      household_name: "Household - Kharadi Society",
      household_city: "Guwahati",
      publication_id: 1,
      publication_name: "Times of India",
      price_per_copy_rs: 6,
      frequency: "daily",
      papers_delivered: 1,
      delivery_date: "2024-01-19"
    },
    {
      delivery_id: 3,
      household_id: 1,
      household_name: "Household - Kharadi Society",
      household_city: "Guwahati",
      publication_id: 2,
      publication_name: "Malayala Manorama",
      price_per_copy_rs: 5,
      frequency: "daily",
      papers_delivered: 3,
      delivery_date: "2024-01-25"
    },
    {
      delivery_id: 4,
      household_id: 1,
      household_name: "Household - Kharadi Society",
      household_city: "Guwahati",
      publication_id: 1,
      publication_name: "Times of India",
      price_per_copy_rs: 6,
      frequency: "daily",
      papers_delivered: 2,
      delivery_date: "2024-02-05"
    },
    {
      delivery_id: 5,
      household_id: 1,
      household_name: "Household - Kharadi Society",
      household_city: "Guwahati",
      publication_id: 4,
      publication_name: "Hindustan Times",
      price_per_copy_rs: 6,
      frequency: "daily",
      papers_delivered: 3,
      delivery_date: "2024-02-15"
    },
    {
      delivery_id: 6,
      household_id: 1,
      household_name: "Household - Kharadi Society",
      household_city: "Guwahati",
      publication_id: 1,
      publication_name: "Times of India",
      price_per_copy_rs: 6,
      frequency: "daily",
      papers_delivered: 1,
      delivery_date: "2024-03-01"
    }
  ]
});

// Duplicated fields — complete list:
//
// FROM households (parent → every sub-document):
//   household_id    — the parent's _id repeated inside each delivery
//   household_name  — the parent's name repeated inside each delivery
//   household_city  — the parent's city repeated inside each delivery
//
// FROM publications (a separate entity → every sub-document):
//   publication_name   — denormalised from the publications catalogue
//   price_per_copy_rs  — denormalised from the publications catalogue
//   frequency          — denormalised from the publications catalogue
//
// Why duplicate?  So that a single db.households_embedded.findOne({_id:1})
// returns the household AND all its deliveries with full publication details,
// without needing a second query to the publications collection.


// ============================================================================
// 2. REFERENCED MODEL — Household and deliveries in separate collections
//    Only IDs/references are stored, no field duplication.
//    This mirrors the relational (SQL) design more closely.
// ============================================================================

db.households_referenced.insertOne({
  _id: 1,
  name: "Household - Kharadi Society",
  city: "Guwahati",
  monthly_bill_rs: 770
});

db.deliveries_referenced.insertMany([
  { _id: 1, household_id: 1, publication_id: 1, papers_delivered: 4, delivery_date: "2024-01-08" },
  { _id: 2, household_id: 1, publication_id: 1, papers_delivered: 1, delivery_date: "2024-01-19" },
  { _id: 3, household_id: 1, publication_id: 2, papers_delivered: 3, delivery_date: "2024-01-25" },
  { _id: 4, household_id: 1, publication_id: 1, papers_delivered: 2, delivery_date: "2024-02-05" },
  { _id: 5, household_id: 1, publication_id: 4, papers_delivered: 3, delivery_date: "2024-02-15" },
  { _id: 6, household_id: 1, publication_id: 1, papers_delivered: 1, delivery_date: "2024-03-01" }
]);


// ============================================================================
// 3. COMPARE — "Find all delivery rows for one household"
// ============================================================================

// --- EMBEDDED: Single document read (1 query) ---
print("\n=== EMBEDDED MODEL: Find all deliveries for Household 1 ===");
db.households_embedded.findOne(
  { _id: 1 },
  { name: 1, "deliveries.delivery_date": 1, "deliveries.papers_delivered": 1, "deliveries.publication_name": 1 }
);

// --- REFERENCED: Two queries needed ---
print("\n=== REFERENCED MODEL: Find all deliveries for Household 1 ===");
// Query 1: Get the household
db.households_referenced.findOne({ _id: 1 });
// Query 2: Get its deliveries
db.deliveries_referenced.find({ household_id: 1 }).toArray();

// Comparison:
//
//   Embedded Model:
//     - 1 read: findOne({_id:1}) returns the household AND all 6 deliveries
//       in a single disk seek / network round-trip.
//     - Trade-off: publication_name, price, frequency, and household fields
//       are duplicated in every sub-document.  If a publication price changes,
//       every copy inside every household document must be updated.
//
//   Referenced Model:
//     - 2 reads: first findOne({_id:1}) for the household, then
//       find({household_id:1}) for its deliveries — two separate queries.
//     - Trade-off: no duplication, so updates (e.g., price changes) happen in
//       one place.  But the extra query adds latency and application-level
//       joining is needed to combine the results.
//
//   Verdict for this case study:
//     Embedded is better for READ-heavy operations like "show me everything
//     about Household 1", which is the vendor's most common lookup.
//     Referenced is better when publications change often or when deliveries
//     are queried independently of households.


// ============================================================================
// 4. GRAPH DATABASE VIEW (JSON sketch)
//    This is a simplified illustrative sample — it contains only 3 households
//    and 3 publications from the full SQL dataset, enough to demonstrate the
//    node-edge concept without reproducing the entire database.
//
//    Nodes: Household, Publication
//    Edges: DELIVERED (a delivery event connecting a household to a publication)
// ============================================================================

print("\n=== GRAPH DATABASE VIEW ===");

var graphNodes = [
  { label: "Household",   id: 1, name: "Household - Kharadi Society", city: "Guwahati" },
  { label: "Household",   id: 2, name: "Household - Wagholi Colony",  city: "Mumbai" },
  { label: "Household",   id: 3, name: "Household - Viman Nagar",     city: "Pune" },
  { label: "Publication", id: 1, name: "Times of India",    price: 6 },
  { label: "Publication", id: 2, name: "Malayala Manorama", price: 5 },
  { label: "Publication", id: 3, name: "India Today",       price: 50 }
];

var graphEdges = [
  { type: "DELIVERED", from: "Household:1", to: "Publication:1", papers: 4, date: "2024-01-08" },
  { type: "DELIVERED", from: "Household:1", to: "Publication:1", papers: 1, date: "2024-01-19" },
  { type: "DELIVERED", from: "Household:1", to: "Publication:2", papers: 3, date: "2024-01-25" },
  { type: "DELIVERED", from: "Household:2", to: "Publication:3", papers: 4, date: "2024-02-02" },
  { type: "DELIVERED", from: "Household:3", to: "Publication:1", papers: 2, date: "2024-02-14" }
];

printjson({ nodes: graphNodes, edges: graphEdges });

// Traversal query (replaces a relational JOIN):
//
// In SQL, "Find all publications delivered to Household 1" requires:
//   SELECT DISTINCT p.publication_name
//   FROM daily_deliveries dd
//   JOIN publications p ON dd.publication_id = p.id
//   WHERE dd.household_id = 1;
//
// In a graph database (e.g. Neo4j), the same query is a single traversal:
//   MATCH (h:Household {id:1})-[:DELIVERED]->(p:Publication)
//   RETURN DISTINCT p.name
//
// No JOIN is needed — the graph engine simply follows the DELIVERED edges
// outward from the Household node and collects the connected Publication nodes.
// This is more natural for relationship-heavy queries and avoids the cost of
// hash/merge joins on large datasets.


// ============================================================================
// 5. CAP THEOREM — This system should prioritise: CP (Consistency + Partition
//    Tolerance)
//
//    Why CP and not AP or CA?
//
//    Consistency (C): Every billing record must accurately reflect actual
//      deliveries.  If a household's delivery record is read as inconsistent
//      (e.g., a delivery is written to one replica but not yet visible on
//      another), the computed bill will be wrong — the vendor either
//      overcharges or undercharges the customer.  For a billing system, this
//      is unacceptable.
//
//    Partition Tolerance (P): In any multi-data-centre or distributed
//      deployment, network partitions will eventually occur.  The system must
//      continue to function correctly when they do.  Choosing CA (sacrificing
//      P) is not realistic for a distributed system — the CAP theorem says
//      partitions are a fact of life, not a choice.
//
//    Availability (sacrificed): Under a network partition, the CP system may
//      refuse to serve reads/writes rather than serve stale or inconsistent
//      data.  A delayed bill (generated after the partition heals) is far
//      preferable to a wrong bill.
//
//    Lost vs Delayed delivery record:
//    - Lost record = delivery happened but is permanently missing from the
//      database.  The monthly bill will be permanently under-calculated.
//      The vendor loses revenue with no way to recover it.  Unacceptable.
//    - Delayed record = delivery is eventually recorded after a short delay
//      (e.g., due to a partition).  The bill for that day may be generated
//      slightly later, but the final amount is correct.  Tolerable.
//
//    Therefore: prefer CP.  Accept brief unavailability to guarantee that
//    every delivery record is consistent and no billing data is lost.
// ============================================================================


// ============================================================================
// 6. BASE vs ACID
//
//    daily_deliveries → ACID is essential.
//      Each delivery row directly affects billing.  If a delivery INSERT is
//      only partially committed (e.g., the row is written but the billing
//      aggregation is not updated), the monthly bill will be incorrect.
//      ACID guarantees (Atomicity, Consistency, Isolation, Durability) ensure
//      that either the full delivery+billing update succeeds or nothing
//      changes.  In financial/billing contexts, partial state is a bug.
//
//    households (catalogue) → BASE is tolerable.
//      The households table is a slowly-changing master list — names and
//      cities rarely change.  If a name update takes a few seconds to
//      propagate across replicas (eventual consistency), no financial harm
//      occurs.  The billing calculations do not depend on the household name;
//      they depend on household_id, which never changes.
//      BASE properties (Basically Available, Soft-state, Eventually
//      consistent) are acceptable here because the cost of brief staleness
//      is negligible.
// ============================================================================


// ============================================================================
// 7. Query a pure key-value store would struggle with:
//
//    "Show total revenue per publication across all households"
//    (This is Query 7 in project.sql)
//
//    In SQL:
//      SELECT p.publication_name,
//             SUM(dd.papers_delivered * p.price_per_copy_rs) AS total_revenue
//      FROM daily_deliveries dd
//      JOIN publications p ON dd.publication_id = p.id
//      GROUP BY p.publication_name;
//
//    Why a key-value store struggles:
//    A key-value store (e.g. Redis, DynamoDB in KV mode) indexes data by a
//    single primary key (e.g. delivery_id).  To answer "total revenue per
//    publication", the application would need to:
//      1. Scan ALL delivery records (no secondary index on publication_id).
//      2. For each delivery, issue a separate lookup to get the publication
//         price (another key-based read).
//      3. Aggregate the results manually in application code.
//    This turns a single SQL query into potentially thousands of reads and
//    an application-level GROUP BY — far less efficient and more complex.
// ============================================================================


// ============================================================================
// 8. DESIGN DECISIONS — Summary
//
//    Why four SQL tables?
//      Normalisation to 3NF eliminates redundancy.  Changing a publication
//      price updates exactly one row in `publications`, not hundreds of
//      delivery rows.  This is the standard relational approach for a billing
//      system where data integrity matters most.
//
//    Why embedded MongoDB for the read path?
//      The vendor's most frequent operation is "look up one household and see
//      its deliveries."  Embedding delivers this in a single document read.
//      The duplication cost is acceptable because publication prices change
//      rarely and the dataset is small.
//
//    Why referenced MongoDB for the write path?
//      When a new delivery is recorded, the referenced model only inserts one
//      document into deliveries_referenced — no need to find-and-update a
//      household document.  This is simpler and avoids the risk of exceeding
//      MongoDB's 16 MB document size limit for households with thousands of
//      deliveries.
//
//    Why CP over AP?
//      A billing system cannot tolerate inconsistent reads.  A delayed
//      response is fixable; a wrong bill erodes customer trust.
//
//    Why ACID for daily_deliveries?
//      Deliveries are financial events.  Partial commits produce wrong bills.
//      The households catalogue is not financially sensitive, so eventual
//      consistency (BASE) is fine there.
// ============================================================================


print("\n=== NoSQL script completed successfully ===");
