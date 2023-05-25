pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMerkleVault } from "./IMerkleVault.sol";

/// @title Funds distribution vault driven by MerkleTrees
/// @author KnownOrigin Labs Ltd.
contract MerkleVault is IMerkleVault, Pausable, ReentrancyGuard, Ownable {

    // All the information anyone needs to verify the validity of a merkle tree
    struct MerkleTreeMetadata {
        bytes32 root;
        string dataIPFSHash;
    }

    /// @notice Active merkle tree version / pointer
    uint256 public merkleVersion;

    /// @notice Merkle version -> merkle tree metadata
    mapping(uint256 => MerkleTreeMetadata) public merkleVersionMetadata;

    /// @notice Beneficiary -> Merkle version -> Whether the beneficiary has claimed their funds
    mapping(address => mapping(uint256 => bool)) public fundsClaimed;

    /// @notice Sets up the contract in a paused state
    constructor() {
        // Starting paused means claiming can be enabled by calling `unpauseClaiming()` later
        _pause();
    }

    /// @notice Owner can pause claiming to permit updating the merkle tree to a new version i.e. stop front-running
    function pauseClaiming() onlyOwner external {
        _pause();
    }

    /// @notice Owner can unpause claiming
    function unpauseClaiming() onlyOwner external {
        _unpause();
    }

    /// @notice Update the merkle tree to a new version as the contract owner
    /// @param _metadata Root and IPFS hash of the merkle tree used for the contract
    function updateMerkleTree(MerkleTreeMetadata calldata _metadata) external whenPaused onlyOwner {
        _updateMerkleTree(_metadata);
    }

    /// @notice Allows a beneficiary to claim ETH or ERC20 tokens provided they have a node in the Merkle tree
    /// @param _index Nonce assigned to beneficiary
    /// @param _token Contract address or zero address if claiming ETH
    /// @param _amount Amount being claimed - must be exact
    /// @param _merkleProof Proof for the claim
    function claim(
        uint256 _index,
        address _token,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external override whenNotPaused nonReentrant {
        _claim(_index, _token, _amount, payable(msg.sender), _merkleProof);
    }

    /// @notice Allows anyone to trigger a claim on behalf of a beneficiary
    /// @param _index Nonce assigned to beneficiary
    /// @param _token Contract address or zero address if claiming ETH
    /// @param _amount Amount being claimed - must be exact
    /// @param _merkleProof Proof for the claim
    function claimFor(
        uint256 _index,
        address _token,
        uint256 _amount,
        address payable _claimant,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused nonReentrant {
        _claim(_index, _token, _amount, _claimant, _merkleProof);
    }

    /// NOTE: This receive will fail for payments that only forward the minimum 21k GAS
    /// However, the gas use of this method is only circa 22,111 so not much more is needed
    receive() external payable {
        emit ETHReceived(msg.value);
    }

    /// @notice Externally verify whether a node is part of merkle tree before doing claim
    function isPartOfMerkleTree(
        uint256 _index,
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_index, _token, _account, _amount));
        return MerkleProof.verify(_merkleProof, merkleVersionMetadata[merkleVersion].root, node);
    }

    // Update the merkle tree version whilst validating the new metadata
    function _updateMerkleTree(MerkleTreeMetadata memory _metadata) internal {
        require(bytes(_metadata.dataIPFSHash).length == 46, "Invalid IPFS hash");

        merkleVersion += 1;
        merkleVersionMetadata[merkleVersion] = _metadata;

        emit MerkleTreeUpdated(merkleVersion);
    }

    // process a claim
    function _claim(
        uint256 _index,
        address _token,
        uint256 _amount,
        address payable _claimant,
        bytes32[] calldata _merkleProof
    ) internal {
        require(!fundsClaimed[_claimant][merkleVersion], "Funds have been claimed");

        bytes32 node = keccak256(abi.encodePacked(_index, _token, _claimant, _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleVersionMetadata[merkleVersion].root, node),
            "Merkle verification failed"
        );

        fundsClaimed[_claimant][merkleVersion] = true;

        // If token is zero - this is a claim for ETH. Otherwise its an ERC20 claim
        if (_token == address(0)) {
            (bool ethTransferSuccessful,) = _claimant.call{value: _amount}("");
            require(ethTransferSuccessful, "ETH transfer failed");
        } else {
            IERC20(_token).transfer(_claimant, _amount);
        }

        emit TokensClaimed(_token, _amount);
    }
}