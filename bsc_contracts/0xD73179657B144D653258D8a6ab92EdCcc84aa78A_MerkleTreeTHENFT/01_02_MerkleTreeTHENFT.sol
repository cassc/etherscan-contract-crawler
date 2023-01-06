// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

//import { ERC20 } from "./SolmateERC20.sol"; // Solmate: ERC20
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

interface IAirdropClaim {
    function claim(address _who, uint _amount, address _to) external returns(bool status);
}



/// @title MerkleTreeTHENFT
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <[email protected]>
/// @dev Solmate ERC20 includes unused _burn logic that can be removed to optimize deployment cost

/*
    Based off Solmate [thanks]. Merkle contract to claim Thena Airdrop.
*/

contract MerkleTreeTHENFT {

    /// ============ Mutable storage ============

    /// @notice ERC20-claimee inclusion root
    bytes32 public merkleRoot;

    /// @notice airdrop managment
    address public airdropClaim;

    /// @notice owner of the contract
    address public owner;

    /// @notice init flag
    bool public init;

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// @notice what is used for
    string public info = "MerkleTree theNFT Airdrop";

    /// ============ Errors ============

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed(address _who);
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle(address _who, uint _amnt);


    /// ============ Modifier ============
    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaimERC20 contract
    /// @param _airdropClaim claim manager
    constructor(address _airdropClaim) {
        airdropClaim = _airdropClaim; // THE NFT AIRDROP CLAIM CONTRACT
        owner = msg.sender;
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param who has right to claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event ClaimSet(address indexed who,address indexed to, uint256 amount);


    /// ============ Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address to send claims
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {

        // check claim is started
        require(init, 'not started');

        // Throw if address has already claimed tokens
        if (hasClaimed[msg.sender]) revert AlreadyClaimed(msg.sender);

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle(msg.sender,amount);

        // Mint tokens to address
        bool _status = IAirdropClaim(airdropClaim).claim(msg.sender, amount, to);
        require(_status);
        
        // Set address to claimed
        hasClaimed[msg.sender] = true;

        // Emit claim event
        emit ClaimSet(msg.sender, to, amount);
    }


    /// @notice Set Merkle Root (before starting the claim!)
    /// @param _merkleRoot merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot != bytes32(0), 'root 0');
        merkleRoot = _merkleRoot;
    }

    function _init() external onlyOwner {
        require(init == false);
        require(merkleRoot != bytes32(0), 'root 0');
        init = true;
    }

    /// @notice Change owner
    /// @param _owner new Owner
    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0));
        owner = _owner;
    }

}