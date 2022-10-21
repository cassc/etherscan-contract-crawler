// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IConvexToken {
    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);
}