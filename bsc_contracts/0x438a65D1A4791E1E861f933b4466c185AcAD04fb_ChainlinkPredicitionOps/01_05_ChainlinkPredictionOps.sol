pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "./IPredictionOpsManager.sol";

contract ChainlinkPredicitionOps is KeeperCompatibleInterface {
    IPredictionOpsManager public predictionOpsManager;

    constructor(IPredictionOpsManager _predictionOpsManager) {
        predictionOpsManager = _predictionOpsManager;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = predictionOpsManager.canPerformTask(0);
    }

    function performUpkeep(bytes calldata) external override {
        predictionOpsManager.execute();
    }
}