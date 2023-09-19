// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IFactory {
    function property(uint256) external returns (address);

    function createProperty(
        uint256 _propertyId,
        address _host,
        address _delegate
    ) external returns (address _property);

    event NewProperty(
        uint256 indexed propertyId,
        address indexed property,
        address indexed host
    );
}