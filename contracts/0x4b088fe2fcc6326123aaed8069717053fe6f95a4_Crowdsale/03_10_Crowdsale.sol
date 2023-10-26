// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// OZ
import { ERC20 } from "./ERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

import { IWETH9 } from "./IWETH9.sol";

contract Crowdsale is ReentrancyGuard {
  using SafeERC20 for ERC20;

  // errors
  error Crowdsale_Initialized();
  error Crowdsale_Invalid_Currency();
  error Crowdsale_Invalid_Rate();
  error Crowdsale_Invalid_Token();
  error Crowdsale_Invalid_Beneficiary();
  error Crowdsale_Duplicate_Beneficiary();
  error Crowdsale_Invalid_ShareAmount();
  error Crowdsale_Invalid_SaleShares();
  error Crowdsale_Not_Paused();
  error Crowdsale_Not_Admin();
  error Crowdsale_Not_Governor();
  error Crowdsale_Paused();
  error Crowdsale_Buy_Insufficient_Balance();
  error Crowdsale_Buy_Insufficient_Token();
  error Crowdsale_Lock_Invalid_Index();
  error Crowdsale_Lock_Insufficient_Token();
  error Crowdsale_Unlock_Invalid_Index();

  // constants

  // state variables
  address public wNative;
  address public currency;
  address public token;
  uint256 public totalMintAmount;
  uint256 public totalLockAmount;
  uint256 public rate;
  uint256 public totalShare;
  uint256 public beneficiaryCount;
  bool public isPaused;
  bool public isInitialized;

  mapping(address => bool) public isAdmin;
  mapping(address => bool) public isGovernor;
  mapping(uint256 => uint256) public lockAmounts; //map index of each lock requests to their lock amount
  mapping(uint256 => address) public beneficiaries; //map index of beneficiaries to their address
  mapping(address => uint256) public shareAmounts; //map address of beneficiaries to their share amounts

  // events
  event SetAdmin(address admin, bool prevAllow, bool newAllow);
  event SetGovernor(address governor, bool prevAllow, bool newAllow);
  event SetBeneficiary(address beneficiary, uint256 shareAmount);
  event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 receiving);
  event DistributeIncome(address beneficiary, address currency, uint256 amount);
  event LogwithdrawRevenue(address withdrawer, address token, uint256 amount);
  event TokensLocked(address admin, uint256 index, uint256 lockAmount);
  event TokensUnlocked(address admin, uint256 index, uint256 unlockAmount);
  /**
   * @dev Emitted when the pause is triggered by `admin`.
   */
  event Paused(address admin);
  /**
   * @dev Emitted when the pause is lifted by `admin`.
   */
  event Unpaused(address admin);
  event EmergencyWithdraw(address token, address receiver, uint256 balance);

  // modifiers
  modifier whenNotInitialized() {
    if (isInitialized) revert Crowdsale_Initialized();
    _;
  }

  modifier onlyAdmin() {
    if (!isAdmin[msg.sender]) revert Crowdsale_Not_Admin();
    _;
  }

  modifier onlyGovernor() {
    if (!isGovernor[msg.sender]) revert Crowdsale_Not_Governor();
    _;
  }

  modifier onlyERC20Sale() {
    if (currency == address(0)) revert Crowdsale_Invalid_Currency();
    _;
  }

  modifier onlyNativeSale() {
    if (currency != address(0)) revert Crowdsale_Invalid_Currency();
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    if (isPaused) {
      revert Crowdsale_Paused();
    }
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    if (!isPaused) {
      revert Crowdsale_Not_Paused();
    }
    _;
  }

  // structs
  struct SaleShare {
    address beneficiary;
    uint256 shareAmount;
  }

  // functions
  /**
   * This function is used to initialize the contract
   * by setting various parameters such as the rate, currency and token.
   * It performs necessary checks on the provided values, updates the state variables accordingly,
   * and designates the default admin.
   *
   * @param _wNative The address of the wrapped native token
   * @param _rate The price in currency for a single token
   * @param _currency Address of the currency (token) accepted for the sale
   * @param _token Address of the token contract
   * @param _totalMintAmount The total tokens for the sale
   * @param _beneficiaries Addresses that will receive share from token sale income
   * @param _shareAmounts The amount of share of each benficiaries
   * @param _admin The address of the admin
   */
  function initialize(
    address _wNative,
    uint256 _rate,
    address _currency,
    address _token,
    uint256 _totalMintAmount,
    address[] calldata _beneficiaries,
    uint256[] calldata _shareAmounts,
    address _admin
  ) external whenNotInitialized {
    if (_rate == 0) {
      revert Crowdsale_Invalid_Rate();
    }
    if (_token == address(0)) {
      revert Crowdsale_Invalid_Token();
    }
    if (_beneficiaries.length != _shareAmounts.length) {
      revert Crowdsale_Invalid_SaleShares();
    }
    SaleShare[] memory _saleShares = new SaleShare[](_beneficiaries.length);
    for (uint256 i = 0; i < _beneficiaries.length;) {
      _saleShares[i] = SaleShare(_beneficiaries[i], _shareAmounts[i]);
      unchecked {
        ++i;
      }
    }
    _setBeneficiaryShares(_saleShares);

    wNative = _wNative;
    rate = _rate;
    currency = _currency;
    token = _token;
    totalMintAmount = _totalMintAmount;
    isInitialized = true;
    isPaused = true;
    isAdmin[_admin] = true;
    isAdmin[msg.sender] = true;
    isGovernor[msg.sender] = true;
  }

  /**
   * This function return the amount of token being on sell
   */
  function remainingAmount() public view returns (uint256) {
    return ERC20(token).balanceOf(address(this)) - totalLockAmount;
  }

  function _buy(uint256 paying, uint256 receiving, address beneficiary) internal {
    if (remainingAmount() < receiving) {
      revert Crowdsale_Buy_Insufficient_Token();
    }
    if (beneficiary == address(0) || beneficiary == address(this)) {
      revert Crowdsale_Invalid_Beneficiary();
    }

    ERC20(token).safeTransfer(beneficiary, receiving);
    emit TokensPurchased(msg.sender, beneficiary, paying, receiving);
  }

  function _distribute(uint256 _paying, address _token) internal {
    uint256 _remainingRevenue = _paying;
    for (uint256 i = 1; i < beneficiaryCount;) {
      address _beneficiary = beneficiaries[i];
      uint256 _sharedRevenue = _paying * shareAmounts[_beneficiary] / totalShare;
      _remainingRevenue -= _sharedRevenue;
      ERC20(_token).safeTransfer(_beneficiary, _sharedRevenue);

      emit DistributeIncome(_beneficiary, currency, _sharedRevenue);
      unchecked {
        ++i;
      }
    }
    {
      address _beneficiary = beneficiaries[0];
      ERC20(_token).safeTransfer(_beneficiary, _remainingRevenue);
      emit DistributeIncome(_beneficiary, currency, _remainingRevenue);
    }
  }

  /**
   * This function that allows a user to buy tokens for the beneficiary address.
   *
   * @param paying The amount of payment
   * @param beneficiary which represents the address of the account that will receive the purchased tokens
   */
  function buy(uint256 paying, address beneficiary) external nonReentrant whenNotPaused onlyERC20Sale {
    uint256 receiving = paying * 1e18 / rate;

    if (ERC20(currency).balanceOf(msg.sender) < paying) {
      revert Crowdsale_Buy_Insufficient_Balance();
    }
    ERC20(currency).safeTransferFrom(msg.sender, address(this), paying);

    _distribute(paying, currency);
    _buy(paying, receiving, beneficiary);
  }

  /**
   * This function allows a user to buy native tokens for the beneficiary addres
   *
   * @param beneficiary which represents the address of the account that will receive the purchased tokens
   */
  function buyNative(address beneficiary) external payable nonReentrant whenNotPaused onlyNativeSale {
    uint256 receiving = msg.value * 1e18 / rate;
    IWETH9(wNative).deposit{ value: msg.value }();

    _distribute(msg.value, wNative);
    _buy(msg.value, receiving, beneficiary);
  }

  /**
   * This function allows the designated admin to modify the status (allow/disallow) of a admin by specifying the admin's address and the desired status.
   *
   * @param admin Address of the admin to be modified
   * @param allow A boolean value indicating whether to allow or disallow the admin
   */
  function setAdmin(address admin, bool allow) external onlyAdmin {
    emit SetAdmin(admin, isAdmin[admin], allow);
    isAdmin[admin] = allow;
  }

  /**
   * This function allows the designated governor to modify the status (allow/disallow) of a governor by specifying the governor's address and the desired status.
   *
   * @param governor Address of the governor to be modified
   * @param allow A boolean value indicating whether to allow or disallow the governor
   */
  function setGovernor(address governor, bool allow) external onlyGovernor {
    emit SetGovernor(governor, isGovernor[governor], allow);
    isGovernor[governor] = allow;
  }

  function _resetBeneficiaryShares() internal {
    if (beneficiaryCount == 0) {
      return;
    }
    for (uint256 i = 0; i < beneficiaryCount;) {
      address _beneficiary = beneficiaries[i];
      shareAmounts[_beneficiary] = 0;
      beneficiaries[i] = address(0);
      emit SetBeneficiary(_beneficiary, 0);
      unchecked {
        ++i;
      }
    }

    totalShare = 0;
    beneficiaryCount = 0;
  }

  function _setBeneficiaryShares(SaleShare[] memory _saleShares) internal {
    uint256 _totalShare = 0;
    uint256 _beneficiaryCount = _saleShares.length;
    for (uint256 i = 0; i < _beneficiaryCount;) {
      address _beneficiary = _saleShares[i].beneficiary;
      if (_beneficiary == address(0)) {
        revert Crowdsale_Invalid_Beneficiary();
      }
      if (shareAmounts[_beneficiary] != 0) {
        revert Crowdsale_Duplicate_Beneficiary();
      }

      uint256 _shareAmount = _saleShares[i].shareAmount;
      if (_shareAmount == 0) {
        revert Crowdsale_Invalid_ShareAmount();
      }

      beneficiaries[i] = _beneficiary;
      shareAmounts[_beneficiary] = _shareAmount;
      _totalShare += _shareAmount;

      emit SetBeneficiary(_beneficiary, _shareAmount);
      unchecked {
        ++i;
      }
    }

    totalShare = _totalShare;
    beneficiaryCount = _beneficiaryCount;
  }

  function setBeneficiaryShares(SaleShare[] calldata _saleShares) external onlyGovernor {
    if (_saleShares.length == 0) {
      revert Crowdsale_Invalid_SaleShares();
    }
    _resetBeneficiaryShares();
    _setBeneficiaryShares(_saleShares);
  }

  /**
   * This function allows the designated admin to pause the contract,
   * indicating that certain functionality
   * or operations within the contract are temporarily halted
   */
  function pause() external onlyAdmin whenNotPaused {
    isPaused = true;
    emit Paused(msg.sender);
  }

  /**
   * This function allows the designated admin to unpause the contract,
   * indicating that the contract is no longer in a paused state.
   */
  function unpause() external onlyAdmin whenPaused {
    isPaused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * This function that allows the contract admin to withdraw all of the ERC20 tokens
   * from the contract to a specified address
   *
   * @param _token The address of the ERC20 token contract
   * @param receiver The address of the recipient of the ERC20 tokens
   */
  function emergencyWithdraw(address _token, address receiver) external onlyAdmin {
    ERC20 tokenContract = ERC20(_token);
    uint256 balance = tokenContract.balanceOf(address(this));
    tokenContract.safeTransfer(receiver, balance);

    emit EmergencyWithdraw(_token, receiver, balance);
  }

  /**
   * This function allows the contract admin to temporarily lock tokens from being sold.
   *
   * @param index The index of the lock order
   * @param lockAmount The amount of token to be locked
   */
  function lock(uint256 index, uint256 lockAmount) external onlyAdmin {
    if (lockAmounts[index] != 0) {
      revert Crowdsale_Lock_Invalid_Index();
    }

    if (remainingAmount() < lockAmount) {
      revert Crowdsale_Lock_Insufficient_Token();
    }

    lockAmounts[index] = lockAmount;
    totalLockAmount += lockAmount;
    emit TokensLocked(msg.sender, index, lockAmount);
  }

  /**
   * This function allows the contract admin to unlock tokens from the lock order.
   *
   * @param index The index of the lock order
   */
  function unlock(uint256 index) external onlyAdmin {
    if (lockAmounts[index] == 0) {
      revert Crowdsale_Unlock_Invalid_Index();
    }

    uint256 unlockAmount = lockAmounts[index];
    lockAmounts[index] = 0;
    totalLockAmount -= unlockAmount;
    emit TokensUnlocked(msg.sender, index, unlockAmount);
  }
}
