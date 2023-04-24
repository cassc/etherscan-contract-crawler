// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library RebateCalculator {
    uint256 constant UONE = 1e18;

    function calculateTierRebate(
        uint256 startFee,
        uint256 startRate,
        uint256 endFee,
        uint256 endRate,
        uint256 fee
    ) internal pure returns (uint256 currentRate, uint256 tierRebate) {
        require(fee >= startFee && fee < endFee, "wrong tier");
        currentRate =
            ((fee - startFee) * (endRate - startRate)) /
            (endFee - startFee) +
            startRate;
        tierRebate =
            (((currentRate + startRate) / 2) * (fee - startFee)) /
            UONE;
    }

    // Fee Ranges and Rates:
    // Fee range >= 10000: rate = 40%
    // Fee range >= 6000 and < 10000: rate = [32%, 40%]
    // Fee range >= 4000 and < 6000: rate = [28%, 32%]
    // Fee range >= 2000 and < 4000: rate = [24%, 28%]
    // Fee range >= 1000 and < 2000: rate = [20%, 24%]
    // Fee range >= 10 and < 1000: rate = 20%
    function calculateTotalRebate(
        uint256 fee
    ) internal pure returns (uint256 currentRate, uint256 totalRebate) {
        uint256 tierRebate;
        if (fee >= 10000 * UONE) {
            currentRate = 400000000000000000;
            totalRebate =
                ((fee - 10000 * UONE) * currentRate) /
                UONE +
                2980 *
                UONE;
        } else if (fee >= 6000 * UONE && fee < 10000 * UONE) {
            (currentRate, tierRebate) = calculateTierRebate(
                6000 * UONE,
                320000000000000000,
                10000 * UONE,
                400000000000000000,
                fee
            );
            totalRebate = tierRebate + 1540 * UONE;
        } else if (fee >= 4000 * UONE && fee < 6000 * UONE) {
            (currentRate, tierRebate) = calculateTierRebate(
                4000 * UONE,
                280000000000000000,
                6000 * UONE,
                320000000000000000,
                fee
            );
            totalRebate = tierRebate + 940 * UONE;
        } else if (fee >= 2000 * UONE && fee < 4000 * UONE) {
            (currentRate, tierRebate) = calculateTierRebate(
                2000 * UONE,
                240000000000000000,
                4000 * UONE,
                280000000000000000,
                fee
            );
            totalRebate = tierRebate + 420 * UONE;
        } else if (fee >= 1000 * UONE && fee < 2000 * UONE) {
            (currentRate, tierRebate) = calculateTierRebate(
                1000 * UONE,
                200000000000000000,
                2000 * UONE,
                240000000000000000,
                fee
            );
            totalRebate = tierRebate + 200 * UONE;
        } else if (fee >= 10 * UONE && fee < 1000 * UONE) {
            currentRate = 200000000000000000;
            totalRebate = (fee * currentRate) / UONE;
        }
    }

    function calculateTotalBrokerRebate(
        uint256 fee
    )
        internal
        pure
        returns (uint256 currentBrokerRate, uint256 totalBrokerRebate)
    {
        (uint256 currentRate, uint256 totalRebate) = calculateTotalRebate(fee);
        currentBrokerRate = (currentRate * 900000000000000000) / UONE;
        totalBrokerRebate = (totalRebate * 900000000000000000) / UONE;
    }

    function calculateTotalRecruiterRebate(
        uint256 fee
    ) internal pure returns (uint256 currentRecruiterRate, uint256 totalRecruiterRebate) {
        (uint256 currentRate, uint256 totalRebate) = calculateTotalRebate(fee);
        currentRecruiterRate = (currentRate * 100000000000000000) / UONE;
        totalRecruiterRebate = (totalRebate * 100000000000000000) / UONE;
    }
}