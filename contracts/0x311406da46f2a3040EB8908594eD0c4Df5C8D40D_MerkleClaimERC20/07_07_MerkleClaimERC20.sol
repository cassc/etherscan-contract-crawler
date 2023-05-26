pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

/// ============ Imports ============
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // OZ: ERC20
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol"; // OZ: Ownable

/// @title MerkleClaimERC20
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <[email protected]>, modified / extended by Aleksa Stojanović <[email protected]>
contract MerkleClaimERC20 is Ownable {

  /// ============ Immutable storage ============

  /// @notice ERC20 to claim
  address public immutable erc20ToClaim;
  /// @notice ERC20-claimee inclusion root
  bytes32 public immutable merkleRoot;
  /// @notice admin withdrawal timestamp ( in case there are unclaimed tokens )
  uint256 public adminWithdrawalTimestamp;
  /// ============ Mutable storage ============

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;

  /// ============ Errors ============

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();
  /// @notice Thrown if transfer fails
  error TransferFailed();
  /// @notice Thrown if there are no tokens to transfer
  error EverythingClaimed();
  /// @notice Thrown if admin tries to claim tokens before claiming period ends ( adminWithdrawalTimestamp )
  error ClaimingIsNotClosed();

  /// ============ Constructor ============

  /// @notice Creates a new MerkleClaimERC20 contract
  /// @param _erc20ToClaim address of token
  /// @param _merkleRoot of claimees
  constructor(
    address _erc20ToClaim,
    bytes32 _merkleRoot,
    uint256 _adminWithdrawalTimestamp
  ){
    merkleRoot = _merkleRoot; // Update root
    erc20ToClaim = _erc20ToClaim; // Update address of token that is being claimed
    adminWithdrawalTimestamp = _adminWithdrawalTimestamp; // Update claim timeframe
  }

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

  /// ============ Functions ============

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Set address to claimed
    hasClaimed[to] = true;
    
    // Send tokens
    (bool success, bytes memory data) = erc20ToClaim.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');

    // Emit claim event
    emit Claim(to, amount);
  }
  /// @notice Allows claiming unclaimed tokens from this contract after `adminWithdrawalTimestamp` has passed
  /// @param to address of admin
  function claimRemaining(address to) external onlyOwner{
    uint256 amount = ERC20(erc20ToClaim).balanceOf(address(this));
    if(amount == 0) revert EverythingClaimed();
    if(block.timestamp < adminWithdrawalTimestamp) revert ClaimingIsNotClosed();
    (bool success, bytes memory data) = erc20ToClaim.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
  }
}