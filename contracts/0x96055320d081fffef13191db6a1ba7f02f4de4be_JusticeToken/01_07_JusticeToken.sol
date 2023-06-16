// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

interface IOwnable {
    function owner() external view returns (address);
}

/// @title JusticeToken
/// @author opnxj
/// @notice Custom ERC20 implementation for a Justice Token
/// @dev This contract incorporates elements from Anish Agnihotri's merkle-airdrop-starter contract:
///      https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol
contract JusticeToken is ERC20, Ownable {
    address public immutable factory;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether; // 1 billion

    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    uint256 public claimDeadline;

    address public minter;

    event Claim(address indexed to, uint256 amount);
    event MerkleRootUpdated(bytes32 newMerkleRoot);
    event ClaimDeadlineUpdated(uint256 newClaimDeadline);
    event MinterUpdated(address newMinter);

    modifier checkMaxSupply(uint256 amount) {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Mint would exceed the maximum supply"
        );
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Only the minter can call this function");
        _;
    }

    /// @notice Initializes the JusticeToken contract
    /// @dev OZ's ERC20 implementation defaults to 18 decimals
    /// @param _symbol The symbol of the Justice Token
    /// @param _merkleRoot The initial Merkle root for airdrop claims
    /// @param _claimDeadline The deadline for claiming tokens (unix timestamp)
    constructor(
        string memory _symbol,
        bytes32 _merkleRoot,
        uint256 _claimDeadline
    ) ERC20(string(abi.encodePacked("Justice Token - ", _symbol)), _symbol) {
        factory = msg.sender;
        merkleRoot = _merkleRoot;
        claimDeadline = _claimDeadline;

        minter = owner();

        emit MerkleRootUpdated(_merkleRoot);
        emit ClaimDeadlineUpdated(_claimDeadline);
    }

    /// @notice Retrieves the owner of this Justice Token
    /// @dev This function overrides the ownership of this individual contract by
    ///      pointing it to the owner of its factory
    /// @return The owner's address
    function owner() public view override returns (address) {
        return IOwnable(factory).owner();
    }

    /// @notice Allows the owner to update the minter
    /// @param newMinter The new minter address
    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    /// @notice Mints new tokens to the contract owner
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(
        address to,
        uint256 amount
    ) external onlyMinter checkMaxSupply(amount) {
        _mint(to, amount);
    }

    /// @notice Allows the owner to update the Merkle root
    /// @param newMerkleRoot The new Merkle root value
    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
        emit MerkleRootUpdated(newMerkleRoot);
    }

    /// @notice Allows the owner to update the claim deadline
    /// @param newClaimDeadline The new claim deadline (unix timestamp)
    function updateClaimDeadline(uint256 newClaimDeadline) external onlyOwner {
        claimDeadline = newClaimDeadline;
        emit ClaimDeadlineUpdated(newClaimDeadline);
    }

    /// @notice Allows claiming tokens if address is part of the Merkle tree and within the claim deadline
    /// @param to Address of the claimant
    /// @param amount Amount of tokens claimed
    /// @param proof Merkle proof to prove address and amount are in the tree
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external checkMaxSupply(amount) {
        require(!hasClaimed[to], "Address has already claimed tokens");
        require(
            block.timestamp <= claimDeadline,
            "Airdrop claim deadline has passed"
        );

        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Invalid Merkle proof"
        );

        hasClaimed[to] = true;
        _mint(to, amount);

        emit Claim(to, amount);
    }
}