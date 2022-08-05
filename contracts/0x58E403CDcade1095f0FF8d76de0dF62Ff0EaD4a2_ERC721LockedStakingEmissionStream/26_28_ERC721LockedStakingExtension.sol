// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721LockableExtension} from "../../../collections/ERC721/extensions/ERC721LockableExtension.sol";

import "./ERC721StakingExtension.sol";

/**
 * @author Flair (https://flair.finance)
 */
interface IERC721LockedStakingExtension {
    function hasERC721LockedStakingExtension() external view returns (bool);
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721LockedStakingExtension is
    IERC721LockedStakingExtension,
    ERC721StakingExtension
{
    /* INIT */

    function __ERC721LockedStakingExtension_init(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        __ERC721LockedStakingExtension_init_unchained();
        __ERC721StakingExtension_init_unchained(
            _minStakingDuration,
            _maxStakingTotalDurations
        );
    }

    function __ERC721LockedStakingExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721LockedStakingExtension).interfaceId);
    }

    /* PUBLIC */

    function hasERC721LockedStakingExtension() external pure returns (bool) {
        return true;
    }

    function stake(uint256 tokenId) public virtual override {
        ERC721StakingExtension.stake(tokenId);
        IERC721LockableExtension(ticketToken).lock(tokenId);
    }

    function stake(uint256[] calldata tokenIds) public virtual override {
        ERC721StakingExtension.stake(tokenIds);
        IERC721LockableExtension(ticketToken).lock(tokenIds);
    }

    function unstake(uint256 tokenId) public virtual override {
        ERC721StakingExtension.unstake(tokenId);
        IERC721LockableExtension(ticketToken).unlock(tokenId);
    }

    function unstake(uint256[] calldata tokenIds) public virtual override {
        ERC721StakingExtension.unstake(tokenIds);
        IERC721LockableExtension(ticketToken).unlock(tokenIds);
    }

    function _stake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual override {
        require(
            operator == IERC721(ticketToken).ownerOf(tokenId),
            "NOT_TOKEN_OWNER"
        );
        ERC721StakingExtension._stake(operator, currentTime, tokenId);
    }

    function _unstake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual override {
        require(
            operator == IERC721(ticketToken).ownerOf(tokenId),
            "NOT_TOKEN_OWNER"
        );
        ERC721StakingExtension._unstake(operator, currentTime, tokenId);
    }
}