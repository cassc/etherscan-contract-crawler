// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

// Upgradeable contracts are required to use clone() in SaleFactory
abstract contract Sale is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  event Buy(address indexed buyer, address indexed token, uint256 baseCurrencyValue, uint256 tokenValue, uint256 tokenFee);

  /**
  Important: the constructor is only called once on the implementation contract (which is never initialized)
  Clones using this implementation cannot use this constructor method.
  Thus every clone must use the same fields stored in the constructor (feeBips, feeRecipient)
  */

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  // is this user permitted to access a sale?
  function isValidMerkleProof(
      bytes32 root,
      address account,
      bytes calldata data,
      bytes32[] calldata proof
  ) public pure returns (bool) {
    // check if the account is in the merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(account, data));
    if (MerkleProofUpgradeable.verify(proof, root, leaf)) {
      return true;
    }
    return false;
  }

  function buyWithToken(
    IERC20Upgradeable token,
    uint256 quantity,
    bytes calldata data,
    bytes32[] calldata proof
  ) external virtual {}

  function buyWithNative(
    bytes calldata data,
    bytes32[] calldata proof
  ) external virtual payable {}


  function isOpen() public virtual view returns(bool) {}

  function isOver() public virtual view returns(bool) {}

  function buyerTotal(address user) external virtual view returns(uint256) {}

  function total() external virtual view returns(uint256) {}
}