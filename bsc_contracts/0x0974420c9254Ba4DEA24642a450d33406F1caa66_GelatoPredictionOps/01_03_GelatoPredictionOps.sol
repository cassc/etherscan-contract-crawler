pragma solidity ^0.8.13;

import "./IResolver.sol";

import "./IPredictionOpsManager.sol";

contract GelatoPredictionOps is IResolver {
    IPredictionOpsManager public predictionOpsManager;

    constructor(IPredictionOpsManager _predictionOpsManager) {
        predictionOpsManager = _predictionOpsManager;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        // solhint-disable not-rely-on-time
        canExec = predictionOpsManager.canPerformTask(20);

        execPayload = abi.encodeWithSignature("execute()", predictionOpsManager);
    }
}