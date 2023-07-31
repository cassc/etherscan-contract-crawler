// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract gALSD is ERC20, Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    constructor(bytes32 _root) ERC20("Genesis ALSD", "gALSD") {
        merkleRoot = _root;
    }

    function mintTokens(uint256 _amount, bytes32[] memory _proof) public {
        require(!claimed[msg.sender], "Tokens already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(verify(leaf, _proof), "Invalid proof");

        claimed[msg.sender] = true;

        _mint(msg.sender, _amount);
    }

    function verify(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) private view returns (bool) {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == merkleRoot;
    }
}