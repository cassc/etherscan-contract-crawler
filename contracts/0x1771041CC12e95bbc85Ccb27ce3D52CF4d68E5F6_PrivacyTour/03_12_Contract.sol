// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PrivacyTour is ERC721A, Ownable {
    string public baseExtension = ".json";
    uint256 MAX_MINTS = 200;
    uint256 MAX_FREE_MINTS = 5;
    uint256 MAX_SUPPLY = 10000;
    uint256 public mintRate = 0.002 ether;

    string public baseURI =
        "ipfs://bafybeiemwbjagzcaaahbvhk7bmywpisspgsrgtb6mligec5jq53zeqlwre/";

    constructor() ERC721A("Privacy Tour", "PT", 200, 10000) {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            quantity + _numberMinted(msg.sender) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        //require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        //bool eligibleForFreeMint = (_numberMinted(msg.sender) < 5);
        if (_numberMinted(msg.sender) < 5) {
            // Allow free mint
            require(
                quantity + _numberMinted(msg.sender) <= 5,
                "free limit exceeded"
            );
            require(msg.value == 0, "Free mints cannot have a cost");
        } else {
            // Require payment for non-free mints
            require(msg.value >= mintRate * quantity, "Insufficient payment");
        }
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function _canSetOwner() internal view virtual returns (bool) {}
}