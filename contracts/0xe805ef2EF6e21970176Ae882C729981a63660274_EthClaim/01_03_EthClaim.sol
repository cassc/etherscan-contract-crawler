//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/MerkleProof.sol";
import "./libraries/Math.sol";

contract EthClaim {
    using Math for uint256;
    using MerkleProof for bytes32;

    address public owner;
    bytes32 public merkleRoot;
    uint256 public claimEnds;
    bool public isActive;

    uint256 private _totalBalance;
    uint256 private _totalAmount;
    
    mapping(address => bool) private _claims;

    constructor(bytes32 _merkleRoot, uint256 totalAmount) payable {
        merkleRoot = _merkleRoot;
        owner = msg.sender;
        claimEnds = block.timestamp + (365 * 86400);
        _totalAmount = totalAmount;
    }

    receive() external payable {}
    fallback() external payable {}

    function setActive() public {
        require(msg.sender == owner, "Not owner");
        require(!isActive, "Contract already active");

        _totalBalance = address(this).balance;
    }

    function checkAmount(uint256 amount) public view returns (uint256) {
        uint256 percentOfTotal = amount.mulDivDown(1e18, _totalAmount);
        uint256 amountToSend = _totalBalance.mulDivDown(percentOfTotal, 1e18);

        return amountToSend;
    }

    function claim(bytes32[] calldata proof, uint256 amount) external returns (uint256)
    {
        require(checkProof(msg.sender, proof, amount));
        require(block.timestamp < claimEnds, "Claiming is over");

        uint256 amountToSend = checkAmount(amount);

        require(amountToSend < address(this).balance, "Amount exceeds contract balance");
        require(amountToSend > 0, "Amount cannot be 0");

        (bool sent, ) = payable(msg.sender).call{value: amountToSend}("");

        require(sent, "Failed to send ETH");

        _claims[msg.sender] = true;

        return amountToSend;
    }

    function checkProof(address account, bytes32[] calldata proof, uint256 amount) public view returns (bool) {
        require(!checkClaimed(account), "Already claimed");

        bytes32 leaf = keccak256(abi.encode(account, amount));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Proof failed");

        return true;
    }

    function checkClaimed(address account) public view returns (bool)
    {
        return _claims[account];
    }

    function withdrawLeftover() public
    {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp > claimEnds, "Claiming not done yet");

        isActive = false;

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        
        require(sent, "Failed to send ETH");
    }
}