// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVault is IERC20 {
    function earn(address _bountyHunter) external returns (uint256);

    function deposit(address _user, uint256 _depositAmount) external;

    function withdraw(address _user, uint256 _withdrawAmount) external;

    function stakeToken() external view returns (address);

    function totalStakeTokens() external view returns (uint256);
}