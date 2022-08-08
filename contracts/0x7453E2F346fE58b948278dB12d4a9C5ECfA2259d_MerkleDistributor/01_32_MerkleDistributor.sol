// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

// import "hardhat/console.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    PublicResolver public immutable publicResolver;
    ENS public immutable registry;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    mapping(uint256 => uint256) private numberOfClaims;
    mapping(bytes32 => bool) public domainsClaimed;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        PublicResolver publicResolver_,
        ENS registry_
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        publicResolver = publicResolver_;
        registry = registry_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32 namehash,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        require(
            registry.owner(namehash) == account,
            "Domain not owned by this account"
        );
        require(
            publicResolver.contenthash(namehash).length > 0,
            "Content hash not set"
        );
        require(
            domainsClaimed[namehash] == false,
            "Domain has already been claimed"
        );
        numberOfClaims[index] = numberOfClaims[index] + 1;

        if (numberOfClaims[index] >= 3) {
            // Mark it claimed and send the token.
            _setClaimed(index);
        }
        domainsClaimed[namehash] = true;
        require(
            IERC20(token).transfer(account, amount),
            "MerkleDistributor: Transfer failed."
        );

        emit Claimed(index, account, amount);
    }
}