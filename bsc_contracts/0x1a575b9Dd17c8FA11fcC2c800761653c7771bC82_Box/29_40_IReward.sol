// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Common.sol";

interface IReward {
    event RewardProcess(uint256 amount);
    event RewardWithdraw(address indexed withdrawer, uint256 amount);

    function processReward(
        NameValuePair[] calldata depositParams,
        NameValuePair[] calldata reapRewardParams
    ) external;

    function withdrawReward(NameValuePair[] calldata withdrawParams) external;
}