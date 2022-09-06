// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount,
        address received
    );
}