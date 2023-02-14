// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IVToken.sol";

interface IVBNB is IVToken {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;
}