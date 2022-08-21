// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftGame is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 42905;
    uint256 public constant MINT_PRICE = 0.02 ether;
    uint256 public constant MAX_PUBLIC_MINT = 10;

    string public _provenanceHash = "";
    string public _baseURL;

    Counters.Counter private currentTokenId;

    constructor() ERC721("NFTGame", "NFTG") {}

    function mintTo(address recipient, uint256 count) public payable {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        require(
            count > 0 && count <= MAX_PUBLIC_MINT,
            "Max mint supply reached"
        );

        require(
            msg.value == MINT_PRICE * count,
            "Transaction value did not equal the mint price"
        );

        for (uint256 i = 0; i < count; i++) {
            currentTokenId.increment();
            uint256 newItemId = currentTokenId.current();
            _safeMint(recipient, newItemId);
        }

        bool success = false;
        (success, ) = owner().call{value: msg.value}("");
        require(success, "Failed to send to owner");
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId.current();
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }
}