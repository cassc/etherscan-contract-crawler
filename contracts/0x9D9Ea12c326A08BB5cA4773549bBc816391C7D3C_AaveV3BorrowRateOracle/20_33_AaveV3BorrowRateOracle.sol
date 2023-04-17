// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/IAaveV3RateOracle.sol";
import "../interfaces/aave/IAaveV3LendingPool.sol";
import "../rate_oracles/CompoundingRateOracle.sol";

contract AaveV3BorrowRateOracle is CompoundingRateOracle, IAaveV3RateOracle {
    /// @inheritdoc IAaveV3RateOracle
    IAaveV3LendingPool public override aaveLendingPool;

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 9; // id of aave borrow v3 is 9

    constructor(
        IAaveV3LendingPool _aaveLendingPool,
        IERC20Minimal _underlying,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(_underlying) {
        require(
            address(_aaveLendingPool) != address(0),
            "aave v3 pool must exist"
        );
        // Check that underlying was set in BaseRateOracle
        require(address(underlying) != address(0), "underlying must exist");
        aaveLendingPool = _aaveLendingPool;

        _populateInitialObservations(_times, _results, true);
    }

    /// @inheritdoc BaseRateOracle
    function getLastUpdatedRate()
        public
        view
        override
        returns (uint32 timestamp, uint256 resultRay)
    {
        resultRay = aaveLendingPool.getReserveNormalizedVariableDebt(
            underlying
        );
        if (resultRay == 0) {
            revert CustomErrors
                .AaveV3PoolGetReserveNormalizedVariableDebtReturnedZero();
        }

        return (Time.blockTimestampTruncated(), resultRay);
    }
}