//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiMerkleWhitelist is Ownable {
    mapping(uint256 => bytes32) public merkleRoots;

    function verifySenderExternal(
        bytes32[] calldata proof,
        uint256 _index,
        address _address
    ) external view returns (bool) {
        return
            MerkleProof.verifyCalldata(
                proof,
                merkleRoots[_index],
                keccak256(abi.encodePacked((_address)))
            );
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot, uint256 _index)
        external
        onlyOwner
    {
        merkleRoots[_index] = merkleRoot;
    }

    modifier onlyWhitelisted(bytes32[] calldata proof, uint256 _index) {
        require(merkleRoots[_index] != bytes32(0x0), "Merkle root is unset.");

        bool whitelisted = MerkleProof.verifyCalldata(
            proof,
            merkleRoots[_index],
            keccak256(abi.encodePacked((msg.sender)))
        );
        require(whitelisted, "MerkleWhitelist: Caller is not whitelisted");
        _;
    }
}