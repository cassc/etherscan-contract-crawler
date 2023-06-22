// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SettableCallbackerWithAccessControl} from "proof/sellers/presets/CallbackerWithAccessControl.sol";
import {Seller} from "proof/sellers/base/Seller.sol";

import {MythicEggSampler} from "../Egg/MythicEggSampler.sol";
import {NonRollingRateLimited} from "./NonRollingRateLimited.sol";

interface OddsoleumEvents {
    event OdditySacrificed(address indexed owner, uint256 tokenId);

    /**
     * @notice Emitted if a burner attempts to sacrifice an Oddity that is not in the queue or was not approved to be
     * transferred by the Oddsoleum contract.
     * @dev This will likely only happen in the case of a race condition, where Oddity nomination is revoked after
     * selecting it to be burned.
     */
    event CannotBurnIneligibleOddity(uint256 indexed tokenId, bool queued, bool approved);
}

/**
 * @title Oddsoleum
 * @notice Allows Oddities to enter a queue for being sacrificed on the altar of the Oddgod.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract Oddsoleum is Seller, SettableCallbackerWithAccessControl, OddsoleumEvents, NonRollingRateLimited {
    /**
     * @notice The role allowed to burn oddities.
     */
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice The receiver of burned Oddities.
     * @dev The original Oddities contract does not allow burning, so we send the tokens to the dead address instead.
     */
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * @notice The Oddities contract.
     */
    IERC721 public immutable oddities;

    /**
     * @notice Keeps track of Oddities that are in the queue to be sacrificed.
     * @dev Keyed by owner to automatically unqueue Oddities if they are transferred. Consequently, tokens will still
     * be queued after a round-trip, which can't be avoided as it would require a callback from the Oddities contract
     * upon transfer.
     */
    mapping(address owner => mapping(uint256 tokenId => bool)) private _queued;

    constructor(address admin, address steerer, IERC721 oddities_)
        SettableCallbackerWithAccessControl(admin, steerer)
        NonRollingRateLimited(50, 1 days)
    {
        _setRoleAdmin(BURNER_ROLE, DEFAULT_STEERING_ROLE);
        oddities = oddities_;
    }

    /**
     * @notice Adds the given Oddities to the senders queue.
     * @dev Oddity ownership is not relevant here as senders only have access to their own flag set. Upon burn, the
     * contract will only consider the flag of the current owner of the given Oddity.
     */
    function addToQueue(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _queued[msg.sender][tokenIds[i]] = true;
        }
    }

    /**
     * @notice Removes the given Oddities from the senders queue.
     * @dev Oddity ownership is not relevant here as senders only have access to their own flag set. Upon burn, the
     * contract will only consider the flag of the current owner of the given Oddity.
     */
    function removeFromQueue(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _queued[msg.sender][tokenIds[i]] = false;
        }
    }

    /**
     * @notice Returns whether the given Oddities are in the queue.
     * @dev This does not imply that they can be sacrificed, as the owner may not have approved this contract to burn
     * them.
     */
    function queued(uint256[] calldata tokenIds) public view returns (bool[] memory) {
        bool[] memory queued_ = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            address owner = oddities.ownerOf(tokenIds[i]);
            queued_[i] = _queued[owner][tokenIds[i]];
        }
        return queued_;
    }

    /**
     * @notice Returns whether the given Oddities can be sacrificed.
     * @dev True iff the Oddity is in the queue and the owner has approved this contract to burn it.
     */
    function burnable(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory burnable_ = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            address owner = oddities.ownerOf(tokenIds[i]);
            burnable_[i] = _burnable(owner, tokenIds[i]);
        }
        return burnable_;
    }

    /**
     * @notice Returns whether the given Oddities can be sacrificed.
     */
    function _burnable(address owner, uint256 tokenId) internal view returns (bool) {
        return _queued[owner][tokenId] && _approved(owner, tokenId);
    }

    /**
     * @notice Returns whether the given Oddities can be sacrificed.
     */
    function _approved(address owner, uint256 tokenId) internal view returns (bool) {
        return (oddities.isApprovedForAll(owner, address(this)) || oddities.getApproved(tokenId) == address(this));
    }

    /**
     * @notice Burns the given Oddity by sending it to a burn address.
     */
    function _burn(address owner, uint256 tokenId) internal returns (bool) {
        bool queued_ = _queued[owner][tokenId];
        bool approved = _approved(owner, tokenId);

        if (!(queued_ && approved)) {
            emit CannotBurnIneligibleOddity(tokenId, queued_, approved);
            return false;
        }

        oddities.transferFrom(owner, BURN_ADDRESS, tokenId);
        emit OdditySacrificed(owner, tokenId);
        return true;
    }

    /**
     * @notice Sacrifices the given Oddity by burning it and awards a Mythic to the original owner in return.
     */
    function _sacrifice(uint256 tokenId) internal returns (bool) {
        address owner = oddities.ownerOf(tokenId);
        bool burned = _burn(owner, tokenId);
        if (!burned) {
            return false;
        }
        _purchase(owner, 1, /* total cost */ 0, "");
        return true;
    }

    /**
     * @notice Sacrifices the given Oddities by burning them and awards Mythics to the original owners in return.
     */
    function sacrifice(uint256[] calldata tokenIds) external onlyRole(BURNER_ROLE) {
        uint64 numSacrificed;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            bool sacrificed = _sacrifice(tokenIds[i]);

            unchecked {
                if (sacrificed) {
                    ++numSacrificed;
                }
            }
        }
        _checkAndTrackRateLimit(numSacrificed);
    }

    /**
     * @notice Sets the maximum number of activations per day.
     */
    function setMaxSacrificesPerPeriod(uint32 maxSacrificesPerPeriod) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setMaxActionsPerPeriod(maxSacrificesPerPeriod);
    }
}