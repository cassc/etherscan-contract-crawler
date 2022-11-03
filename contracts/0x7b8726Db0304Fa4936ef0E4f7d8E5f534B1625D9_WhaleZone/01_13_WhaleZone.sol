// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhaleZone is ERC721, Ownable {
    using Strings for uint256;

    uint256 private counter;
    string public baseURI = "ipfs://bafybeiaxpqxyen2yxn5h74yke3otrxrswcu7q23lfunfj7f3ajn344aiuu/";
    string public baseExtension = ".json";

    constructor() ERC721("WhaleZone Institute NFT", "WZ") {}

    function mint(address to) public onlyOwner {
        _safeMint(to, ++counter);        
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}