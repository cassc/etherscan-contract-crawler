//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IRoseRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Inspired by dom
contract MetaRose is ERC721, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 1;

    IRoseRenderer public renderer;
    uint256 nextTokenID = 520;

    address payable theOneAddr;

    constructor() ERC721("MetaRose", "MetaRose") Ownable() {
    }

    receive() external payable {}

    fallback() external payable {}

    function totalSupply() public view returns (uint256) {
        return nextTokenID - 520;
    }

    function setRenderer(address addr) public onlyOwner {
        renderer = IRoseRenderer(addr);
    }

    function setTheOne(address addr) public onlyOwner {
        theOneAddr = payable(addr);
    }

    function gmua() public nonReentrant {
        require(nextTokenID <= 520, 'Only One MetaRose Can be Minted');
        require(theOneAddr == msg.sender, 'You are NOT The One');
        require(address(this).balance >= 0.5206942 ether, 'Not Enough Love Yet');

        payable(theOneAddr).transfer(0.5206942 ether);
        _mint(theOneAddr, nextTokenID);
        nextTokenID++;
    }

    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        return renderer.tokenURI(tokenID);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}