// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZeroV2 is ERC20, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 10240000 * (10 ** 18);
    uint256 public constant RATE = 1024 * (10 ** 18);
    uint256 public constant CYCLE = 4 seconds;

    uint256 public nextMintTime;
    mapping(address => bool) public hasClaimed;

    constructor() ERC20("ZeroV2", "ZEROV2") {
        _mint(msg.sender, TOTAL_SUPPLY / 1000); // Mint 0.1% of total supply to deployer
        nextMintTime = block.timestamp + CYCLE;
    }

    function claim() external nonReentrant {
        require(block.timestamp >= nextMintTime, "Too early to claim");
        require(!hasClaimed[msg.sender], "You have already claimed");

        uint256 totalSupply = totalSupply();
        require(totalSupply + RATE <= TOTAL_SUPPLY, "Total supply exceeded");
        
        _mint(msg.sender, RATE);
        nextMintTime = block.timestamp + CYCLE;
        hasClaimed[msg.sender] = true;
    }

    receive() external payable nonReentrant {
        require(block.timestamp >= nextMintTime, "Too early to claim");
        require(!hasClaimed[msg.sender], "You have already claimed");

        uint256 totalSupply = totalSupply();
        require(totalSupply + RATE <= TOTAL_SUPPLY, "Total supply exceeded");

        _mint(msg.sender, RATE);
        nextMintTime = block.timestamp + CYCLE;
        hasClaimed[msg.sender] = true;
    }
}