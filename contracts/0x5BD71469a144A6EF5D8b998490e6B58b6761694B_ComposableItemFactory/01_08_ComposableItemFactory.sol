// SPDX-License-Identifier: GPL-3.0

/// @title The Composable Item Factory

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// ComposableItemFactory.sol is a modified version of Foundation's FNDCollectionFactory.sol:
// https://github.com/f8n/fnd-protocol/blob/9dcdd63ebad77bca79f12ee4c791f931cfa8a3c2/contracts/FNDCollectionFactory.sol

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { IComposableItemFactory } from './interfaces/IComposableItemFactory.sol';
import { IComposableItemInitializer } from './interfaces/IComposableItemInitializer.sol';

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create an NFT collection contract managed by a single owner.
 * @dev This creates and initializes an ERC-1165 minimal proxy pointing to the NFT collection contract template.
 */
contract ComposableItemFactory is IComposableItemFactory, Ownable {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Clones for address;
  using Strings for uint256;

  /**
   * @notice The address of the template all new collections will leverage.
   */
  address public implementation;

  /**
   * @notice The implementation version new collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public version;
  
  // An address who has permissions to mint Composable Items, passed down during initializer
  address public minter;

  /**
   * @notice Defines requirements for the collection factory at deployment time.
   * @param _implementation The new collection implementation address.
   */
  constructor(address _implementation, address _minter) {
    _updateImplementation(_implementation);
    minter = _minter;
  }

  /**
   * @notice Allows Owner to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new collection implementation address.
   */
  function setImplementation(address _implementation) external onlyOwner {
    _updateImplementation(_implementation);
  }
  
  function setMinter(address _minter) external onlyOwner {
  	minter = _minter;

    emit MinterUpdated(_minter);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   * @param name The name for the new collection being created.
   * @param symbol The symbol for the new collection being created.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return tokenAddress The address of the new collection contract.
   */
  function createCollection(
    string calldata name,
    string calldata symbol,
    uint256 nonce
  ) external returns (address tokenAddress) {
    require(bytes(name).length != 0, "ComposableItemFactory: name is required");
    require(bytes(symbol).length != 0, "ComposableItemFactory: symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    tokenAddress = implementation.cloneDeterministic(_getSalt(_msgSender(), nonce));

    IComposableItemInitializer(tokenAddress).initialize(name, symbol, _msgSender(), minter);

    emit CollectionCreated(tokenAddress, _msgSender(), version, name, symbol, nonce);
  }

  /**
   * @dev Updates the implementation address, increments the version
   */
  function _updateImplementation(address _implementation) private {
    require(_implementation.isContract(), "ComposableItemFactory: implementation is not a contract");
    implementation = _implementation;
    unchecked {
      // Version cannot overflow 256 bits.
      version++;
    }

    emit ImplementationUpdated(_implementation, version);
  }

  /**
   * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return collectionAddress The address of the collection contract that would be created by this nonce.
   */
  function predictCollectionAddress(address creator, uint256 nonce) external view returns (address collectionAddress) {
    collectionAddress = implementation.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(creator, nonce));
  }
}