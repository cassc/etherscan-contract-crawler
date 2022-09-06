// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolAccountantUpgrader is UpgraderBase {
    constructor(address _multicall)
        UpgraderBase(_multicall) // solhint-disable-next-line no-empty-blocks
    {}

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](5);
        calls[0] = abi.encodeWithSignature("pool()");
        calls[1] = abi.encodeWithSignature("totalDebtRatio()");
        calls[2] = abi.encodeWithSignature("totalDebt()");
        calls[3] = abi.encodeWithSignature("getStrategies()");
        calls[4] = abi.encodeWithSignature("getWithdrawQueue()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        address beforePool = abi.decode(_beforeResults[0], (address));
        uint256 beforeTotalDebtRatio = abi.decode(_beforeResults[1], (uint256));
        uint256 beforeTotalDebt = abi.decode(_beforeResults[2], (uint256));
        address[] memory beforeGetStrategies = abi.decode(_beforeResults[3], (address[]));
        address[] memory beforeGetWithdrawQueue = abi.decode(_beforeResults[4], (address[]));

        address afterPool = abi.decode(_afterResults[0], (address));
        uint256 afterTotalDebtRatio = abi.decode(_afterResults[1], (uint256));
        uint256 afterTotalDebt = abi.decode(_afterResults[2], (uint256));
        address[] memory afterGetStrategies = abi.decode(_afterResults[3], (address[]));
        address[] memory afterGetWithdrawQueue = abi.decode(_afterResults[4], (address[]));

        require(
            beforePool == afterPool && beforeTotalDebtRatio == afterTotalDebtRatio && beforeTotalDebt == afterTotalDebt,
            "simple-fields-test-failed"
        );
        require(
            beforeGetStrategies.length == afterGetStrategies.length &&
                beforeGetWithdrawQueue.length == afterGetWithdrawQueue.length,
            "dynamic-fields-test-failed"
        );
    }
}