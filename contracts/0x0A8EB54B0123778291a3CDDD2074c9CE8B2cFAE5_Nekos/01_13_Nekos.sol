// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721EnumerableSimple} from "./ERC721EnumerableSimple.sol";

contract Nekos is ERC721EnumerableSimple, Ownable {
    // Maximum amount of Nekos in existance. Ever.
    uint public constant MAX_NEKO_SUPPLY = 10000;

    // The provenance hash of all Nekos. (Root hash of all Neko hashes concatenated)
    string public constant METADATA_PROVENANCE_HASH =
        "3b67eb1f1cd246ea1c46faa3ba7492aca81c84b320f8334e93cf0f460ff5b4a4";

    // Truth.
    string public constant R = "Inspired by Vegeta, not the one in DBZ, my cat.";

    // Sale switch.
    bool public hasSaleStarted = false;

    // Bsae URI of Neko's metadata
    string private baseURI;

    constructor() ERC721("Neko", "NEKO") {}

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0); // Return an empty array
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function calculatePrice() public view returns (uint) {
        require(hasSaleStarted, "Sale hasn't started");
        return calculatePriceForToken(totalSupply());
    }

    function calculatePriceForToken(uint _id) public pure returns (uint) {
        require(_id < MAX_NEKO_SUPPLY, "Sale has already ended");

        if (_id >= 9900) {
            return 1 ether; //    9900-10000: 1.00 ETH
        } else if (_id >= 9500) {
            return 0.64 ether; // 9500-9500:  0.64 ETH
        } else if (_id >= 7500) {
            return 0.32 ether; // 7500-9500:  0.32 ETH
        } else if (_id >= 3500) {
            return 0.16 ether; // 3500-7500:  0.16 ETH
        } else if (_id >= 1500) {
            return 0.08 ether; // 1500-3500:  0.08 ETH
        } else if (_id >= 500) {
            return 0.04 ether; // 500-1500:   0.04 ETH
        } else {
            return 0.02 ether; // 0 - 500     0.02 ETH
        }
    }

    function adoptNekos(uint numNekos) public payable {
        uint _totalSupply = totalSupply();
        require(_totalSupply < MAX_NEKO_SUPPLY, "Sale has already ended");
        require(_totalSupply + numNekos <= MAX_NEKO_SUPPLY, "Exceeds maximum Neko supply");
        require(numNekos > 0 && numNekos <= 20, "You can adopt minimum 1, maximum 20 nekos");
        require(msg.value >= calculatePrice() * numNekos, "Ether value sent is below the price");

        for (uint i = 0; i < numNekos; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // #0 - #29: Reserved for giveaways and people who helped along the way
    function reserveGiveaway(uint numNekos) public onlyOwner {
        uint currentSupply = totalSupply();
        require(currentSupply + numNekos <= 30, "Exceeded giveaway limit");
        for (uint index = 0; index < numNekos; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@   @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@         @ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@ @@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@   @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@##@@ @@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@ @@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@ @@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@  @@@  @    @@@@@@@@@@@  @@@@@@@@@@
// @@@@ @@ @@  @@@  @@@@@@@@@@@ @@@ @@@@@@@
// @@@@ @@@    @@@@@ @@@@%@@@@ @@@@ @@@@@@@
// @@@@@@@       @@@ @@@@ @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@@[email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@