// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../tokens/SBT/ISBT.sol";

interface ILinkableSBT is ISBT {
    function addLinkPrice() external view returns (uint256);

    function addLinkPriceMASA() external view returns (uint256);

    function queryLinkPrice() external view returns (uint256);

    function queryLinkPriceMASA() external view returns (uint256);
}