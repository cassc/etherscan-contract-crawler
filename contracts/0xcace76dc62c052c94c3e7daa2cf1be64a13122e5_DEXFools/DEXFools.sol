/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract DEXFools {
    string public name = "DEXFools token";
    string public symbol = "DEXF";
    string public logoURI = "https://beige-persistent-sawfish-427.mypinata.cloud/ipfs/QmW3PkZxKPKrENMdXPFtmt98gQGp3cGiVbeBsaVAhXm3fH?_gl=1*fmcxxe*_ga*NDgwNDI0ODQ1LjE2OTc2OTg5NzU.*_ga_5RMPXG14TE*MTY5Nzk0NDk5Ny41LjEuMTY5Nzk0NTE2Mi4zMi4wLjA.";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public creatorAddress;
    address public devAddress;
    address public burnAddress;

    uint256 public buyTaxRate = 2; // 2% fee to be burned
    uint256 public sellTaxRate = 2; // 2% to be burned
    uint256 public burnThreshold;
    bool public taxRatesChanged;
    bool public thresholdReached;
    uint256 public maxSellPercentage = 5; // 0.005% of the total supply
    uint256 public maxSellCooldown = 1 hours;

    address public owner;  // Track the owner of the contract

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;  // Set the contract creator as the owner initially
        creatorAddress = msg.sender;
        devAddress = address(0x460c170Ef03B35a206F28De06f74496D579B4Fa1);
        totalSupply = 420_000_000_000 * 10 ** uint256(decimals); // 420 billion tokens
        burnAddress = address(0x000000000000000000000000000000000000dEaD);
        burnThreshold = (totalSupply * 100) / 100;
        logoURI = "https://beige-persistent-sawfish-427.mypinata.cloud/ipfs/QmW3PkZxKPKrENMdXPFtmt98gQGp3cGiVbeBsaVAhXm3fH?_gl=1*fmcxxe*_ga*NDgwNDI0ODQ1LjE2OTc2OTg5NzU.*_ga_5RMPXG14TE*MTY5Nzk0NDk5Ny41LjEuMTY5Nzk0NTE2Mi4zMi4wLjA.";
    }

    // Set the creator address (can only be called once)
    function setCreatorAddress(address _creator) public {
        require(msg.sender == creatorAddress, "Only the creator can set this");
        require(creatorAddress == address(0), "Creator address already set");
        creatorAddress = _creator;
    }

    // Set the dev address (can only be called once)
    function setDevAddress(address _dev) public {
        require(msg.sender == creatorAddress, "Only the creator can set this");
        require(devAddress == address(0), "Dev address already set");
        devAddress = _dev;
    }

    // Mint tokens to the creator address (can only be called by the creator)
    function mint(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can mint");
        require(totalSupply + amount >= totalSupply, "Overflow protection");
        totalSupply += amount;
        balanceOf[creatorAddress] += amount;
        emit Transfer(address(0), creatorAddress, amount);
    }

    // Renounce ownership
    function renounceOwnership() public onlyOwner {
        owner = address(0);  // Set the owner address to address(0) to renounce ownership
    }

    // Transfer function
    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 buyFee = (value * buyTaxRate) / 100; // Calculate buy fee
        uint256 sellFee = (value * sellTaxRate) / 100; // Calculate sell fee

        uint256 transferValue = value - buyFee - sellFee; // Calculate the amount to transfer to 'to'

        // Transfer the fees to the burn address
        balanceOf[burnAddress] += buyFee + sellFee;

        // Transfer the remaining tokens to the 'to' address
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferValue;

        emit Transfer(msg.sender, to, transferValue); // Emit a transfer event

        return true;
    }
}