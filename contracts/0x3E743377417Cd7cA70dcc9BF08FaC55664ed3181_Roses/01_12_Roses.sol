// SPDX-License-Identifier: Unlicense
/*
    @@@@@@@@   @@@@@@@   @@@@@@  @@@@@@@@  @@@@@@  
    @@     @@ @@     @@ @@    @@ @@       @@    @@ 
    @@     @@ @@     @@ @@       @@       @@       
    @@@@@@@@  @@     @@  @@@@@@  @@@@@@    @@@@@@  
    @@   @@   @@     @@       @@ @@             @@ 
    @@    @@  @@     @@ @@    @@ @@       @@    @@ 
    @@     @@  @@@@@@@   @@@@@@  @@@@@@@@  @@@@@@  
    |       |     |       \|      \|   |     \|
    |/      |     |/       |/      |   |/     |
    |      \|     |        |/      |   |      |/
    |       |/    |        |       |/  |      |
*/
// by dom; use however you like

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IHelloWorldsRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Roses is ERC721,  ReentrancyGuard, Ownable {
    uint256 constant maxSupply = 1024;

    IHelloWorldsRenderer public renderer;
    uint256 nextTokenID;

    mapping (address => bool) allowList;

    constructor() ERC721("Roses", "ROSE") Ownable() {
        // genesis mint
        _mint(msg.sender, 1);
        nextTokenID = 2;
    }

    function reserve() public onlyOwner {
        // reserve 31 more
        uint256 start = nextTokenID;
        uint256 end = nextTokenID + 31; 
        for (uint i = start; i < end; ++i) {
            _mint(msg.sender, i);
        }
        nextTokenID += 31;
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenID - 1;
    }

    function setRenderer(address addr) public onlyOwner {
        renderer = IHelloWorldsRenderer(addr);
    }

    function setAllowed(address addr, bool allowed) public onlyOwner {
        allowList[addr] = allowed;
    }

    function mint(address destination) public nonReentrant {
        require(nextTokenID <= maxSupply, 'complete');
        require(allowList[msg.sender] == true || msg.sender == owner(), 'not allowed or owner');
        _mint(destination, nextTokenID);
        nextTokenID++;
    }

    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        return renderer.tokenURI(tokenID);
    }
}