// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sudoge is ERC721Enumerable, Ownable {
    uint256 public PRICE = 0.01 ether;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public INITIAL_LP_SUPPLY = 100;

    constructor() ERC721("Sudoge", "SUDOGE") {
        for (uint i = 0; i < INITIAL_LP_SUPPLY; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmUMNeo3QiT71icLB2xcqETQiXMyLJ6xZ8wdYbnzFnasyg";
    }
    
    function mint(uint256 amount) public payable {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply");
        require(amount < 101, "Max 100 at a time");
        require(msg.value == amount * PRICE, "0.01 ETH per");
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}