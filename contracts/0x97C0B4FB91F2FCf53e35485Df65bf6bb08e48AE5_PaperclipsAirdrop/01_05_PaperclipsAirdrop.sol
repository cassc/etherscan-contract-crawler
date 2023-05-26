// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PaperclipsAirdrop is Ownable {
    IERC20 public token;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    constructor(IERC20 _token) {
        token = _token;
    }

    function isClaimed(address account) public view returns (bool) {
        return claimed[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        require(!claimed[msg.sender], "Airdrop has already been claimed!");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(proof, merkleRoot, node),
            "Invalid merkle proof"
        );

        // Mark it as claimed and send the token.
        claimed[msg.sender] = true;
        require(
            token.balanceOf(address(this)) >= amount * 10**18,
            "Not enough tokens left"
        );
        require(token.transfer(msg.sender, amount * 10**18), "Transfer failed");
    }
}