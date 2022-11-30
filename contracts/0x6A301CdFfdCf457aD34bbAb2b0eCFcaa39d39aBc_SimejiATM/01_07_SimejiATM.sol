// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnerPausable.sol";

contract SimejiATM is OwnerPausable, ReentrancyGuard {
    bytes32 private merkleRoot;
    mapping(bytes32 => bool) private withdrawUser;
    event SimejiTransferEvent(address indexed account, uint256 indexed amount, uint256 indexed nonce, uint32 score);

    constructor() {
    }

    function dispost() external payable {
    }
    
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function withdraw(uint256 amount, uint256 nonce, uint32 score, bytes32[] calldata merkleProof)
        external
        nonReentrant
        whenNotPaused {
        (bytes32 key, bool result) = verify(msg.sender, amount, nonce, merkleProof);
        require(result, "The proof is invalidate.");
        require(address(this).balance > 0, "Balance is no enough");
        require(withdrawUser[key] == false, 'User has withdrawn');
        withdrawUser[key] = true;

        payable(msg.sender).transfer(amount);

        emit SimejiTransferEvent(msg.sender, amount, nonce, score);
    }

    function verify(address account, uint256 amount, uint256 nonce, bytes32[] calldata merkleProof) public view returns(bytes32, bool) {
        if (merkleRoot == "") {
            return (0, false);
        }

        bytes32 leaf = keccak256(abi.encodePacked(account, amount, nonce));
        bool ret = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        
        return (leaf, ret);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    function getMerkleRoot() external view onlyOwner returns(bytes32) {
        return merkleRoot;
    }
    
    function checkout() external onlyOwner whenNotPaused {
        require(address(this).balance > 0, "Balance is not enough.");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function userWithdraw(uint256 amount, uint256 nonce) external view returns(bytes32, bool) {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, amount, nonce));
        return (key, withdrawUser[key]);
    }
    
    fallback () external {
    }
    
    receive() external payable {
    }
}