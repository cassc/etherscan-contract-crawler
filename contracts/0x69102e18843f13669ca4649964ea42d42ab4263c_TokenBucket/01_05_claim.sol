// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenBucket {
    ERC20 public token = ERC20(0xF90267D1331e5b148C80Adc2aC511fF0Df96D8fD);
    address public owner;
    mapping (address => bool) public hasClaimed;
    address[] public claimers;
    mapping (address => bool) public isBlacklisted;
    uint256 public claimAmount = 500 * 10**18;

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can deposit tokens.");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
    }

    function claim() public {
        require(!hasClaimed[msg.sender], "You already claimed your token.");
        require(!isBlacklisted[msg.sender], "This address is blacklisted.");
        require(token.balanceOf(address(this)) >= claimAmount, "Not enough tokens in the contract.");
        hasClaimed[msg.sender] = true;
        claimers.push(msg.sender);
        token.transfer(msg.sender, claimAmount);
    }

    function setClaimAmount(uint256 _claimAmount) public {
        require(msg.sender == owner, "Only the owner can set the claim amount.");
        claimAmount = _claimAmount;
    }

    function resetClaims() public {
        require(msg.sender == owner, "Only the owner can reset claims.");
        for(uint256 i = 0; i < claimers.length; i++){
            hasClaimed[claimers[i]] = false;
        }
        delete claimers;
    }

    function addToBlacklist(address _address) public {
        require(msg.sender == owner, "Only the owner can add to the blacklist.");
        isBlacklisted[_address] = true;
    }

    function removeFromBlacklist(address _address) public {
        require(msg.sender == owner, "Only the owner can remove from the blacklist.");
        isBlacklisted[_address] = false;
    }
}