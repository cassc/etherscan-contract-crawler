// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUCKSEC is ERC20, Ownable {
    mapping (address => bool) public hasClaimed;
    bool public isClaimingActive = false;
    uint public maxClaimable = 10000 * (10 ** 18);
    uint private claimableTokens;
    
    constructor() ERC20("FUKSEC Token", "FUKSEC") {
        uint totalSupply = 200000000 * (10 ** 18);
        uint deployerTokens = totalSupply * 80 / 100;
        claimableTokens = totalSupply - deployerTokens;
        _mint(msg.sender, deployerTokens);
    }

    function claimTokens(uint claimAmount) public {
        require(isClaimingActive, "Claiming is not active at the moment");
        require(!hasClaimed[msg.sender], "You have already claimed tokens");
        require(claimAmount <= maxClaimable, "Claim amount exceeds the maximum limit");
        require(claimAmount <= claimableTokens, "Not enough tokens left to claim");

        _mint(msg.sender, claimAmount);
        hasClaimed[msg.sender] = true;
        claimableTokens -= claimAmount;
    }

    function toggleClaiming() public onlyOwner {
        isClaimingActive = !isClaimingActive;
    }
}