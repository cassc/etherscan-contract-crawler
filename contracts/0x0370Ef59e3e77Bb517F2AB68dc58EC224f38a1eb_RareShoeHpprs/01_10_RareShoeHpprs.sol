// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RareShoeHpprs is ERC1155, Ownable {
    string public name;
    string public symbol;

    mapping(address => bool) public controllers;

    constructor() ERC1155("https://storage.googleapis.com/hpprs-project/rareshoe/metadata/{id}") {
        name = "RARESHOE X HPPRS";
        symbol = "RSxHPPRS";
    }

    function setURI(string calldata uri) external onlyOwner {
        _setURI(uri);
    }

    function airdrop(address to, uint[] calldata ids, uint[] calldata amounts) external onlyController {
        require(ids.length == amounts.length, "ids.length == amounts.length");

        for (uint i = 0; i < ids.length; i++) {
            _mint(to, ids[i], amounts[i], "");
        }
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Wrong caller");
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}