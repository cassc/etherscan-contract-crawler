// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VeryEmoji is ERC721, ERC721Enumerable {
    uint256 private constant MAX_SUPPLY = 88;
    uint256[] private _mintedTokenIds;

    constructor() ERC721("VeryEmoji", "EMOJI") {
    }

    /**
     * @dev Mints a token to msg.sender
     * @param tokenId of the token
     */
    function mint(uint256 tokenId) public {
        require(tokenId < MAX_SUPPLY);
        _mint(msg.sender, tokenId);
        _mintedTokenIds.push(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev returns the maxSupply
     * @return uint256 for the maxSupply
     */
    function maxSupply() 
        public
        pure
        returns (uint256)
    {
        return MAX_SUPPLY;
    }

    /**
     * @dev returns the minted TokenId array
     * @return uint256[] for the minted TokenId array
     */
    function mintedTokenIds()
        public
        view
        returns (uint256[] memory)
    {
        return _mintedTokenIds;
    }

    /**
     * @dev returns the tokenURI for the specified tokenId
     * @param tokenId of the token
     * @return string for the tokenURI
     */
    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://QmSxvj2y3ktM8EErNvzfBiUBFDBNRW4GBTomGpvrfM25Td/", Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}