// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUnitroller  {
    /*** User Interface ***/

    function enterMarkets(address[] calldata vTokens) external returns (uint[] memory);
    function claimVenus(address holder) external;
}