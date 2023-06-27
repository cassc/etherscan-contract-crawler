// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Claim is Ownable, ReentrancyGuard {
    IERC20 public Dogc;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    constructor(
        address _dogc,
        bytes32 _merkleRoot
    ) {
        Dogc = IERC20(_dogc);
        merkleRoot = _merkleRoot;
    }

    function balance() external view returns (uint256) {
        return Dogc.balanceOf(address(this));
    }

    function claim(uint256 _amount, bytes32[] calldata _merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(!claimed[msg.sender], "Already claimed");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "unable to claim");

        claimed[msg.sender] = true;
        SafeERC20.safeTransfer(Dogc, msg.sender, _amount * 10 ** 18);
    }

    function changeSnapshot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        SafeERC20.safeTransfer(Dogc, msg.sender, Dogc.balanceOf(address(this)));
    }
}