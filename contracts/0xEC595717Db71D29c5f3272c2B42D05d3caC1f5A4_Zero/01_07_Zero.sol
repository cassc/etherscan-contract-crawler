// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Zero is ERC20, ReentrancyGuard, Ownable {
    uint256 public constant TOTAL_SUPPLY = 10240000 * (10 ** 18);
    uint256 public constant RATE = 1024 * (10 ** 18);
    uint256 public constant CYCLE = 10 seconds;
    uint256 public constant MAX_CLAIMS = 10000;

    uint256 public nextMintTime;
    mapping(address => bool) public hasClaimed;
    uint256 public totalClaims;
    uint256 public totalMinted;

    constructor() ERC20("Zero", "ZERO") {
        _mint(msg.sender, TOTAL_SUPPLY / 1000); // Mint 0.1% of total supply to deployer
        nextMintTime = block.timestamp + CYCLE;
        totalMinted = TOTAL_SUPPLY / 1000;
    }

    function claim() external nonReentrant {
        require(block.timestamp >= nextMintTime, "Too early to claim");
        require(!hasClaimed[msg.sender], "You have already claimed");
        require(totalClaims < MAX_CLAIMS, "Maximum number of claims reached");
        require(totalMinted + RATE <= TOTAL_SUPPLY, "Exceeds total supply");

        _mint(msg.sender, RATE);
        nextMintTime = block.timestamp + CYCLE;
        hasClaimed[msg.sender] = true;
        totalClaims++;
        totalMinted += RATE;
    }

    receive() external payable nonReentrant {
        require(block.timestamp >= nextMintTime, "Too early to claim");
        require(!hasClaimed[msg.sender], "You have already claimed");
        require(totalClaims < MAX_CLAIMS, "Maximum number of claims reached");
        require(totalMinted + RATE <= TOTAL_SUPPLY, "Exceeds total supply");

        _mint(msg.sender, RATE);
        nextMintTime = block.timestamp + CYCLE;
        hasClaimed[msg.sender] = true;
        totalClaims++;
        totalMinted += RATE;
    }

    function renounceOwnership() public onlyOwner override {
        super.renounceOwnership();
    }
}