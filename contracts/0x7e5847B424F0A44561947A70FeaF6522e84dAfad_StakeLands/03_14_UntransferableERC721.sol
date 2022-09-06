// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UntransferableERC721
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice An NFT implementation that cannot be transfered no matter what
 *         unless minting or burning
 */
contract UntransferableERC721 is ERC721, Ownable {
    /// @dev Base URI for the underlying token
    string private baseURI;

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
        require(to == address(0) || from == address(0));
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Prevent approvals of staked token
     */
    function approve(address, uint256) public virtual override {
        revert();
    }

    /**
     * @dev Prevent approval of staked token
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert();
    }

    /**
     * @notice Set the base URI for the NFT
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns the base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}