// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BirdieVIPPass is ERC1155, Ownable {
    string public name = "Birdie VIP Passes";
    string public symbol = "BIRDIEVIP";

    mapping(address => uint256) public whitelist;

    constructor() ERC1155("https://web3birdie.io/tokens/BirdieVIPPass.json") {
    }

    function ClaimPasses() public {
        uint256 amount = whitelist[msg.sender];
        require(amount > 0, "Address is not whitelisted");
        _mint(_msgSender(), 1, amount, "");
        delete whitelist[msg.sender];
    }

    function devMint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), 1, amount, "");
    }

    function addToWhitelist(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
        require(addresses.length == amounts.length, "Array lengths do not match");

        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = amounts[i];
        }
    }

    function devMintForAddress(address receiver, uint256 amount) public onlyOwner {
        _mint(receiver, 1, amount, "");
    }
}