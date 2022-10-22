// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILSale {
    function createLand(
        address _beneficiary,
        uint256 x,
        uint256 y,
        uint256 _categories,
        string memory _uri
    ) external;

}