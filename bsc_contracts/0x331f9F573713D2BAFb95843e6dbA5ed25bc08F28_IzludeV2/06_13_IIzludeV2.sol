//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IByalan.sol";

interface IIzludeV2 {
    function totalSupply() external view returns (uint256);

    function prontera() external view returns (address);

    function want() external view returns (IERC20);

    function deposit(address user, uint256 amount) external returns (uint256 jellopy);

    function withdraw(address user, uint256 jellopy) external returns (uint256);

    function balance() external view returns (uint256);

    function byalan() external view returns (IByalan);

    function feeKafra() external view returns (address);

    function allocKafra() external view returns (address);

    function calculateWithdrawFee(uint256 amount, address user) external view returns (uint256);
}