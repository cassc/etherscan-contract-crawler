// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Savings Dai Interface
 */
interface ISDai is IERC20 {
    function dai() external view returns (address);
    function deposit(uint256, address, uint16) external returns (uint256);
    function mint(uint256, address) external returns (uint256);
    function mint(uint256, address, uint16) external returns (uint256);
    function redeem(uint256, address, address) external returns (uint256);
    function deposit(uint256 amount, address receiver) external returns (uint256);
    function withdraw(uint256 amount, address receiver, address owner) external returns (uint256);
}