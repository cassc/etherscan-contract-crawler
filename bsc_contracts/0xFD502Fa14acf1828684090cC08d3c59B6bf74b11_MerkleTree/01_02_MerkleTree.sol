// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

//import { ERC20 } from "./SolmateERC20.sol"; // Solmate: ERC20
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

interface IAirdropClaim {
    function setUserInfo(address _who, address _to, uint256 _amount) external returns(bool status);
}

/// @title MerkleClaimERC20
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <[email protected]>
/// @dev Solmate ERC20 includes unused _burn logic that can be removed to optimize deployment cost

/*
    Based off Solmate [thanks]. Merkle contract to claim Thena Airdrop.
*/

contract MerkleTree {

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

    /// @notice mapping of LiquidDriver FNFT smartWallet to Owner
    mapping(address => address) public swFnftToOwner;
    mapping(address => address) public ownersToFnft;
    mapping(address => bool) public isFnftOwner;

    /// @notice what is used for
    string public info = "MerkleTree ecosystem Airdrop";

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
        airdropClaim = _airdropClaim;
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
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {

        // check claim is started
        require(init, 'not started');

        // set user
        address _userToCheck = msg.sender;

        // if liquid driver fnft holder then _user is the smartwallet
        if(isFnftOwner[msg.sender]){
            _userToCheck = ownersToFnft[msg.sender];
        }

        // Throw if address has already claimed tokens
        if (hasClaimed[msg.sender]) revert AlreadyClaimed(_userToCheck);   
        

        // Verify merkle proof, or revert if not in tree
        /*bytes32 leaf = keccak256(abi.encodePacked(_userToCheck, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle(_userToCheck,amount);*/

        // Mint tokens to msg.sender
        bool _status = IAirdropClaim(airdropClaim).setUserInfo(msg.sender, to, amount);
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
        require(init == false);
        merkleRoot = _merkleRoot;
    }

    function _init() external onlyOwner {
        require(init == false);
        require(merkleRoot != bytes32(0), 'root 0');
        init = true;
    }

    /// @notice Change owner
    /// @param _owner new Owner
    function setOwner(address _owner) external onlyOwner  {
        require(_owner != address(0));
        owner = _owner;
    }


    function setFNFTOwners(address[] memory owners, address[] memory smartWallet) external onlyOwner {
        require( owners.length == smartWallet.length );

        uint i = 0;
        uint len = owners.length;
        address _owner;
        address _sw;
        for(i; i < len; i++){
            _sw = smartWallet[i];
            _owner = owners[i];
            require(_owner != address(0));
            require(_sw != address(0));
            swFnftToOwner[_sw] = _owner;
            ownersToFnft[_owner] = _sw;
            isFnftOwner[_owner] = true;
        }

    }

}