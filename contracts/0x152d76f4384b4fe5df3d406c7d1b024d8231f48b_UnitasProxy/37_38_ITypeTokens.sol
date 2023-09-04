// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IERC20Token.sol";
import "./ISwapFunctions.sol";

interface ITypeTokens {
    function listTokensByIndexAndCount(uint8 tokenType, uint256 index, uint256 count) external view returns (address[] memory);

    function isTokenInPool(address token) external view returns (bool);

    function tokenLength(uint8 tokenType) external view returns (uint256);

    function tokenByIndex(uint8 tokenType, uint256 index) external view returns (address);
}