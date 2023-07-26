// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable {
    bytes32 public merkleRoot;
    address public token;
    mapping(bytes32 => bool) public claimed;

    event Claimed(address indexed account, uint256 indexed amount);

    constructor(address _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function reclaim() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(msg.sender, balance), "Airdrop: Transfer failed.");
    }

    function verify(address account, uint256 amount, bytes32[] memory proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account, amount)));
    }

    function claim(address account, uint256 amount, bytes32[] memory proof) public {
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(!claimed[node], "Airdrop: Already claimed.");
        require(MerkleProof.verify(proof, merkleRoot, node), "Airdrop: Invalid proof.");

        claimed[node] = true;
        require(IERC20(token).transfer(account, amount), "Airdrop: Transfer failed.");
        emit Claimed(account, amount);
    }
}