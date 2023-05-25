// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '../utils/IDelegationRegistry.sol';
import '../interface/ICoolERC721A.sol';
import '../interface/IFractures.sol';

/// @title Into The Fracture
/// @author Adam Goodman
/// @notice This contract allows the burning of Cool Cats Fractures for Shadow Wolves
contract IntoTheFracture is Ownable, Pausable {
  IFractures public _fractures;
  ICoolERC721A public _shadowWolves;
  IDelegationRegistry public _delegationRegistry;

  bytes32 public _merkleRoot;
  bool public _allowlistEnabled;

  uint256 public _burnWindowStart;
  uint256 public _burnWindowEnd;

  uint256 public _maxBurnAmount = 100;

  // Mapping to only allow a merkle proof array to be used once.
  // Merkle proofs are not guaranteed to be unique to a specific Merkle root. So store them by root.
  mapping(bytes32 => mapping(bytes32 => bool)) public _usedMerkleProofs;

  error AllowlistEnabled();
  error MaxBurnExceeded();
  error BurnWindowNotStarted();
  error BurnWindowEnded();
  error InvalidBurnWindow();
  error InvalidMerkleProof();
  error MaxBurnAmountZero();
  error NullMerkleRoot();
  error NotFractureOwnerNorApproved(address account, uint256 fractureId);

  event AllowlistEnabledSet(bool allowlistEnabled);
  event BurnWindowSet(uint256 burnWindowStart, uint256 burnWindowEnd);
  event DelegateRegistryAddressSet(address delegationRegistry);
  event FractureAddressSet(address fractures);
  event FractureEntered(uint256[] fractureIds, uint256 firstId);
  event MaxBurnAmountSet(uint256 maxBurnAmount);
  event MerkleRootSet(bytes32 merkleRoot);
  event ShadowWolvesAddressSet(address shadowWolves);

  /// @dev Set merkleRoot to the null bytes32 to disable the allowlist
  ///      Any other value will enable the allowlist by default
  constructor(
    address fractures,
    address shadowWolves,
    address delegationRegistry,
    uint64 burnWindowStart,
    uint64 burnWindowEnd,
    bytes32 merkleRoot
  ) {
    _fractures = IFractures(fractures);
    _shadowWolves = ICoolERC721A(shadowWolves);
    _delegationRegistry = IDelegationRegistry(delegationRegistry);

    setBurnWindow(burnWindowStart, burnWindowEnd);

    if (merkleRoot != bytes32(0)) {
      _merkleRoot = merkleRoot;
      _allowlistEnabled = true;
    }

    _pause();
  }

  /// @notice Modifier to check if the burn window is open, otherwise revert
  modifier withinBurnWindow() {
    if (block.timestamp < _burnWindowStart) {
      revert BurnWindowNotStarted();
    }

    if (block.timestamp > _burnWindowEnd) {
      revert BurnWindowEnded();
    }
    _;
  }

  /// @notice Verify merkleProof submitted by a sender
  /// @param sender The account being verified
  /// @param merkleProof Merkle data to verify against
  modifier hasValidMerkleProof(address sender, bytes32[] calldata merkleProof) {
    if (_allowlistEnabled) {
      if (!isValidMerkleProof(sender, merkleProof)) {
        revert InvalidMerkleProof();
      }

      // bytes32 unique identifier for each merkle proof
      bytes32 node = keccak256(abi.encodePacked(sender));
      if (_usedMerkleProofs[_merkleRoot][node]) {
        revert InvalidMerkleProof();
      }
      _usedMerkleProofs[_merkleRoot][node] = true;
    }
    _;
  }

  /// @notice Burns given Fractures and mints Shadow Wolves
  /// @param fractureIds The Fractures to burn
  /// @param merkleProof The merkle proof for the given address
  /// @dev If the allowlist is enabled, the merkle proof must be valid, otherwise it will revert
  ///      if the allowlist is disabled, the merkle proof will be ignored, so it can be an empty array.
  ///      To avoid reentrancy attacks, the fractures are burned before the Shadow Wolves are minted.
  function enterFracture(
    uint256[] calldata fractureIds,
    bytes32[] calldata merkleProof
  ) external whenNotPaused withinBurnWindow hasValidMerkleProof(msg.sender, merkleProof) {
    uint256 len = fractureIds.length;
    // Prevent gas out for large burns
    if (len > _maxBurnAmount) revert MaxBurnExceeded();

    uint256 nextTokenId = _shadowWolves.nextTokenId();

    address owner;
    uint256 i;
    unchecked {
      do {
        // Check that the fracture owner is the sender or the sender is approved, otherwise revert. If a user approves
        // another account to manage their fractures, the owner of the fracture will receive the Shadow Wolf.
        // - the `_getOwnerIfApproved` function either returns an address or reverts
        owner = _getOwnerIfApproved(fractureIds[i]);
        _fractures.burn(fractureIds[i]);

        _shadowWolves.mint(owner, 1);
      } while (++i < len);
    }

    emit FractureEntered(fractureIds, nextTokenId);
  }

  /// @notice Sets the merkle root for the allowlist
  /// @dev Only the owner can call this function, setting the merkle root does not change
  ///      whether the allowlist is enabled or not
  /// @param merkleRoot The new merkle root
  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    if (_allowlistEnabled && merkleRoot == bytes32(0)) {
      revert AllowlistEnabled();
    }

    _merkleRoot = merkleRoot;

    emit MerkleRootSet(merkleRoot);
  }

  /// @notice Sets whether the allowlist is enabled or not
  /// @dev Only the owner can call this function
  /// @param allowlistEnabled Whether the allowlist is enabled or not
  function setAllowlistEnabled(bool allowlistEnabled) external onlyOwner {
    if (allowlistEnabled && _merkleRoot == bytes32(0)) {
      revert NullMerkleRoot();
    }

    _allowlistEnabled = allowlistEnabled;

    emit AllowlistEnabledSet(allowlistEnabled);
  }

  /// @notice Sets the maximum number of tokens that can be burned in a single transaction
  /// @dev Only the owner can call this function
  /// @param maxBurnAmount The maximum number of tokens that can be burned in a single transaction
  function setMaxBurnAmount(uint256 maxBurnAmount) external onlyOwner {
    // Can't set max burn amount to zero, we have pause to stop minting
    if (maxBurnAmount == 0) revert MaxBurnAmountZero();

    _maxBurnAmount = maxBurnAmount;

    emit MaxBurnAmountSet(maxBurnAmount);
  }

  /// @notice Pauses the contract - stopping minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZepplin Pausable}
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract - allowing minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZepplin Pausable}
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Sets the address of the Fractures contract
  /// @dev Only the owner can call this function
  /// @param fractures The address of the Fractures contract
  function setFracturesAddress(address fractures) external onlyOwner {
    _fractures = IFractures(fractures);

    emit FractureAddressSet(fractures);
  }

  /// @notice Sets the address of the Shadow Wolves contract
  /// @dev Only the owner can call this function
  /// @param shadowWolves The address of the Shadow Wolves contract
  function setShadowWolvesAddress(address shadowWolves) external onlyOwner {
    _shadowWolves = ICoolERC721A(shadowWolves);

    emit ShadowWolvesAddressSet(shadowWolves);
  }

  /// @notice Sets the address of the Delegation Registry contract
  /// @dev Only the owner can call this function
  /// @param delegateRegistry The address of the Delegation Registry contract
  function setDelegateRegistryAddress(address delegateRegistry) external onlyOwner {
    _delegationRegistry = IDelegationRegistry(delegateRegistry);

    emit DelegateRegistryAddressSet(delegateRegistry);
  }

  /// @notice Sets the burn window, start and end times are in seconds since unix epoch
  /// @dev Only the owner can call this function
  /// @param burnWindowStart The start time of the burn window
  /// @param burnWindowEnd The end time of the burn window
  function setBurnWindow(uint256 burnWindowStart, uint256 burnWindowEnd) public onlyOwner {
    if (burnWindowEnd < burnWindowStart) {
      revert InvalidBurnWindow();
    }

    _burnWindowStart = burnWindowStart;
    _burnWindowEnd = burnWindowEnd;

    emit BurnWindowSet(burnWindowStart, burnWindowEnd);
  }

  /// @notice Checks if a given address is on the merkle tree allowlist
  /// @dev Merkle trees can be generated using https://github.com/OpenZeppelin/merkle-tree
  /// @param account The address to check
  /// @param merkleProof The merkle proof to check
  /// @return Whether the address is on the allowlist or not
  function isValidMerkleProof(
    address account,
    bytes32[] calldata merkleProof
  ) public view virtual returns (bool) {
    return
      MerkleProof.verifyCalldata(
        merkleProof,
        _merkleRoot,
        keccak256(bytes.concat(keccak256(abi.encode(account))))
      );
  }

  /// @notice Checks if a given Fracture is owned by or approved for the sender
  /// @dev This can be used to stop users from being able to burn Fractures someone else owns without their permission
  /// @param tokenId The Fracture to check
  /// @return The owner of the token
  function _getOwnerIfApproved(uint256 tokenId) internal view returns (address) {
    address owner = _fractures.ownerOf(tokenId);

    if (owner == msg.sender) {
      return owner;
    }

    if (
      _delegationRegistry.checkDelegateForToken(msg.sender, owner, address(_fractures), tokenId)
    ) {
      return owner;
    }

    if (_fractures.isApprovedForAll(owner, msg.sender)) {
      return owner;
    }

    if (_fractures.getApproved(tokenId) == msg.sender) {
      return owner;
    }

    revert NotFractureOwnerNorApproved(msg.sender, tokenId);
  }
}