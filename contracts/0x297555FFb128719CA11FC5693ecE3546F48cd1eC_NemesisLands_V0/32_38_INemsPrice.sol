// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface INemsPrice {
    function NemsUSDPrice() external view returns (uint256);
}