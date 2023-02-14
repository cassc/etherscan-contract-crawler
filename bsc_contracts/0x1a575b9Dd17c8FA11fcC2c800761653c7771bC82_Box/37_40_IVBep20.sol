// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IVToken.sol";

interface IVBep20 is IVToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}