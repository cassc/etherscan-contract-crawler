// contracts/ERC721.sol
// spdx-license-identifier: mit

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///////////////////////////////////////////////////////////////
// ________                           /\          ____ ____  //
// \_____  \   ____  ____ _____    ___)/  ______ /_   /_   | //
//  /   |   \_/ ___\/ __ \\__  \  /    \ /  ___/  |   ||   | //
// /    |    \  \__\  ___/ / __ \|   |  \\___ \   |   ||   | //
// \_______  /\___  >___  >____  /___|  /____  >  |___||___| //
//         \/     \/    \/     \/     \/     \/              //
///////////////////////////////////////////////////////////////

// Contract by @punk2513 for @MyRugema

contract Oceans11 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public MAX_SUPPLY = 33;

    // Mapping from tokenId to the token's URI.
    mapping(uint256 => string) private mintedTokenURIs;

    constructor() ERC721("Ocean's 11", "O11") {
    }

    function mintToAddress(string memory newTokenURI, address recipient)
        public onlyOwner
        returns (uint256)
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Mint would exceed max supply");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        mintedTokenURIs[newItemId] = newTokenURI;

        return newItemId;
    }

    function mintManyToAddress(string[] memory tokenURIs, address recipient)
        public onlyOwner
    {
        for (uint i=0; i < tokenURIs.length; i++) {
            mintToAddress(tokenURIs[i], recipient);
        }
    }

    // ennsure overriding correctly...
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return mintedTokenURIs[tokenId];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}