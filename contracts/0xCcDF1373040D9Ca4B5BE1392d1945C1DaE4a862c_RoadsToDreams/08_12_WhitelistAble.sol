// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title The contract to provide whitelist wave functionality
abstract contract WhitelistAble {
  /// @dev A map to count how many NFTs have been minted by a wallet address during waves
  mapping(address => uint16) private _whitelistClaimed;
  /// @dev The root of the merkle tree for validation of participation in a wave
  bytes32 private _whitelistMerkleRoot;
  /// @dev Start timestamp, second since unix epoch
  uint256 private _whitelistStart;
  /// @dev End timestamp, second since unix epoch
  uint256 private _whitelistEnd;
  /// @dev The maximum number of NFTs a wallet address is allowed to mint during waves
  uint16 private _maxWhitelistNftMintsPerWallet;

  /// @notice Set whitelist wave data
  function _setWhitelistData(bytes32 whitelistMerkleRoot, uint256 whitelistStart, uint256 whitelistEnd, uint16 maxWhitelistNftMintsPerWallet) internal {
    _whitelistMerkleRoot = whitelistMerkleRoot;
    _whitelistStart = whitelistStart;
    _whitelistEnd = whitelistEnd;
    _maxWhitelistNftMintsPerWallet = maxWhitelistNftMintsPerWallet;
  }

  function getWhitelistMerkleRoot() public view returns (bytes32) {
    return _whitelistMerkleRoot;
  }

  function getWhitelistStart() public view returns (uint256) {
    return _whitelistStart;
  }

  function getWhitelistEnd() public view returns (uint256) {
    return _whitelistEnd;
  }

  function getWhitelistMaxMint() public view returns (uint16) {
    return _maxWhitelistNftMintsPerWallet;
  }

  /// @notice Function to check if minter is allowed to mint amount of NFTs and count minted NFTs of minter
  /// @dev The map _whitelistClaimed is not reset when starting a new wave
  function _checkAndFlagWhitelist(address minter, bytes32[] calldata merkleProof, uint16 amount) internal {
    // checks if whitelist is open, if minter can claim the requested amount and if minter is on whitelist
    require(block.timestamp >= _whitelistStart, "W2");
    require(block.timestamp <= _whitelistEnd, "W3");
    require(_whitelistClaimed[minter] + amount <= _maxWhitelistNftMintsPerWallet, "W0");
    bytes32 leaf = keccak256(abi.encodePacked(minter));
    require(MerkleProof.verify(merkleProof, _whitelistMerkleRoot, leaf), "W1");
    _whitelistClaimed[minter] += amount;
  }
}