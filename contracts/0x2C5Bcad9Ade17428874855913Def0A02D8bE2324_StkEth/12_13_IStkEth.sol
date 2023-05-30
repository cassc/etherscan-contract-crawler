//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICoreRef.sol";

/// @title Oracle interface
/// @author Ankit Parashar
interface IStkEth is IERC20{

    function pricePerShare() external view returns (uint256 amount);

    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}