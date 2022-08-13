// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract JoonyonVault is Ownable {
    bytes32 public claimMerkleRoot;

    // ============ ACCESS CONTROL MODIFIERS ============
    modifier isValidClaimAddress(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                claimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in the claim list"
        );
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setClaimMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        claimMerkleRoot = _merkleRoot;
    }

    // ============ CLAIM FUNCTIONS ============
    function claim(bytes32[] calldata merkleProof)
        external
        isValidClaimAddress(merkleProof)
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function claimTokens(IERC20 token, bytes32[] calldata merkleProof)
        external
        isValidClaimAddress(merkleProof)
    {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev enable contract to receive ethers
     */
    receive() external payable {}
}