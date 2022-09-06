// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WCT is ERC721, PullPayment, Ownable {
    using Counters for Counters.Counter;
    uint256 public constant TOTAL_SUPPLY = 10_001;
    Counters.Counter private currentTokenId;
    string public baseTokenURI;
    uint public CURRENTLY_CREATED;

    constructor() ERC721("Worm Civilization", "WCT") {
        baseTokenURI = "";
        CURRENTLY_CREATED = 9800;
    }

    function mintSingleNft(address _to) private {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(_to, newItemId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setCurrentlyCreated(uint _currentlyCreated) public onlyOwner {
        require(_currentlyCreated < TOTAL_SUPPLY, "Max supply lower that currently created");
        CURRENTLY_CREATED = _currentlyCreated;
    }

    function withdrawPayments(address payable payee) public override onlyOwner virtual {
        super.withdrawPayments(payee);
    }
}