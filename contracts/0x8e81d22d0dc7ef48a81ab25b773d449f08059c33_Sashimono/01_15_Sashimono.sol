// SPDX-License-Identifier: MIT
//
//
// Twitter: https://twitter.com/bushidosnft
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Sashimono is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MAX_SASHIMONO = 888;
    bool public mintIsActive = false;
    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("Sashimono", "PRINCIPLE") {
        setBaseURI(baseURI);
    }

    //User Function to Claim
    function claimSashimono() public {
        require(mintIsActive, "Must be active to mint Sashimono");
        require(totalSupply() < MAX_SASHIMONO, "All sashimono have been claimed");
        require(totalSupply().add(1) <= MAX_SASHIMONO, "Mint would exceed max supply of Sashimono");
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    //Only owner actions

    //Turn sale active
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    // internal function override
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // set baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    //Witdraw funds
    function withdrawAll() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //See how many sashimono claimed
    function totalClaimed() public view returns (uint256) {
        return totalSupply();
    }
}