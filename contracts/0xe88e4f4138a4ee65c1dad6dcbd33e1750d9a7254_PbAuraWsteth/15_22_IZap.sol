// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBalancer.sol";

interface IZap {
    function depositSingle(
        address _rewardPoolAddress,
        address _inputToken,
        uint256 _inputAmount,
        bytes32 _balancerPoolId,
        IBalancer.JoinPoolRequest memory _request
    ) external;
}