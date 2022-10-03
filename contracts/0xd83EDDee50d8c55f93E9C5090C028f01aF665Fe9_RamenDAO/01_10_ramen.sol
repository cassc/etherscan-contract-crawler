// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RamenDAO is ERC721
 {
    uint256 public maxSupply = 30; 
    uint256 public totalSupply = 0;
    address private immutable owner;
    uint256 public immutable price = 0.055 ether;

    constructor() ERC721("RamenDAO @ Devcon by Crypto Nomads Club", "RAMEN") {
        owner = msg.sender;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "ipfs://QmQbYbAsebdMgH1kwz7t55D4fAjKNrf4WofzWmP8VYV6D6/";
    }

    function setMaxSupply(uint256 newMaxSupply) public {
        require(msg.sender == owner, "only owner");
        maxSupply = newMaxSupply;
    }

    function mint(uint256 amount) external payable {
        require(totalSupply + amount <= maxSupply, "No ramen left");
        require(
            amount <= 3,
            "Leave some ramen for the others ser"
        );
        require(price * amount <= msg.value, "Inflation ser. Add more ETH");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
        totalSupply += amount;
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }

}