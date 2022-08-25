pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { LinearVestingCore } from "./LinearVestingCore.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Merkle tree based vesting contract which pulls funds from an owner address
contract SimpleMerkleVesting is LinearVestingCore, UUPSUpgradeable {
    /// @notice Emitted when a new merkle tree is updated
    event MerkleTreeSet(uint256 indexed version);

    /// @notice Decentralised merkle tree metadata i.e. where full data is on IPFS and what the root of the tree is
    struct MerkleTree {
        string ipfsHash;
        bytes32 root;
    }

    /// @notice Merkle tree vesting version -> Tree metadata
    mapping(uint256 => MerkleTree) public merkleTrees;

    /// @notice Whether the hashed agreement has been signed by the beneficiary
    /// @dev Beneficiary -> Hash of agreement -> Signed true / false
    mapping(address => mapping(bytes32 => bool)) public isAgreementSigned;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        address _vestedToken,
        address _contractOwner
    ) external initializer {
        __LinearVestingCore_init(_vestedToken, _contractOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @dev Iron rule: Any changes to a beneficiary needs to be under a new ETH address. Re-using an existing address will cause problems
    function updateTree(MerkleTree calldata _merkleTree) external onlyOwner whenPaused {
        _updateTree(_merkleTree);
    }

    /// @notice Beneficiary can call this method to claim tokens owed up to the current block
    /// @param _start Start timestamp of the schedule
    /// @param _end End timestamp of the schedule
    /// @param _cliff Cliff end timestamp for the schedule
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _recipient Account of receiving the tokens
    /// @param _hashOfSignedAgreement Signed by msg.sender
    /// @param _merkleProof Merkle proof showing that they are part of the vesting merkle tree
    function claim(
        uint256 _start,
        uint256 _end,
        uint256 _cliff,
        uint256 _amount,
        address _recipient,
        bytes32 _hashOfSignedAgreement,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        require(vestingVersion != 0, "Contract under maintenance");
        require(_recipient != address(0), "Zero recipient");
        require(_recipient != address(this), "Self recipient");
        require(_hashOfSignedAgreement != bytes32(0), "Invalid agreement");

        // verify beneficiary and schedule are in the merkle tree based on current merkle root
        require(
            isVestingSchedulePartOfTree(msg.sender, _start, _end, _cliff, _amount, _merkleProof),
            "Invalid proof"
        );

        // record the signing of the agreement the first time the draw down is triggered
        if (drawnDown[msg.sender] == 0) {
            isAgreementSigned[msg.sender][_hashOfSignedAgreement] = true;
        }

        uint256 amountToSend = _drawDown(_start, _end, _cliff, _amount, msg.sender);

        // Send tokens to beneficiary from contract owner (will fail if contract owner does not have tokens)
        require(
            vestedToken.transfer(_recipient, amountToSend),
            "Failed"
        );
    }

    /// @notice Before drawing down, check if the vesting schedule params are part of the merkle tree
    /// @param _beneficiary Address receiving the tokens
    /// @param _start Start timestamp of the schedule
    /// @param _end End timestamp of the schedule
    /// @param _cliff Cliff end timestamp for the schedule
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _merkleProof Merkle proof showing that they are part of the vesting merkle tree
    function isVestingSchedulePartOfTree(
        address _beneficiary,
        uint256 _start,
        uint256 _end,
        uint256 _cliff,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        require(_amount > 0, "Invalid amount");
        require(_beneficiary != address(0), "Invalid beneficiary");

        // compute the hash of the leaf in the merkle tree
        bytes32 treeLeaf = keccak256(
            abi.encodePacked(
                _beneficiary,
                address(vestedToken),
                _start,
                _end,
                _cliff,
                _amount
            )
        );

        // verify beneficiary and schedule are in the merkle tree based on current merkle root
        return MerkleProof.verify(_merkleProof, merkleTrees[vestingVersion].root, treeLeaf);
    }

    /// @dev Push a new merkle tree and increment the version
    function _updateTree(MerkleTree calldata _merkleTree) internal {
        require(_merkleTree.root != bytes32(0), "Invalid root");
        require(bytes(_merkleTree.ipfsHash).length == 46, "IPFS hash invalid");

        vestingVersion += 1;
        merkleTrees[vestingVersion] = _merkleTree;

        emit MerkleTreeSet(vestingVersion);
    }
}