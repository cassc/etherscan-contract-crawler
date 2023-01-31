// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEulerMarkets {
    function underlyingToEToken(address underlying)
        external
        view
        returns (address);

    function underlyingToDToken(address underlying)
        external
        view
        returns (address);

    function enterMarket(uint256 subAccountId, address newMarket) external;
}

interface IEToken is IERC20 {
    function deposit(uint256 subAccountId, uint256 amount) external;

    function withdraw(uint256 subAccountId, uint256 amount) external;
}

interface IDToken is IERC20 {
    function borrow(uint256 subAccountId, uint256 amount) external;

    function repay(uint256 subAccountId, uint256 amount) external;
}