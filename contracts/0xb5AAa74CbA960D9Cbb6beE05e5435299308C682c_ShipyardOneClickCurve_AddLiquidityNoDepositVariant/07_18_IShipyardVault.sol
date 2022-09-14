// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShipyardVault is IERC20 {

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function strategy() external returns (address);
}