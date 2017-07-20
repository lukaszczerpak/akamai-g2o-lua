require "akamai-g2o"

describe("Akamai G2O Signature Verification", function()
    it("[v1] checks if they're equals", function()
        local expected = "FWvsJT8JBKvnZ4jGiE7uYA=="
        local obj = akamai_g2o_versions[1]("s3cr3tk3y", "1, 1.2.3.4, 3.4.5.6, 1471524574, 2805760.691583751, v1", "/abc")
        assert.are.equals(expected, obj)
    end)
    it("[v2] checks if they're equals", function()
        local expected = "LL4EzlYZG9DWKjDYegZf7Q=="
        local obj = akamai_g2o_versions[2]("s3cr3tk3y", "2, 1.2.3.4, 3.4.5.6, 1471524574, 2805760.691583751, v1", "/abc")
        assert.are.equals(expected, obj)
    end)
    it("[v3] checks if they're equals", function()
        local expected = "D2+ASTlqs3WfCC5EBIhtjA=="
        local obj = akamai_g2o_versions[3]("s3cr3tk3y", "3, 1.2.3.4, 3.4.5.6, 1471524574, 2805760.691583751, v1", "/abc")
        assert.are.equals(expected, obj)
    end)
    it("[v4] checks if they're equals", function()
        local expected = "OLU/4N3Sc5gvy7Ta/e1rzMgPb2g="
        local obj = akamai_g2o_versions[4]("s3cr3tk3y", "4, 1.2.3.4, 3.4.5.6, 1471524574, 2805760.691583751, v1", "/abc")
        assert.are.equals(expected, obj)
    end)
    it("[v5] checks if they're equals", function()
        local expected = "d/8DhQppXfD8WvbEP5TU3UVrPxgifX4LumVfadVPxgk="
        local obj = akamai_g2o_versions[5]("s3cr3tk3y", "5, 1.2.3.4, 3.4.5.6, 1471524574, 2805760.691583751, v1", "/abc")
        assert.are.equals(expected, obj)
    end)
end)

describe("Akamai G2O Time Verification", function()
    it("checks future date within the delta", function()
        local expected = true
        local got = akamai_g2o_timestamp_verify("1, 1.2.3.4, 3.4.5.6, 1471524584, 2805760.691583751, v1", "1471524574", 20)
        assert.are.equals(expected, got)
    end)
    it("checks past date within the delta", function()
        local expected = true
        local got = akamai_g2o_timestamp_verify("1, 1.2.3.4, 3.4.5.6, 1471524564, 2805760.691583751, v1", "1471524574", 20)
        assert.are.equals(expected, got)
    end)
    it("checks future date outside the delta", function()
        local expected = false
        local got = akamai_g2o_timestamp_verify("1, 1.2.3.4, 3.4.5.6, 1471524595, 2805760.691583751, v1", "1471524574", 20)
        assert.are.equals(expected, got)
    end)
    it("checks past date outside the delta", function()
        local expected = false
        local got = akamai_g2o_timestamp_verify("1, 1.2.3.4, 3.4.5.6, 1471524553, 2805760.691583751, v1", "1471524574", 20)
        assert.are.equals(expected, got)
    end)
end)
