// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TubaDAO is ERC721Enumerable, ReentrancyGuard, Ownable {
    string private baseURI;

    constructor(string memory initBaseURI) ERC721("TubaDAO", "TUBADAO") Ownable() {
        baseURI = initBaseURI;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function mint() public payable nonReentrant {
        uint256 latestId = totalSupply();
        _safeMint(_msgSender(), latestId);

        require(totalSupply() <= 1069, "Max mint amount");
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
}