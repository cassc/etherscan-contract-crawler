// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

error InactiveClaimableState();
error InvalidMerkleRoot();
error ZeroAddressClaimToken();
error AlreadyActiveClaimableState();
error InvalidProof();
error AddressBlocked();

contract ClaimToken is
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using MerkleProof for bytes32[];
  bytes32 public merkleRoot;
  address public token;

  mapping(address => uint256) public tokenClaimed;
  mapping(address => bool) public blockedAddress;

  event MerkleRootUpdated(bytes32 merkleRoot);
  event Initialized(address token, bytes32 merkleRoot);

  event TokenClaimed(address beneficiary, uint256 amount);

  event AddressUpdated(address oldAddress, address newAddress);

  enum State {
    ACTIVE,
    INACTIVE
  }

  State public state;

  function closePoolDistribution() external onlyOwner {
    if (state != State.ACTIVE) revert InactiveClaimableState();
    state = State.INACTIVE;
  }

  function activatePoolDistribution() external onlyOwner {
    if (state != State.INACTIVE) revert AlreadyActiveClaimableState();
    state = State.ACTIVE;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit MerkleRootUpdated(_merkleRoot);
  }

  function initialize(address _token, bytes32 _merkleRoot)
    external
    initializer
  {
    if (_token == address(0)) revert ZeroAddressClaimToken();
    if (_merkleRoot == bytes32("")) revert InvalidMerkleRoot();

    __Ownable_init();
    state = State.ACTIVE;
    token = _token;
    merkleRoot = _merkleRoot;
    emit Initialized(_token, _merkleRoot);
  }

  function updateAddress(address formerAddress, address newAddress)
    external
    onlyOwner
  {
    uint256 addressBalance = tokenClaimed[formerAddress];
    tokenClaimed[newAddress] = addressBalance;
    delete tokenClaimed[formerAddress];
    blockedAddress[formerAddress] = true;
    emit AddressUpdated(formerAddress, newAddress);
  }

  function claim(bytes32[] memory proof, uint256 _amount)
    external
    nonReentrant
  {
    if (blockedAddress[msg.sender]) revert AddressBlocked();
    if (state != State.ACTIVE) revert InactiveClaimableState();
    require(merkleRoot != 0, "Claiming not available yet");
    bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _amount));
    if (!MerkleProofUpgradeable.verify(proof, merkleRoot, _leaf))
      revert InvalidProof();

    uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));

    if (tokenClaimed[msg.sender] > 0) {
      uint256 claimableAmount = _amount - tokenClaimed[msg.sender];
      tokenClaimed[msg.sender] = _amount;

      require(balance >= claimableAmount, "Not enough balance on contract");
      _transferAsset(msg.sender, claimableAmount);
    } else {
      require(balance >= _amount, "Not enough balance on contract");

      _transferAsset(msg.sender, _amount);
      tokenClaimed[msg.sender] = _amount;
    }
    emit TokenClaimed(msg.sender, _amount);
  }

  function _transferAsset(address to, uint256 amount) internal {
    require(amount > 0, "Zero amount transfer");
    IERC20Upgradeable(token).safeTransfer(to, amount);
  }
}