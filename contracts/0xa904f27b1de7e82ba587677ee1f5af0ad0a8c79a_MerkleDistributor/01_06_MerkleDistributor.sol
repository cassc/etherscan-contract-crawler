//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    /// @dev Mints `value` tokens to address `to`
    function mint(address to, uint256 value) external;
}

contract MerkleDistributor is Ownable {
    using MerkleProof for bytes32[];
    using BitMaps for BitMaps.BitMap;

    /// @dev silv v2 token address
    IERC20Mintable public immutable silv;
    /// @dev bitmap of users token claim
    BitMaps.BitMap private _claimed;

    /// @dev Merkle tree's root
    bytes32 public root;

    /// @dev Receives the merkle root in the constructor, but it can be
    /// set again through setRoot
    ///
    /// @param root_ new root value
    constructor(bytes32 root_, IERC20Mintable silv_) {
        root = root_;
        silv = silv_;
    }

    /// @dev Updates merkle tree's root value
    /// Requirements:
    /// - Only owner can update it
    /// @param root_ new root value
    function setRoot(bytes32 root_) external onlyOwner {
        // emits an event
        emit LogSetRoot(root, root_);
        // sets new root value
        root = root_;
    }

    /// @dev Returns whether an user at index_ has already claimed sILV v2 or not
    /// @param index_ user index in the merkle tree
    function claimed(uint256 index_) public view returns (bool) {
        return _claimed.get(index_);
    }

    /// @dev Mints sILV v2 tokens to the caller if verified in the merkle tree
    /// Requirements:
    /// - Users in the tree can claim their sILV value only once
    /// @param proof_ merkle proof provided by the user
    /// @param index_ user index in the merkle tree
    /// @param value_ sILV value to mint
    function claim(
        bytes32[] calldata proof_,
        uint256 index_,
        uint256 value_
    ) external {
        // calculates the merkle tree leaf using msg.sender
        bytes32 leaf = keccak256(abi.encodePacked(index_, msg.sender, value_));
        // checks if user has already claimed
        require(!claimed(index_), "MerkleDistributor: tokens alrady claimed");
        // uses MerkleProof.verify internal function to check if the proof is valid
        require(proof_.verify(root, leaf), "MerkleDistributor: invalid proof");


        // sets index as claimed in the bitmap
        _claimed.set(index_);
        // mints silv to the caller
        silv.mint(msg.sender, value_);
        // emits an event
        emit LogClaim(index_, msg.sender, value_);
    }

    /// @dev Logs setRoot function
    /// @param previousRoot previous merkle root
    /// @param newRoot new merkle root
    event LogSetRoot(bytes32 previousRoot, bytes32 newRoot);

    /// @dev Logs a silv v2 token claim
    /// @param index claimer index in the merkle tree
    /// @param from address claiming new silv token
    /// @param value number of silv v2 tokens minted
    event LogClaim(uint256 indexed index, address indexed from, uint256 value);
}