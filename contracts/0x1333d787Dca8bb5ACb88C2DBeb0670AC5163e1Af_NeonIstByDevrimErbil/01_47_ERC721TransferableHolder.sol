// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './IERC721Transferable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

/**
 * @title ERC721TransferableHolder
 * @author @NiftyMike | @NFTCulture
 * @dev Holder class to more easily enable bulk transferring of ERC721 tokens.
 *
 * Note: Tokens must be transferred into the Holder to be bulk transferred. Also,
 * so as to prevent spam, only allowing Owner to utilize functionality.
 */
contract ERC721TransferableHolder is Ownable, ERC721Holder {
    IERC721Transferable public erc721Transferable;

    constructor(address __ERC721Address) {
        _updateERC721Contract(__ERC721Address);
    }

    /**
     * @notice Query for my balance on the source ERC721 Contract.
     */
    function ERC721_balanceOf() public view returns (uint256) {
        return erc721Transferable.balanceOf(address(this));
    }

    /**
     * @notice Update the ERC721 token contract that this contract should manage.
     *
     * @param __ERC721Address the ERC721 address to change to.
     */
    function updateERC721Contract(address __ERC721Address) external onlyOwner {
        _updateERC721Contract(__ERC721Address);
    }

    /**
     * @notice Transfer some quantity of a fungible token from caller to a single friend.
     *
     * @param friend address to send tokens to.
     * @param tokenId the ID of the fungible token.
     */
    function transferToFriend(address friend, uint256 tokenId) external onlyOwner {
        erc721Transferable.safeTransferFrom(address(this), friend, tokenId);
    }

    /**
     * @notice Return unsent tokens back to owner.
     *
     * @param tokenId the ID of the fungible token.
     */
    function returnToOwner(uint256 tokenId) external onlyOwner {
        erc721Transferable.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function _updateERC721Contract(address __ERC721Address) internal {
        if (__ERC721Address != address(0)) {
            erc721Transferable = IERC721Transferable(__ERC721Address);
        }
    }
}