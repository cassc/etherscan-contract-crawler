// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDoubleDiceToken is IERC20 {

    function claimYield() external;

}