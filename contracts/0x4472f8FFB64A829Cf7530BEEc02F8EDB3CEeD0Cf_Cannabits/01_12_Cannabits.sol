// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Cannabits is ERC777, Pausable, Ownable {
    bool public supplyCapped = false;
    bytes32 public allowanceMerkleRoot;

    mapping(address => uint256) public claimed;

    constructor(bytes32 merkleRoot) ERC777("Cannabits", "CBITS", new address[](0)) {
        allowanceMerkleRoot = merkleRoot;
    }

    function authorizeOperators(address[] memory addresses) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            authorizeOperator(addresses[i]);
        }
    }

    function revokeOperators(address[] memory addresses) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            revokeOperator(addresses[i]);
        }
    }

    function setAllowanceMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        allowanceMerkleRoot = merkleRoot;
    }

    function claim(uint256 amount, uint256 allowance, bytes32[] calldata proof) public whenNotPaused whenSupplyNotCapped {
        require(verifyAllowance(msg.sender, allowance, proof), "Failed allowance verification");
        require(claimed[msg.sender] + amount <= allowance, "Request higher than allowance");

        claimed[msg.sender] = claimed[msg.sender] + amount;

        _mint(msg.sender, amount * 10**uint(decimals()), "", "");
    }

    function getQuantityClaimed(address claimee) public view returns (uint256) {
        return claimed[claimee];
    }

    function verifyAllowance(address account, uint256 allowance, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, allowanceMerkleRoot, generateAllowanceMerkleLeaf(account, allowance));
    }

    function generateAllowanceMerkleLeaf(address account, uint256 allowance) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowance));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function capSupply() public onlyOwner {
        supplyCapped = true;
    }

    modifier whenSupplyNotCapped() {
        require(!supplyCapped, "Supply permanently capped");
        _;
    }
}