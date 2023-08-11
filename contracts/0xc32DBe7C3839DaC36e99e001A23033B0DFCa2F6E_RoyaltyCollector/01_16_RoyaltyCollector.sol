// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IRoyaltyCollector } from "./interfaces/IRoyaltyCollector.sol";
import { IRoyaltyForwarder } from "./interfaces/IRoyaltyForwarder.sol";
import { IRoyaltySplitter } from "./interfaces/IRoyaltySplitter.sol";

error NFTItemRangeMissed(uint8[2] nftItemRange, uint256 currentNFTItemCount);

contract RoyaltyCollector is IRoyaltyCollector, Initializable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant VERSION = "1.0.0";
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    event RoyaltySplitterSet(IRoyaltySplitter royaltySplitter);
    event NFTItemRangeSet(uint8[2] nftItemRange);
    event TokenAdded(address token);
    event TokenRemoved(address token);
    event RoyaltiesCollected(uint256 nftItemCount);

    IRoyaltySplitter public royaltySplitter;
    uint8[2] public nftItemRange;
    EnumerableSetUpgradeable.AddressSet private _tokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IRoyaltySplitter royaltySplitter_,
        uint8[2] calldata nftItemRange_,
        address[] calldata tokens_
    ) external initializer {
        AccessControlUpgradeable.__AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COLLECTOR_ROLE, msg.sender);

        royaltySplitter = royaltySplitter_;
        nftItemRange = nftItemRange_;

        uint256 tokenCount = tokens_.length;
        for (uint256 i = 0; i < tokenCount; ) {
            // slither-disable-next-line unused-return
            _tokens.add(tokens_[i]);
            unchecked {
                i++;
            }
        }
    }

    function setRoyaltySplitter(IRoyaltySplitter royaltySplitter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltySplitter = royaltySplitter_;
        emit RoyaltySplitterSet(royaltySplitter_);
    }

    function setNFTItemRange(uint8[2] calldata nftItemRange_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftItemRange = nftItemRange_;
        emit NFTItemRangeSet(nftItemRange_);
    }

    function addToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool added = _tokens.add(token);
        if (added) {
            emit TokenAdded(token);
        }
    }

    function removeToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool removed = _tokens.remove(token);
        if (removed) {
            emit TokenRemoved(token);
        }
    }

    function collectTokenRoyalties(NFTItem[] calldata nftItems) external onlyRole(COLLECTOR_ROLE) {
        uint256 nftItemCount = nftItems.length;
        if (nftItemCount < nftItemRange[0] || nftItemCount > nftItemRange[1]) {
            revert NFTItemRangeMissed(nftItemRange, nftItemCount);
        }

        IRoyaltySplitter royaltySplitter_ = royaltySplitter;
        uint256 tokenCount = _tokens.length();

        emit RoyaltiesCollected(nftItems.length);

        for (uint256 i = 0; i < nftItemCount; ) {
            NFTItem calldata nftItem = nftItems[i];
            // slither-disable-next-line calls-loop
            IRoyaltyForwarder royaltyForwarder = IRoyaltyForwarder(
                royaltySplitter_.computeTokenRoyaltyForwarderAddress(nftItem.collection, nftItem.tokenId)
            );

            for (uint256 j = 0; j < tokenCount; ) {
                address token = _tokens.at(j);
                // slither-disable-next-line calls-loop
                royaltyForwarder.forwardRoyalty(IERC20Upgradeable(token));
                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function tokens() external view returns (address[] memory) {
        return _tokens.values();
    }
}