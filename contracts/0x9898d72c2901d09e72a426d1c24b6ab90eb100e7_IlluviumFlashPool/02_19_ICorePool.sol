// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IPool.sol";

interface ICorePool is IPool {
    function vaultRewardsPerToken() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);

    function stakeAsPool(address _staker, uint256 _amount) external;

    function receiveVaultRewards(uint256 _amount) external;
}