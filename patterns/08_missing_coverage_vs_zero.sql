-- 08: What should parcel screening report when coverage is missing?
--
-- This is a SYNTHETIC demonstration. Parcel 4 intentionally has no
-- observation coverage. Its missing value must stay NULL/unknown, not zero.
-- For parcels 1-3, we demonstrate countable service-site observations
-- inside the synthetic parcel polygons; absence there can be zero observed
-- sites but NEVER establishes environmental safety or absence of hazards.
-- Every coordinate is from the repo's existing fictional fixture.
--
-- This example does not use actual EO imagery, risk values, environmental
-- approvals, or private property records. "Coverage" below is a fixture
-- input for the lesson, not proof of a real dataset's spatial footprint.

CREATE OR REPLACE VIEW parcel_observation_summary AS
WITH coverage AS (
    SELECT parcel_id,
           parcel_id <> 4 AS coverage_available
    FROM parcels
)
SELECT
    p.parcel_id,
    CASE WHEN c.coverage_available
         THEN 'observed_sites'
         ELSE 'unknown_missing_coverage'
    END AS observation_status,
    CASE WHEN c.coverage_available
         THEN count(s.site_id)
         ELSE CAST(NULL AS BIGINT)
    END AS observed_site_count
FROM parcels AS p
JOIN coverage AS c ON p.parcel_id = c.parcel_id
LEFT JOIN service_sites AS s
    ON c.coverage_available
   AND ST_Within(s.geom, p.geom)
GROUP BY p.parcel_id, c.coverage_available;

SELECT parcel_id, observation_status, observed_site_count
FROM parcel_observation_summary
ORDER BY parcel_id;
