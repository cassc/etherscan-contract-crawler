// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/ERC721A.sol";
import '../interface/IERC721Lockable.sol';

/// @title Lockable Extension for ERC721A by ChiruLabs
/// @dev Check the repo and readme at https://github.com/filmakarov/erc721s

abstract contract ERC721ALockable is ERC721A, IERC721Lockable {

    /*///////////////////////////////////////////////////////////////
                            LOCKABLE EXTENSION STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal unlockers;

    /*///////////////////////////////////////////////////////////////
                              LOCKABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is the owner
     *      or approved party.
     */

    function lock(address unlocker, uint256 id) public virtual {
        address tokenOwner = ownerOf(id);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender)
        , "NOT_AUTHORIZED");
        require(unlockers[id] == address(0), "ALREADY_LOCKED");
        unlockers[id] = unlocker;
        super.approve(unlocker, id); //approve unlocker, so unlocker will be able to transfer
    }

    /**
     * @dev Public function to unlock the token. Only the unlocker (stated at the time of locking) can unlock
     */
    function unlock(uint256 id) public virtual {
        require(msg.sender == unlockers[id], "NOT_UNLOCKER");
        unlockers[id] = address(0);
    }

    /**
     * @dev Returns the unlocker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function getLocked(uint256 tokenId) public virtual view returns (address) {
        require(_exists(tokenId), "Lockable: locking query for nonexistent token");
        return unlockers[tokenId];
    }

    /**
     * @dev Locks the token
     */
    function _lock(address unlocker, uint256 id) internal virtual {
        unlockers[id] = unlocker;
    }

    /**
     * @dev Unlocks the token
     */
    function _unlock(uint256 id) internal virtual {
        unlockers[id] = address(0);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function approve(address to, uint256 tokenId) public payable virtual override {
        require (getLocked(tokenId) == address(0), "Can not approve locked token");
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) {
            // token should not be locked or msg.sender should be unlocker to do that
            require(getLocked(startTokenId) == address(0) || msg.sender == getLocked(startTokenId), "LOCKED");
        }
    }

    function _afterTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) {
            // clear locks
            delete unlockers[startTokenId];
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}