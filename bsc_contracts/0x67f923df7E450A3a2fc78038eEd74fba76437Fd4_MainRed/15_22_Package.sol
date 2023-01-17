// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../secutiry/Administered.sol";

contract Package is Administered {
    /// @dev mapping of package id to package details
    mapping(uint256 => PackageInfo) public WhitelistPackage;

    /// @dev count of packages
    uint256 private whitelistPackageCount;

    /// @dev package info
    struct PackageInfo {
        uint256 id;
        uint256 price;
        address _addrsNft;
        bool active;
    }

    constructor() {
        whitelistPackageCount = 0;
    }

    ///  @dev add Package
    function addPackage(uint256 _price, address _addrs) public onlyUser {
        WhitelistPackage[whitelistPackageCount] = PackageInfo(
            whitelistPackageCount,
            _price,
            _addrs,
            true
        );
        whitelistPackageCount++;
    }

    /// @dev remove Package
    function removePackage(uint256 _id) public onlyUser {
        WhitelistPackage[_id].active = !WhitelistPackage[_id].active;
    }

    /// @dev get Package
    function getPackage(uint256 _id) public view returns (PackageInfo memory) {
        return WhitelistPackage[_id];
    }

    /// @dev get Package price
    function getPackagePrice(uint256 _id) public view returns (uint256) {
        return WhitelistPackage[_id].price;
    }
}