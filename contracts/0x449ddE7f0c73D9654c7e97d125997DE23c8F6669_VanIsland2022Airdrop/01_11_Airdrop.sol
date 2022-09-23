// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VanIsland2022Airdrop is ERC721, Ownable {
    uint256 public totalSupply = 0;
    string public baseURI;
    uint256 public decimals = 9;
    mapping(uint256 => bool) private usedTokens;

    constructor() ERC721("Vancouver Island Showdown NFT Collection", "VancouverIslandShowdownNFTCollection") {}

    // ONLY OWNER

    /**
     * @dev Sets the base URI that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
    {
        baseURI = _uri;
    }

     /**
     * @dev gives tokens to the given addresses
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        uint256 tmpTotalMintedTokens = totalSupply;
        totalSupply += _addresses.length;

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }
    }

    // END ONLY OWNER

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return baseURI;
    }
}