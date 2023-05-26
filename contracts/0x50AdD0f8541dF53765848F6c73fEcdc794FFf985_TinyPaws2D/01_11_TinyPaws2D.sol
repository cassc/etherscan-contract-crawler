// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TinyPaws2D is ERC721, Ownable {

    string public baseURI;
    uint public totalSupply;

    mapping(address => bool) public controllers;

    constructor() ERC721("TinyPaws 2D", "TP2D") {
        baseURI = "https://storage.googleapis.com/tiny_bucket/mk_paws/";
        controllers[msg.sender] = true;
    }

    function setBaseURI(string memory _baseURIArg) external onlyController {
        baseURI = _baseURIArg;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] calldata addresses) external onlyController {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], totalSupply + i + 1);
        }
        totalSupply += addresses.length;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Wrong caller!");
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

}