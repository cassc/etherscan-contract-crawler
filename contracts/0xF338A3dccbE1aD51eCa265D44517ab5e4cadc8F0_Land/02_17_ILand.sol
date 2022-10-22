// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILand {
    struct LandData {
        uint256 categories;
        uint256 timestamp;
    }

    enum Type {
        Normal,
        Platinum,
        Premium
    }

    event Blacklisted(address account, bool value);
    event CreateLand(
        address _beneficiary,
        uint256 x,
        uint256 y,
        uint256 _categories
    );
    event PlatFormOwnerUpdate(address oldAddress, address newAddress);
    event TransferLand(address from, address to, uint256 x, uint256 y);
    event TransferManyLand(address from, address to, uint256[] x, uint256[] y);
    event UpdateLandData(address landOwner, uint256 _landId, string _tokenURI);
    event UpdateMultipleLandData(
        address landOwner,
        uint256[] _landId,
        string[] _tokenURI
    );
    event UpdateManyLandData(
        address landOwner,
        uint256[] x,
        uint256[] y,
        string[] _tokenURI
    );
}