// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ILockedContent.sol";
import "./BlockMelonERC721Creator.sol";

abstract contract BlockMelonERC721LockedContent is
    ILockedContent,
    BlockMelonERC721Creator
{
    /// @notice Emitted when `tokenId` is created. `hasLockedContent` indicates if it has a locked content
    event LockedContent(uint256 tokenId, bool hasLockedContent);

    /// @dev bytes4(keccak256('getLockedContent(uint256)')) == 1c7e78f3
    bytes4 private constant _INTERFACE_ID_LOCKED_CONTENT = 0x1c7e78f3;
    /// @dev Mapping from each NFT ID to its optionally locked content
    mapping(uint256 => string) private _lockedContent;

    function __BlockMelonERC721LockedContent_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _INTERFACE_ID_LOCKED_CONTENT == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice See  {ILockedContent-getLockedContent}.
     * @dev Requirements:
     *      - caller must either be the creator or the owner of `tokenId`
     */
    function getLockedContent(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bool isOwner = _msgSender() == ownerOf(tokenId);
        bool isCreator = _msgSender() == tokenCreator(tokenId);
        require(isOwner || isCreator, "caller is not the owner or the creator");
        return _lockedContent[tokenId];
    }

    function _setLockedContent(uint256 tokenId, string memory lockedContent)
        internal
        virtual
    {
        if (0 != bytes(lockedContent).length) {
            _lockedContent[tokenId] = lockedContent;
            emit LockedContent(tokenId, true);
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _lockedContent[tokenId];
    }

    uint256[50] private __gap;
}