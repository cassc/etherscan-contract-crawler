// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IPoolRewards.sol";

interface IEarnDrip is IPoolRewards {
    function rewardTokens(uint256 _index) external view returns (address);

    function growToken() external view returns (address);
}