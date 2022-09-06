// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface FeeSplitter {

    function proxySend(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

}