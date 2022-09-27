// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Epamaker is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 25;
    string private tokenBaseURI =
        "https://cos-nft-hosting.web.app/nft/epamaker/";
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Epamaker", "COSPA") {
        _tokenIds.increment();
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Not allowed");
    }

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
        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function batchMint(address[] calldata toList) external onlyOwner {
        require(
            totalSupply() + toList.length <= MAX_SUPPLY,
            "reach max supply"
        );
        for (uint256 i = 0; i < toList.length; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(toList[i], tokenId);
            _tokenIds.increment();
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    // Internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }
}