// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStakedDividendTracker {
    function dividendOfToken(uint tokenId) external view returns(uint256);
    function dividendOf(address user) external view returns(uint256);
    function withdrawDividendOnbehalfOf(address to) external;
    function withdrawDividend() external;
}