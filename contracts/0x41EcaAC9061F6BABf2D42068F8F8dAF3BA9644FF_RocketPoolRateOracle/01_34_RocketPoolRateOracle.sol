// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/IRocketPoolRateOracle.sol";
import "../interfaces/rocketPool/IRocketEth.sol";
import "../interfaces/rocketPool/IRocketNetworkBalances.sol";
import "../rate_oracles/BaseRateOracle.sol";
import "../utils/WadRayMath.sol";
import "hardhat/console.sol";

contract RocketPoolRateOracle is BaseRateOracle, IRocketPoolRateOracle {
    IRocketEth public override rocketEth;
    IRocketNetworkBalances public override rocketNetworkBalances;

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 4; // id of RocketPool is 4

    constructor(
        IRocketEth _rocketEth,
        IRocketNetworkBalances _rocketNetworkBalances,
        IWETH _weth,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(IERC20Minimal(address(_weth))) {
        // Underlying is ETH, so no address needed
        require(address(_rocketEth) != address(0), "RETH must exist");
        rocketEth = _rocketEth;

        require(
            address(_rocketNetworkBalances) != address(0),
            "RNB must exist"
        );
        rocketNetworkBalances = _rocketNetworkBalances;

        _populateInitialObservations(_times, _results);
    }

    /// @inheritdoc BaseRateOracle
    function getLastUpdatedRate()
        public
        view
        override
        returns (uint32 timestamp, uint256 resultRay)
    {
        resultRay = rocketEth.getEthValue(WadRayMath.RAY);
        if (resultRay == 0) {
            revert CustomErrors.RocketPoolGetEthValueReturnedZero();
        }

        // RocketPool can only give us a block number of the most recent update
        // We estimate a timestamp using recent blocks-per-second data
        uint256 lastUpdatedBlockNumber = rocketNetworkBalances
            .getBalancesBlock();
        (uint256 blockChange, uint32 timeChange) = getBlockSlope();

        // console.log("block.number in getting last updated rate", block.number);
        // console.log(
        //     "block.timestamp in getting last updated rate",
        //     block.timestamp
        // );
        // console.log("blockChange", blockChange);
        // console.log("timeChange", timeChange);

        uint256 lastUpdatedTimestamp = block.timestamp -
            ((block.number - lastUpdatedBlockNumber) * timeChange) /
            blockChange;

        return (Time.timestampAsUint32(lastUpdatedTimestamp), resultRay);
    }
}