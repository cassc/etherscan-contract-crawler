// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGOHMLikeV2 is IERC20 {
    function index() external view returns (uint256);
    function decimals() external view returns (uint256);
}