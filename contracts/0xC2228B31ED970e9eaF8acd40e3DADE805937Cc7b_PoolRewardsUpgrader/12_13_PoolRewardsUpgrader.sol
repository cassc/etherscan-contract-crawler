// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolRewardsUpgrader is UpgraderBase {
    constructor(address _multicall)
        UpgraderBase(_multicall) // solhint-disable-next-line no-empty-blocks
    {}

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](3);
        calls[0] = abi.encodeWithSignature("pool()");
        calls[1] = abi.encodeWithSignature("getRewardTokens()");
        calls[2] = abi.encodeWithSignature("rewardPerToken()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        address beforePool = abi.decode(_beforeResults[0], (address));
        address[] memory beforeRewardToken = abi.decode(_beforeResults[1], (address[]));
        (, address[] memory beforeRewardPerToken) = abi.decode(_beforeResults[2], (address[], address[]));

        address afterPool = abi.decode(_afterResults[0], (address));
        address[] memory afterRewardToken = abi.decode(_afterResults[1], (address[]));
        (, address[] memory afterRewardPerToken) = abi.decode(_afterResults[2], (address[], address[]));

        require(beforePool == afterPool, "fields-test-failed");
        require(
            beforeRewardToken.length == afterRewardToken.length &&
                beforeRewardToken[0] == afterRewardToken[0] &&
                beforeRewardPerToken[0] == afterRewardPerToken[0],
            "methods-test-failed"
        );
    }
}