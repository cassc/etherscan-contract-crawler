// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract IFancyTraitCategories {

    mapping(address => mapping(string => bool)) public categoryApprovedByCollection;
    mapping(address => string[]) public categoryListByCollection;

    function getCategoriesByCollection(address _collection) public virtual view returns (string[] memory);
}