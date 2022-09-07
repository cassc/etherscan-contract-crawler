pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Allow community net participants to claim their community rewards direct from the merkle tree instead of claiming cBSN and then switching to BSN
contract CommunityNetBSNClaim is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    /// @notice Emitted when a new merkle tree is updated
    event MerkleTreeSet(uint256 indexed version);

    /// @notice Decentralised merkle tree metadata i.e. where full data is on IPFS and what the root of the tree is
    struct MerkleTree {
        string ipfsHash;
        bytes32 root;
    }

    /// @notice Merkle tree vesting version -> Tree metadata
    mapping(uint256 => MerkleTree) public merkleTrees;

    /// @notice Version -> beneficiary -> claimed
    mapping(uint256 => mapping(address => bool)) public claimed;

    /// @notice Active version of vesting applicable to beneficiaries
    uint256 public vestingVersion;

    /// @notice Output token that users will receive
    IERC20 public vestedToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        IERC20 _vestedToken,
        address _contractOwner
    ) external initializer {
        require(_contractOwner != address(0), "Invalid owner");
        require(address(_vestedToken) != address(0), "Invalid token");

        vestedToken = _vestedToken;

        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        transferOwnership(_contractOwner);

        _pause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        require(vestingVersion > 0, "Under maintenance");
        _unpause();
    }

    function recoverERC20Funds(IERC20 _token, address _recipient, uint256 _amount) external onlyOwner {
        _token.transfer(_recipient, _amount);
    }

    /// @dev Iron rule: Any changes to a beneficiary needs to be under a new ETH address. Re-using an existing address will cause problems
    function updateTree(MerkleTree calldata _merkleTree) external onlyOwner whenPaused {
        _updateTree(_merkleTree);
    }

    /// @notice Beneficiary can call this method to claim tokens owed up to the current block
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _recipient Address receiving the tokens
    /// @param _merkleProof Merkle proof showing that they are part of the vesting merkle tree
    function claim(
        uint256 _amount,
        address _recipient,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        require(_recipient != address(0), "Zero recipient");
        require(_recipient != address(this), "Self recipient");
        require(!claimed[vestingVersion][msg.sender], "Claimed");
        require(isPartOfTree(msg.sender, _amount, _merkleProof), "Invalid proof");

        claimed[vestingVersion][msg.sender] = true;

        // Send tokens to beneficiary from contract owner (will fail if contract owner does not have tokens)
        require(
            vestedToken.transfer(_recipient, _amount),
            "Failed"
        );
    }

    /// @notice Before drawing down, check if the vesting schedule params are part of the merkle tree
    /// @param _beneficiary Address receiving the tokens
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _merkleProof Merkle proof showing that they are part of the vesting merkle tree
    function isPartOfTree(
        address _beneficiary,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        require(_amount > 0, "Invalid amount");
        require(_beneficiary != address(0), "Invalid beneficiary");

        // compute the hash of the leaf in the merkle tree
        bytes32 treeLeaf = keccak256(
            abi.encodePacked(
                _amount,
                _beneficiary
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