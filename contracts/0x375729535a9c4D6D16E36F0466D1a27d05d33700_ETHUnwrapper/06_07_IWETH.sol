// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import {IERC20} from "../../../openzeppelin/token/ERC20/utils/SafeERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
    function transfer(address to, uint value) external override returns (bool);
	function balanceOf(address account) external override view returns (uint256);
}