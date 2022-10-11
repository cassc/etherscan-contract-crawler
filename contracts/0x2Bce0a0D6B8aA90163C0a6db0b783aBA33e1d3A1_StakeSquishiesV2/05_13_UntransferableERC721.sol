// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UntransferableERC721
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice An NFT implementation that cannot be transfered no matter what
 *         unless minting or burning.
 */
contract UntransferableERC721 is ERC721, Ownable {
    /// @dev Base URI for the underlying token
    string private baseURI;

    /// @dev Thrown when an approval is made while untransferable
    error Unapprovable();

    /// @dev Thrown when making an transfer while untransferable
    error Untransferable();

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev Prevent token transfer unless burn
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        if (to != address(0) && from != address(0)) {
            revert Untransferable();
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Prevent approvals of staked token
     */
    function approve(address, uint256) public virtual override {
        revert Unapprovable();
    }

    /**
     * @dev Prevent approval of staked token
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert Unapprovable();
    }

    /**
     * @notice Set the base URI for the NFT
     */
    function setBaseURI(string memory baseURI_) public virtual onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns the base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}