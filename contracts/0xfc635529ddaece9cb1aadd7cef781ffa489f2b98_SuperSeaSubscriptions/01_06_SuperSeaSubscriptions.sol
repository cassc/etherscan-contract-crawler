// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SuperSeaSubscriptions is Pausable, Ownable {
    using ECDSA for bytes32;

    mapping(address => mapping(uint256 => bool)) seenNonces;
    mapping (address => uint256) pendingReturns;

    address signingAddress;
    uint256 totalPendingReturns = 0;

    struct SubscriptionData {
        address _to; 
        uint256 price;
        uint256 cut;
        address payoutAddress;
        uint16 dealIdentifier;
        uint256 duration;
        uint256 nonce;
        uint256 expiresAt;
    }

    event PartnerWithdraw(address _address, uint256 amount);
    event SignedSubscription(SubscriptionData args, uint256 startDate);

    constructor(address _signingAddress) {
        signingAddress = _signingAddress;
    }

    modifier isEligibleForSubscription (SubscriptionData calldata args, bytes calldata signature) {
        bytes32 hash = keccak256(abi.encodePacked(args._to, args.price, args.cut, args.payoutAddress, args.dealIdentifier, args.duration, args.nonce, args.expiresAt));
        bytes32 messageHash = hash.toEthSignedMessageHash();

        // Verify signature
        address signer = messageHash.recover(signature);
        require(signer == signingAddress, "Invalid signature"); 
        require(block.timestamp < args.expiresAt, "Signature has expired");
        require(!seenNonces[args._to][args.nonce], "Invalid nonce");
        require(args.cut <= args.price, "Cut must be less than or equal to price");
        require(msg.value == args.price, "Not enough ETH");

        _;
    }

    function subscribe(SubscriptionData calldata args, bytes calldata signature) public payable isEligibleForSubscription(args, signature) whenNotPaused {
        seenNonces[args._to][args.nonce] = true;

        if(args.cut > 0) {
            pendingReturns[args.payoutAddress] += args.cut;
            totalPendingReturns += args.cut;
        }
        
        uint256 startingDate = block.timestamp;

        emit SignedSubscription(args, startingDate);
    }

    function getPendingReturns(address _to) public view returns (uint256) {
        return pendingReturns[_to];
    }

    function getTotalPendingReturns() public view returns (uint256) {
        return totalPendingReturns;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function partnerWithdraw() public {
        require(pendingReturns[msg.sender] > 0, "No pending returns");

        uint256 amount = pendingReturns[msg.sender];

        // Checks Effects Interactions
        pendingReturns[msg.sender] = 0;
        totalPendingReturns -= amount;

        payable(msg.sender).transfer(amount);

        emit PartnerWithdraw(msg.sender, amount);   
    }

    function updateSigningAddress (address _signingAddress) public onlyOwner {
        signingAddress = _signingAddress;
    }

    function getSigningAddress() public view returns (address) {
        return signingAddress;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        payable(msg.sender).transfer(balance - totalPendingReturns);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause()  public onlyOwner whenPaused {
        _unpause();
    }
    
}