// https://grillzgang.com
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GRILLZGANGOGBADGE is Context, ERC721Enumerable, ERC721Pausable, Ownable {

    uint public MAX_BADGES = 555; // Maximum tokens that can be minted
    uint public LIMIT_PER_ACCOUNT = 1;
    mapping(address => uint) public mintCounts; // Amount minted per user
    string _baseTokenURI;

    constructor(string memory baseURI) ERC721("GRILLZ GANG OG BADGE", "GGOG") {
       setBaseURI(baseURI);
    }

    function mintBadge() external {
        require(totalSupply() < MAX_BADGES, "No more badges left to be minted");
        require(mintCounts[_msgSender()] < LIMIT_PER_ACCOUNT, "Max 1 badge per account");

        mintCounts[_msgSender()] += 1;
        _safeMint(_msgSender(), totalSupply() + 1);
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Updates the base URI.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Updates limit per account
     */
    function changeMintLimit(uint _mintLimit) public onlyOwner {
        LIMIT_PER_ACCOUNT = _mintLimit;
    }

     /**
     * @dev Pauses all token transfers.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}