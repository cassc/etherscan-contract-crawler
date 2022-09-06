// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "solmate/tokens/ERC20.sol";

abstract contract bdToken is ERC20 {
    address public underlying;

    function redeem(uint redeemTokens) virtual external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) virtual external returns (uint);
    function mint(uint mintAmount, bool enterMarket) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
}

interface Stabilizer {
    function buy(uint amount) external;
    function sell(uint amount) external;
}