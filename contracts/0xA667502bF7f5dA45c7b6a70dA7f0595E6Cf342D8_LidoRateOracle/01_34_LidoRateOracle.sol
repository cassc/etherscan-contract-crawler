// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/ILidoRateOracle.sol";
import "../interfaces/lido/IStETH.sol";
import "../interfaces/lido/ILidoOracle.sol";
import "../rate_oracles/BaseRateOracle.sol";
import "../utils/WadRayMath.sol";
import "./OracleBuffer.sol";
import "../core_libraries/Time.sol";

contract LidoRateOracle is BaseRateOracle, ILidoRateOracle {
    IStETH public override stEth;

    // Lido info
    ILidoOracle public override lidoOracle;
    uint64 genesisTime; // From Beacon chain spec; changes rarely. `refreshBeaconSpec()` to update.
    uint64 secondsPerEpoch; // From Beacon chain spec; changes rarely. `refreshBeaconSpec()` to update.

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 3; // id of Lido is 3

    using OracleBuffer for OracleBuffer.Observation[65535];

    constructor(
        IStETH _stEth,
        ILidoOracle _lidoOracle,
        IWETH _weth,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(IERC20Minimal(address(_weth))) {
        // Underlying is ETH, so no address needed
        require(address(_stEth) != address(0), "stETH must exist");
        require(address(_lidoOracle) != address(0), "lidoOracle must exist");
        stEth = _stEth;
        lidoOracle = _lidoOracle;
        refreshBeaconSpec();

        _populateInitialObservations(_times, _results);
    }

    /// Refresh the beacon spec from Lido's oracle. Permissionless.
    function refreshBeaconSpec() public {
        (
            ,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 _genesisTime
        ) = lidoOracle.getBeaconSpec();
        genesisTime = _genesisTime;
        secondsPerEpoch = slotsPerEpoch * secondsPerSlot;
    }

    /// @inheritdoc BaseRateOracle
    function getLastUpdatedRate()
        public
        view
        override
        returns (uint32 timestamp, uint256 resultRay)
    {
        // We are taking advantage of the fact that Lido's implementation does not care about us passing in a
        // number of shares that is higher than the number of shared in existence.
        // The calculation that Lido does here would risk phantom overflow if Lido had > 10^50 ETH WEI staked
        // But that amount of ETH will never exist, so this is safe
        uint256 lastUpdatedRate = stEth.getPooledEthByShares(WadRayMath.RAY);
        if (lastUpdatedRate == 0) {
            revert CustomErrors.LidoGetPooledEthBySharesReturnedZero();
        }

        uint256 epoch = lidoOracle.getLastCompletedEpochId();

        uint32 lastCompletedTime = Time.timestampAsUint32(
            genesisTime + (epoch * secondsPerEpoch)
        );

        return (lastCompletedTime, lastUpdatedRate);
    }
}