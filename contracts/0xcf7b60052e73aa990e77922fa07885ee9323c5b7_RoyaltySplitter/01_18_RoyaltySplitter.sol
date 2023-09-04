// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { Create2Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IRoyaltySplitter } from "./interfaces/IRoyaltySplitter.sol";
import { RoyaltyForwarder } from "./RoyaltyForwarder.sol";

error NoRoyaltiesFound();
error NoRoyaltyInfoRegistered(address forwarder);
error ZeroTotalShares();

contract RoyaltySplitter is IRoyaltySplitter, Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RoyaltyInfo {
        IRoyaltySplitter.Royalty[] royalties;
        uint96 totalShares;
    }

    bytes32 public constant VERSION = "1.1.0";
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // forwarder => royaltyInfo
    mapping(address => RoyaltyInfo) public royaltyInfos;

    event RoyaltySplitterSet(IRoyaltySplitter indexed royaltySplitter);
    event CollectionRoyaltyRegistered(address indexed forwarder, address indexed collection, uint256 totalShares);
    event TokenRoyaltyRegistered(
        address indexed forwarder,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 totalShares
    );
    event EtherRoyaltyReleased(address indexed forwarder, uint256 amount);
    event ERC20RoyaltyReleased(address indexed forwarder, address indexed token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        AccessControlUpgradeable.__AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
    }

    function registerCollectionRoyalty(
        address collection,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) external onlyRole(REGISTRAR_ROLE) returns (address forwarder, uint96 totalShares) {
        bytes32 salt = _generateCollectionSalt(collection);
        (forwarder, totalShares) = _createForwarder(salt, royalties);

        emit CollectionRoyaltyRegistered(forwarder, collection, totalShares);
    }

    function registerTokenRoyalty(
        address collection,
        uint256 tokenId,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) external onlyRole(REGISTRAR_ROLE) returns (address forwarder, uint96 totalShares) {
        if (royalties.length == 0) {
            revert NoRoyaltiesFound();
        }

        bytes32 salt = _generateTokenSalt(collection, tokenId);
        (forwarder, totalShares) = _createForwarder(salt, royalties);

        emit TokenRoyaltyRegistered(forwarder, collection, tokenId, totalShares);
    }

    function releaseRoyalty() external payable {
        uint256 amount = msg.value;

        RoyaltyInfo storage royaltyInfo = royaltyInfos[msg.sender];
        uint256 totalShares = royaltyInfo.totalShares;
        if (totalShares == 0) {
            revert NoRoyaltyInfoRegistered(msg.sender);
        }

        emit EtherRoyaltyReleased(msg.sender, amount);

        uint256 royaltyCount = royaltyInfo.royalties.length;
        for (uint256 i = 0; i < royaltyCount; ) {
            IRoyaltySplitter.Royalty storage royalty = royaltyInfo.royalties[i];

            uint256 value = (amount * royalty.share) / totalShares;
            royalty.payee.sendValue(value);
            unchecked {
                i++;
            }
        }
    }

    function releaseRoyalty(IERC20Upgradeable token, uint256 amount) external {
        RoyaltyInfo storage royaltyInfo = royaltyInfos[msg.sender];
        uint256 totalShares = royaltyInfo.totalShares;
        if (totalShares == 0) {
            revert NoRoyaltyInfoRegistered(msg.sender);
        }

        emit ERC20RoyaltyReleased(msg.sender, address(token), amount);

        uint256 royaltyCount = royaltyInfo.royalties.length;
        for (uint256 i = 0; i < royaltyCount; ) {
            IRoyaltySplitter.Royalty storage royalty = royaltyInfo.royalties[i];

            uint256 value = (amount * royalty.share) / totalShares;
            token.safeTransferFrom(msg.sender, royalty.payee, value);
            unchecked {
                i++;
            }
        }
    }

    function computeCollectionRoyaltyForwarderAddress(address collection) external view returns (address) {
        bytes32 salt = _generateCollectionSalt(collection);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(RoyaltyForwarder).creationCode, abi.encode(this)));
        return Create2Upgradeable.computeAddress(salt, bytecodeHash);
    }

    function computeTokenRoyaltyForwarderAddress(address collection, uint256 tokenId) external view returns (address) {
        bytes32 salt = _generateTokenSalt(collection, tokenId);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(RoyaltyForwarder).creationCode, abi.encode(this)));
        return Create2Upgradeable.computeAddress(salt, bytecodeHash);
    }

    function _createForwarder(
        bytes32 salt,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) private returns (address forwarder, uint96 totalShares) {
        if (royalties.length == 0) {
            revert NoRoyaltiesFound();
        }

        forwarder = address(new RoyaltyForwarder{ salt: salt }(this));

        totalShares = _setRoyaltyInfo(forwarder, royalties);
        if (totalShares == 0) {
            revert ZeroTotalShares();
        }
    }

    function _setRoyaltyInfo(
        address forwarder,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) private returns (uint96) {
        uint96 totalShares = 0;
        uint256 royaltyCount = royalties.length;

        for (uint256 i = 0; i < royaltyCount; ) {
            totalShares += royalties[i].share;
            royaltyInfos[forwarder].royalties.push(royalties[i]);
            unchecked {
                i++;
            }
        }

        royaltyInfos[forwarder].totalShares = totalShares;
        return totalShares;
    }

    function _generateCollectionSalt(address collection) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection));
    }

    function _generateTokenSalt(address collection, uint256 tokenId) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection, tokenId));
    }
}