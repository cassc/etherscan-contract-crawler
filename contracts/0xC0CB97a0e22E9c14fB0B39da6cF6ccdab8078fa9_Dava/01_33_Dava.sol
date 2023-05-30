//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UpgradeableBeacon} from "./libraries/UpgradeableBeacon.sol";
import {MinimalProxy} from "./libraries/MinimalProxy.sol";
import {GatewayHandler} from "./libraries/GatewayHandler.sol";
import {Part, IAvatar} from "./interfaces/IAvatar.sol";
import {IFrameCollection} from "./interfaces/IFrameCollection.sol";
import {IPartCollection} from "./interfaces/IPartCollection.sol";
import {IDava} from "./interfaces/IDava.sol";
import {IGatewayHandler} from "./interfaces/IGatewayHandler.sol";

contract Dava is IDava, Ownable, UpgradeableBeacon, AccessControl, ERC721 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Clones for address;

    bytes32 public constant DAVA_GATEWAY_KEY = keccak256("DAVA_GATEWAY");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PART_MANAGER_ROLE = keccak256("PART_MANAGER_ROLE");
    bytes32 public constant UPGRADE_MANAGER_ROLE =
        keccak256("UPGRADE_MANAGER_ROLE");

    address public override frameCollection;

    EnumerableSet.AddressSet private _registeredCollections;
    EnumerableSet.Bytes32Set private _supportedCategories;
    address private _minimalProxy;
    IGatewayHandler public gatewayHandler;

    uint48 public constant MAX_SUPPLY = 10000;

    event CollectionRegistered(address collection);
    event CollectionDeregistered(address collection);
    event DefaultCollectionRegistered(address collection);
    event CategoryRegistered(bytes32 categoryId);
    event CategoryDeregistered(bytes32 categoryId);

    // DAO contract owns this registry
    constructor(address minimalProxy_, IGatewayHandler gatewayHandler_)
        ERC721("Dava", "DAVA")
        UpgradeableBeacon(minimalProxy_)
        Ownable()
    {
        _minimalProxy = minimalProxy_;
        gatewayHandler = gatewayHandler_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(PART_MANAGER_ROLE, msg.sender);
        _setRoleAdmin(PART_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(UPGRADE_MANAGER_ROLE, msg.sender);
        _setRoleAdmin(UPGRADE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function baseURI() external view override returns (string memory) {
        return gatewayHandler.gateways(DAVA_GATEWAY_KEY);
    }

    function upgradeTo(address newImplementation)
        external
        onlyRole(UPGRADE_MANAGER_ROLE)
    {
        _upgradeTo(newImplementation);
    }

    function mint(address to, uint256 id)
        external
        override
        onlyRole(MINTER_ROLE)
        returns (address)
    {
        require(id < uint256(MAX_SUPPLY), "Dava: Invalid id");
        return _mintWithProxy(to, id);
    }

    function registerCollection(address collection)
        external
        override
        onlyRole(PART_MANAGER_ROLE)
    {
        require(
            IERC165(collection).supportsInterface(
                type(IPartCollection).interfaceId
            ),
            "Dava: Does not support IPartCollection interface"
        );
        require(
            !_registeredCollections.contains(collection),
            "Dava: already registered collection"
        );
        _registeredCollections.add(collection);

        emit CollectionRegistered(collection);
    }

    function registerCategory(bytes32 categoryId)
        external
        override
        onlyRole(PART_MANAGER_ROLE)
    {
        require(
            !_supportedCategories.contains(categoryId),
            "Dava: category is already registered"
        );
        _supportedCategories.add(categoryId);

        emit CategoryRegistered(categoryId);
    }

    function registerFrameCollection(address collection)
        external
        override
        onlyRole(PART_MANAGER_ROLE)
    {
        require(
            IERC165(collection).supportsInterface(
                type(IFrameCollection).interfaceId
            ),
            "Dava: Does not support IFrameCollection interface"
        );

        frameCollection = collection;

        emit DefaultCollectionRegistered(collection);
    }

    function deregisterCollection(address collection)
        external
        override
        onlyRole(PART_MANAGER_ROLE)
    {
        require(
            _registeredCollections.contains(collection),
            "Dava: Not registered collection"
        );

        _registeredCollections.remove(collection);

        emit CollectionDeregistered(collection);
    }

    function deregisterCategory(bytes32 categoryId)
        external
        override
        onlyRole(PART_MANAGER_ROLE)
    {
        require(
            _supportedCategories.contains(categoryId),
            "Dava: non registered category"
        );
        _supportedCategories.remove(categoryId);

        emit CategoryDeregistered(categoryId);
    }

    function zap(
        uint256 tokenId,
        Part[] calldata partsOn,
        bytes32[] calldata partsOff
    ) external override {
        require(
            msg.sender == ownerOf(tokenId),
            "Dava: msg.sender is not the owner of avatar"
        );
        address avatarAddress = getAvatar(tokenId);
        IAvatar avatar = IAvatar(avatarAddress);
        for (uint256 i = 0; i < partsOff.length; i += 1) {
            Part memory equippedPart = avatar.part(partsOff[i]);
            IERC1155 collection = IERC1155(equippedPart.collection);
            if (
                equippedPart.collection != address(0x0) &&
                collection.balanceOf(avatarAddress, equippedPart.id) > 0
            ) {
                collection.safeTransferFrom(
                    avatarAddress,
                    msg.sender,
                    equippedPart.id,
                    1,
                    ""
                );
            }
        }

        for (uint256 i = 0; i < partsOn.length; i += 1) {
            IERC1155 collection = IERC1155(partsOn[i].collection);
            require(
                collection.supportsInterface(type(IERC1155).interfaceId),
                "Dava: collection is not an erc1155 format"
            );
            require(
                collection.balanceOf(msg.sender, partsOn[i].id) >= 1,
                "Dava: owner does not hold the part"
            );
            collection.safeTransferFrom(
                msg.sender,
                avatarAddress,
                partsOn[i].id,
                1,
                ""
            );
        }

        IAvatar(getAvatar(tokenId)).dress(partsOn, partsOff);
    }

    function isRegisteredCollection(address collection)
        external
        view
        override
        returns (bool)
    {
        return _registeredCollections.contains(collection);
    }

    function isSupportedCategory(bytes32 categoryId)
        external
        view
        override
        returns (bool)
    {
        return _supportedCategories.contains(categoryId);
    }

    function isDavaPart(address collection, bytes32 categoryId)
        external
        view
        override
        returns (bool)
    {
        return
            _registeredCollections.contains(collection) &&
            _supportedCategories.contains(categoryId);
    }

    function getAvatar(uint256 tokenId) public view override returns (address) {
        return
            _minimalProxy.predictDeterministicAddress(
                bytes32(tokenId),
                address(this)
            );
    }

    function getAllSupportedCategories()
        external
        view
        override
        returns (bytes32[] memory categoryIds)
    {
        return _supportedCategories.values();
    }

    function getRegisteredCollections()
        external
        view
        override
        returns (address[] memory)
    {
        return _registeredCollections.values();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return IAvatar(getAvatar(tokenId)).getMetadata();
    }

    function getPFP(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return IAvatar(getAvatar(tokenId)).getPFP();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, AccessControl, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IDava).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mintWithProxy(address to, uint256 id) internal returns (address) {
        address avatar = _minimalProxy.cloneDeterministic(bytes32(id));
        MinimalProxy(payable(avatar)).initialize(id);
        super._mint(to, id);
        return avatar;
    }
}