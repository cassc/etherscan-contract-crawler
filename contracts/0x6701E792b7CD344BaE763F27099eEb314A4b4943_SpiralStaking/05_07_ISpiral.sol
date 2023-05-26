// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISpiral is IERC20 {
    function mint(address who, uint256 amount) external;
    function burn(uint256 amount) external;
}