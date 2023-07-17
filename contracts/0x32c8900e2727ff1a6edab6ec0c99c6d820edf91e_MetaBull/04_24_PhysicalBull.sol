//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Burger.sol";

error ExceedsMaxClaims();
error InvalidTokenAmount();
error CallerIsNotTokenOwner();
error CallerNotInCommunity();

/**
 * @title Physical Bulls
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract handles the payment and verification for pre-ordering physical bulls. Users
 * will pre-order physical bulls by exchanging erc20 tokens and burning burgers.
 */
contract PhysicalBull is Ownable {
  using Strings for uint256;
  using SafeERC20 for IERC20;
  /// contract instances ///
  IERC20 public erc20;
  Burger public immutable BurgerContract;
  Grill2 public immutable GrillContract;
  ISUPER1155 public constant Astro =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  /// if claiming is active ///
  bool public isClaiming = false;
  /// the current erc20 payment receiver ///
  address public vault;
  /// the number of physical bulls claimed ///
  uint256 public totalClaims;
  /// the max number of claims an account can make ///
  uint256 public maxClaims = 3;
  /// the number of burgers burned by this contract ///
  uint256 public totalBurns;
  /// the number of burgers to burn for 1 physical bull ///
  uint256 public burnScalar = 1;
  /// the amount of erc20 tokens to claim 1 physical bull ///
  uint256 public erc20Cost = 100000000; // 100.000000 $USDC
  /// the number of burgers each account has burned ///
  mapping(address => uint256) public accountBurns;
  /// the number of physcal bulls each account has claimed ///
  mapping(address => uint256) public accountClaims;

  /**
   * @param _vault The address to receive erc20 tokens
   * @param _erc20 The contract address of the erc20 contract to use for payments
   * @param _burger The address of the burger contract
   * @param _grill The address of the new grill contract
   */
  constructor(
    address _vault,
    address _erc20,
    address _burger,
    address _grill
  ) {
    vault = _vault;
    erc20 = IERC20(_erc20);
    BurgerContract = Burger(_burger);
    GrillContract = Grill2(_grill);
  }

  /// ============ OWNER ============ ///

  /**
   * Toggles if claiming is active
   */
  function toggleClaiming() public onlyOwner {
    isClaiming = !isClaiming;
  }

  /**
   * Sets the cost for each bull claim
   * @param _erc20Cost The number of erc20 tokens to transfer
   */
  function setERC20Cost(uint256 _erc20Cost) public onlyOwner {
    erc20Cost = _erc20Cost;
  }

  /**
   * Sets the erc20 contract address to use for payments
   * @param _erc20 The erc20 contract address
   */
  function setERC20Address(address _erc20) public onlyOwner {
    erc20 = IERC20(_erc20);
  }

  /**
   * Sets the number of burgers to burn for each bull claim
   * @param _burnScalar The number of burgers to burn
   */
  function setBurnScalar(uint256 _burnScalar) public onlyOwner {
    burnScalar = _burnScalar;
  }

  /**
   * Sets the limit for the max number of claims per account
   * @param _maxClaims The max number of claims per account
   */
  function setMaxClaims(uint256 _maxClaims) public onlyOwner {
    maxClaims = _maxClaims;
  }

  /**
   * Sets the address for receiving erc20 payments
   * @param _vault The address to receive payments
   */
  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  /// ============ INTERNAL ============ ///

  /**
   * Checks if `account` owns any astrobulls or has any active stakes
   * @param account The address to lookup
   * @return _b If `account` owns or is the staker of > 0 astrobulls
   * @notice Checks both old and new grill contracts for active stakes
   */
  function _checkCommunityStatus(address account)
    internal
    view
    returns (bool _b)
  {
    _b = false;
    /// @dev first check if caller owns > 0 astrobulls ///
    if (Astro.groupBalances(1, account) > 0) {
      _b = true;
    }
    /// @dev next, check if caller has any active stakes in the old grill ///
    else if (GrillContract.stakedIdsPerAccountOld(account).length > 0) {
      _b = true;
    }
    /// @dev lastly, check if caller has any active stakes in the new grill ///
    else if (GrillContract.stakedIdsPerAccount(account).length > 0) {
      _b = true;
    }
  }

  /// ============ PUBLIC ============ ///

  /**
   * Claims `quantity` number of physical bulls if caller owns > 0 astrobulls
   * @param quantity The number of bulls to claim
   * @notice Caller will send `erc20Cost` * `quantity` tokens to `vault`
   * @notice Caller must give this contract a sufficient allowance to send their erc20 tokens
   */
  function claimBulls(uint256 quantity) public {
    if (!isClaiming) {
      revert ClaimingNotActive();
    }
    if (!_checkCommunityStatus(msg.sender)) {
      revert CallerNotInCommunity();
    }
    if (accountClaims[msg.sender] + quantity > maxClaims) {
      revert ExceedsMaxClaims();
    }
    if (quantity == 0) {
      revert InvalidTokenAmount();
    }
    /// @dev sends erc20 tokens from caller to vault ///
    erc20.safeTransferFrom(msg.sender, vault, quantity * erc20Cost);
    /// @dev burns caller's burgers ///
    uint256 toBurn = burnScalar * quantity;
    BurgerContract.burnBurger(msg.sender, burnScalar * quantity);
    /// @dev sets contract state ///
    totalBurns += toBurn;
    accountBurns[msg.sender] += toBurn;
    totalClaims += quantity;
    accountClaims[msg.sender] += quantity;
  }
}