// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IENS} from "./ens/interfaces/IENS.sol";
import {IENSResolver} from "./ens/interfaces/IENSResolver.sol";
import {IENSRegistrar} from "./ens/interfaces/IENSRegistrar.sol";
import "./ens/interfaces/ISoulRegistrar.sol";
import {IERC721} from "./lib/ERC721/interface/IERC721.sol";

contract SoulRegistrar is ISoulRegistrar, Ownable2Step, ReentrancyGuard {

    // ======================== Immutable Storage ========================
    /**
     * The interface of the public ENS registry.
     * @dev Dependency-injectable for testing purposes, but otherwise this is the
     * canonical ENS registry at 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e.
     */
    IENS public immutable ensRegistry;

    /**
     * The interface of the ENSResolver.
     * The ENS public resolver at 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41
     */
    IENSResolver public immutable ensResolver;

    // ================ Mutable Ownership Configuration ==================

    /**
     * The address of the contract's relayer.
     * Relayer has the permission to relay certain actions to this contract (i.e., set MerkleRoot)
     */
    address private _relayer;

    // ====================== Merkle Root Configuration ====================

    mapping(bytes32 => bytes32) public merkleRoots;

    // Root shard => id => True/False
    mapping(bytes32 => mapping(bytes32 => bool)) public claimed;

    // ================ Mutable Registration Configuration ==================

    bool public registrable;

    // Root node => funding recipient => fee amount
    mapping(bytes32 => NodeFeeConfig) public feeConfigs;
    struct NodeFeeConfig {
        address payable recipient;
        uint256 fee;
    }

    // Soul commission charge bips
    uint256 public commissionBips;

    // ================================ Events ==============================

    event RelayerUpdated(address newRelayer);
    event RegistrableUpdated(bool newRegistrable);
    event RegisteredSubdomain(bytes32 indexed rootNode, string label, address receiver);
    event MerkleRootUpdated(bytes32 indexed rootShard, bytes32 newMerkleRoot);
    event FeeUpdated(bytes32 indexed rootNode, uint256 newFee);
    event CommissionBipsUpdated(uint256 newBips);
    event FeePayout(address indexed from, address indexed to, uint256 value);
    event FeeWithdrawal(address indexed from, address indexed to, uint256 value);

    // ================================ Errors ==============================

    error Unauthorized();
    error RegistrationHasNotStarted();
    error InvalidParams();
    error InsufficientBalance();
    error AlreadyClaimed();
    error InvalidProof();
    error SubdomainAlreadyOwned();

    // ============================== Modifiers ==============================

    /**
     * @dev Modifier to check whether the `msg.sender` is the relayer.
     */
    modifier onlyRelayer() {
        if(msg.sender != relayer()) revert Unauthorized();
        _;
    }

    modifier canRegister() {
        if(!registrable) revert RegistrationHasNotStarted();
        _;
    }

    // ============================ Constructor ==============================

    /**
     * @notice Constructor that sets the ENS root name and root node to manage.
     * @param ensRegistry_ The address of the ENS registry
     * @param ensResolver_ The address of the ENS resolver
     */
    constructor(
        address ensRegistry_,
        address ensResolver_
    ) {
        ensRegistry = IENS(ensRegistry_);
        ensResolver = IENSResolver(ensResolver_);
        setRegistrable(true);
    }

    // ====================== Configuration Management ========================

    /**
     * Allows the owner to pause registration.
     */
    function setRegistrable(bool newRegistrable) public onlyOwner {
        registrable = newRegistrable;
        emit RegistrableUpdated(newRegistrable);
    }

    /**
     * Allows the owner to set a relayer address
     */
    function setRelayer(address newRelayer) public onlyOwner {
        _relayer = newRelayer;
        emit RelayerUpdated(newRelayer);
    }

    /**
     * Allows relayer to set/update registration fee recipient and amount
     */
    function setRegistrationFee(bytes32 rootNode, NodeFeeConfig memory feeConfig) external onlyRelayer {
        feeConfigs[rootNode] = feeConfig;
        emit FeeUpdated(rootNode, feeConfig.fee);
    }

    /**
     * Allows the owner to set the commission bips
     */
    function setCommissionBips(uint256 newBips) external onlyOwner {
        if(newBips > 10000) revert InvalidParams();

        commissionBips = newBips;
        emit CommissionBipsUpdated(newBips);
    }

    /**
     * Allows the Relayer to set the MerkleRoot
     */
    function setMerkleRoot(bytes32 rootShard, bytes32 newMerkleRoot) external onlyRelayer {
        merkleRoots[rootShard] = newMerkleRoot;
        emit MerkleRootUpdated(rootShard, newMerkleRoot);
    }

    // ================================ Getters ===============================

    function relayer() public view returns (address) {
        return _relayer == address(0) ? owner() : _relayer;
    }

    // ========================= Subdomain Registration ========================

    /**
     * This method registers an ENS given label to a given address, provided that there is a proof of its
     * inclusion (label and owner address) in the membership merkle tree.
     * Before calling this function, the root node owner should already called setApprovalForAll
     * on ENSRegistry to add this contract as the root node's authorised operator.
     * @param rootNode The hashed node for the ens root
     * @param rootShard The merkle proof shard
     * @param receivers The list of addresses that should own the labels.
     * @param labels The list of ENS labels
     * @param merkleProofs The list of merkle proof
     */
    function registerWithProof(
        bytes32 rootNode,
        bytes32 rootShard,
        address[] calldata receivers,
        string[] calldata labels,
        bytes32[][] calldata merkleProofs
    )
        external
        payable
        canRegister
        nonReentrant
    {
        if(receivers.length != labels.length || receivers.length != merkleProofs.length) revert InvalidParams();

        // registration fee
        NodeFeeConfig memory feeConfig = feeConfigs[rootNode];
        if(msg.value < feeConfig.fee) revert InsufficientBalance();

        uint256 payout = feeConfig.fee * (10000 - commissionBips) / 10000 * receivers.length;
        if (payout > 0) {
            Address.sendValue(feeConfig.recipient, payout);
            emit FeePayout(address(this), feeConfig.recipient, payout);
        }

        for (uint i = 0; i < receivers.length; i++) {
            bytes32 merkleLeaf = keccak256(abi.encodePacked(receivers[i], rootNode, labels[i]));
            _register(rootNode, rootShard, receivers[i], labels[i], merkleProofs[i], merkleLeaf);
        }
    }

    /**
     * @notice Allow membership NFT owner to claim ENS subdomain of the root node. Only one subdomain can be
     * claimed per NFT token ID.
     * Before calling this function, the root node owner should already called setApprovalForAll
     * on ENSRegistry to add this contract as the root node's authorised operator.
     * @param nftContract The contract address of the membership NFT
     * @param tokenId The token id of the membership NFT
     * @param rootNode The node of the root name
     * @param label The subdomain label
     * @param rootShard The merkle proof shard
     * @param merkleProof The list of merkle proof
     */
    function registerWithNFTOwnership(
        address nftContract,
        uint256 tokenId,
        bytes32 rootNode,
        string calldata label,
        bytes32 rootShard,
        bytes32[] calldata merkleProof
    )
        external
        canRegister
    {
        bytes32 claimId = keccak256(abi.encodePacked(tokenId, nftContract));
        //  Make sure it's not already claimed.
        if(claimed[rootShard][claimId]) revert AlreadyClaimed();
        // Mark it as claimed.
        claimed[rootShard][claimId] = true;

        // NOTE: No registration fee for existing NFT holders.
        if(msg.sender != IERC721(nftContract).ownerOf(tokenId)) revert Unauthorized();

        bytes32 merkleLeaf = keccak256(abi.encodePacked(nftContract, rootNode, "*"));
        _register(rootNode, rootShard, msg.sender, label, merkleProof, merkleLeaf);
    }

    /**
     * @notice Assigns an ENS subdomain of the root node to a target address.
     * Private function. Before calling this function,
     * the root node owner should already called setApprovalForAll on ENSRegistry,
     * to add this contract as the root node's authorised operator.
     * @param rootNode The node of the root name
     * @param rootShard The merkle proof shard
     * @param receiver The owner of the subdomain
     * @param label The subdomain label
     * @param merkleProof The list of merkle proof
     * @param merkleLeaf The leaf of merkle proof
     */
    function _register(
        bytes32 rootNode,
        bytes32 rootShard,
        address receiver,
        string memory label,
        bytes32[] memory merkleProof,
        bytes32 merkleLeaf
    )
        private
    {
        // Verify the merkle proof.
        if(!MerkleProof.verify(merkleProof, merkleRoots[rootShard], merkleLeaf)) revert InvalidProof();
        // We don't need to mark it as claimed, because the label is already scarce.

        // Register the node with ens
        bytes32 labelNode = keccak256(abi.encodePacked(label));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));

        if(ensRegistry.owner(node) != address(0)) revert SubdomainAlreadyOwned();

        ensRegistry.setSubnodeRecord(rootNode, labelNode, receiver, address(ensResolver), 0);
        ensResolver.setAddr(node, receiver);

        emit RegisteredSubdomain(rootNode, label, receiver);
    }

    // ========================== Admin Functions ==========================

    function withdrawFees(address payable to) external onlyOwner
    {
        uint256 balance = address(this).balance;
        Address.sendValue(to, balance);
        emit FeeWithdrawal(address(this), to, balance);
    }
}