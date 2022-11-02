// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IWhitelistSalePublic.sol";

import "./MerkleDistributor.sol";

/// @title WhitelistSalePublic
/// @author Bluejay Core Team
/// @notice WhitelistSalePublic is a token sale contract that sells tokens at a fixed price to whitelisted
/// addresses. Purchased BLU tokens are sent immediately to the buyer.
contract WhitelistSalePublic is
  Ownable,
  MerkleDistributor,
  IWhitelistSalePublic
{
  using SafeERC20 for IERC20;

  uint256 internal constant WAD = 10**18;

  /// @notice The contract address of the treasury, for minting BLU
  ITreasury public immutable treasury;

  /// @notice The contract address the asset used to purchase the BLU token
  IERC20 public immutable reserve;

  /// @notice Maximum number of BLU tokens that can be purchased, in WAD
  uint256 public immutable maxPurchasable;

  /// @notice Total of quota that has been claimed, in WAD
  uint256 public totalQuota;

  /// @notice Total of tokens that have been sold, in WAD
  uint256 public totalPurchased;

  /// @notice Mapping of addresses to available quota for purchase, in WAD
  mapping(address => uint256) public quota;

  /// @notice Price of the token against the reserve asset, in WAD
  uint256 public price;

  /// @notice Flag to pause contract
  bool public paused;

  /// @notice Constructor to initialize the contract
  /// @param _reserve Address the asset used to purchase the BLU token
  /// @param _treasury Address of the treasury
  /// @param _price Price of the token against the reserve asset, in WAD
  /// @param _maxPurchasable Maximum number of BLU tokens that can be purchased, in WAD
  /// @param _merkleRoot Merkle root of the distribution
  constructor(
    address _reserve,
    address _treasury,
    uint256 _price,
    uint256 _maxPurchasable,
    bytes32 _merkleRoot
  ) {
    treasury = ITreasury(_treasury);
    reserve = IERC20(_reserve);
    price = _price;
    maxPurchasable = _maxPurchasable;
    _setMerkleRoot(_merkleRoot);
    paused = true;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Claims quota for the distribution to start purchasing tokens
  /// @dev The parameters of the function should come from the merkle distribution file
  /// @param index Index of the distribution
  /// @param account Account where the distribution is credited to
  /// @param amount Amount of allocated in the distribution, in WAD
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) public override {
    _claim(index, account, amount, merkleProof);
    quota[account] += amount;
    totalQuota += amount;
  }

  /// @notice Purchase tokens from the sale
  /// @dev The quota for purchase should be claimed prior to executing this function
  /// @param amount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function purchase(uint256 amount, address recipient) public override {
    require(!paused, "Purchase paused");
    uint256 tokensBought = (amount * WAD) / price;
    require(quota[msg.sender] >= tokensBought, "Insufficient quota");

    quota[msg.sender] -= tokensBought;
    totalPurchased += tokensBought;
    require(totalPurchased <= maxPurchasable, "Max purchasable reached");

    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(recipient, tokensBought);

    emit Purchase(msg.sender, recipient, amount, tokensBought);
  }

  /// @notice Utility function to execute both claim and purchase in a single transaction
  /// @param index Index of the distribution
  /// @param account Account where the distribution is credited to
  /// @param claimAmount Amount of allocated in the distribution, in WAD
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  /// @param purchaseAmount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function claimAndPurchase(
    uint256 index,
    address account,
    uint256 claimAmount,
    bytes32[] calldata merkleProof,
    uint256 purchaseAmount,
    address recipient
  ) public override {
    claimQuota(index, account, claimAmount, merkleProof);
    purchase(purchaseAmount, recipient);
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Pause and unpause the contract
  /// @param _paused True to pause, false to unpause
  function setPause(bool _paused) public onlyOwner {
    paused = _paused;
    emit Paused(_paused);
  }

  /// @notice Set the merkle root for the distribution
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  /// @param _merkleRoot New merkle root of the distribution
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    _setMerkleRoot(_merkleRoot);
    emit UpdatedMerkleRoot(_merkleRoot);
  }

  /// @notice Set the price of the BLU toke
  /// @dev The contract needs to be paused before setting the price
  /// @param _price New price of BLU, in WAD
  function setPrice(uint256 _price) public onlyOwner {
    require(paused, "Not Paused");
    price = _price;
    emit UpdatedPrice(_price);
  }
}