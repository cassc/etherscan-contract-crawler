// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ITokenPairs {
    function listPairTokensByIndexAndCount(address token, uint256 index, uint256 count) external view returns (address[] memory);

    function isPairInPool(address tokenX, address tokenY) external view returns (bool);

    function pairTokenLength(address token) external view returns (uint256);

    function pairTokenByIndex(address token, uint256 index) external view returns (address);

    function pairLength() external view returns (uint256);

    function getPairHash(address tokenX, address tokenY) external pure returns (bytes32);
}