// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title $CROAK
/// @author @ryeshrimp

contract CROAK is ERC20, Ownable {

  /// @notice a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;
  bytes32 public merkleRoot;
  bool claimPaused;
  
  constructor(bytes32 _merkleRoot) ERC20("Croakens", "CROAK") {
    controllers[msg.sender] = true;
    merkleRoot = _merkleRoot;
  }

  /// @notice mints $CROAK to a recipient
  /// @param to the recipient of the $CROAK
  /// @param amount the amount of $CROAK to mint
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /// @notice burns $CROAK from a holder
  /// @param from the holder of the $CROAK
  /// @param amount the amount of $CROAK to burn
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    require(claimPaused == false, "Claim is paused");

    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert("Already claimed");

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert("Claim not found");

    // Set address to claimed
    hasClaimed[to] = true;

    // Mint tokens to address
    _mint(to, amount);

    // Emit claim event
    emit Claim(to, amount);
  }


  /// @notice Adds an address from controller
  /// @dev This is used for contracts to burn/mint
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /// @notice Removes an address from controller
  /// @dev This is used for contracts to burn/mint
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /// @notice Sets the merkel root for token claim
  function setRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /// @notice Sets the ability to pause the initial snapshot cliam of token
  /// @param _value true or false
  function setClaimPause(bool _value) public onlyOwner {
    claimPaused = _value;
  }


  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

}