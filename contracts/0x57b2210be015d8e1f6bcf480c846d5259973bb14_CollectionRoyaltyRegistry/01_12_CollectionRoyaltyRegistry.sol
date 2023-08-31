// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ICollectionRoyaltyReader.sol";

contract CollectionRoyaltyRegistry is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ICollectionRoyaltyReader
{
    RoyaltyAmount[] royalties;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function royaltyInfo(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (RoyaltyAmount[] memory) {
        return royalties;
    }

    function addRoyaltyReceiver(
        address _collection,
        address _receiver,
        uint256 _percentage
    ) external {}

    function removeRoyaltyReceiver(
        address collectionAddress,
        address account
    ) external {}

    function updateRoyaltyReceiver(
        address collectionAddress,
        address account,
        uint256 fraction
    ) external {}

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}