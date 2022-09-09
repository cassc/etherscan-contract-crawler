// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721AMinterExtension.sol";

interface IERC721ALockableExtension {
    function locked(uint256 tokenId) external view returns (bool);

    function lock(uint256 tokenId) external;

    function lock(uint256[] calldata tokenIds) external;

    function unlock(uint256 tokenId) external;

    function unlock(uint256[] calldata tokenIds) external;
}

/**
 * @dev Extension to allow locking NFTs, for use-cases like staking, without leaving holders wallet.
 */
abstract contract ERC721ALockableExtension is
    IERC721ALockableExtension,
    Initializable,
    ERC165Storage,
    ERC721AMinterExtension,
    ReentrancyGuard
{
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap internal lockedTokens;

    function __ERC721ALockableExtension_init() internal onlyInitializing {
        __ERC721ALockableExtension_init_unchained();
    }

    function __ERC721ALockableExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721ALockableExtension).interfaceId);
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721ACollectionMetadataExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * At this moment staking is only possible from a certain address (usually a smart contract).
     *
     * This is because in almost all cases you want another contract to perform custom logic on lock and unlock operations,
     * without allowing users to directly unlock their tokens and sell them, for example.
     */
    function _lock(uint256 tokenId) internal virtual {
        require(!lockedTokens.get(tokenId), "LOCKED");
        lockedTokens.set(tokenId);
    }

    function _unlock(uint256 tokenId) internal virtual {
        require(lockedTokens.get(tokenId), "NOT_LOCKED");
        lockedTokens.unset(tokenId);
    }

    /**
     * Returns if a token is locked or not.
     */
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return lockedTokens.get(tokenId);
    }

    function filterUnlocked(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory unlocked = new uint256[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            if (!locked(ticketTokenIds[i])) {
                unlocked[i] = ticketTokenIds[i];
            }
        }

        return unlocked;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        require(
            // We are not checking the quantity because it is only used during mint where users cannot stake/unstake.
            !lockedTokens.get(startTokenId),
            "LOCKED"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}