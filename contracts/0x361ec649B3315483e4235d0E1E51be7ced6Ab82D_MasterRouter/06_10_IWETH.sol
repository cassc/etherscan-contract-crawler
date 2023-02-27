// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function getOwner() external view returns (address);
    function deposit() external payable;
    function withdraw(uint wad) external;
}