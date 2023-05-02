// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interface/ISLSDToken.sol";

// import "hardhat/console.sol";

/*
 * eSLSD is SLSD Finance's escrowed governance token obtainable by converting SLSD to it
 * It's non-transferable, except from/to whitelisted addresses
 * It can be converted back to SLSD through a vesting process
 */
contract eSLSDToken is Ownable, ReentrancyGuard, ERC20("eSLSD Token", "eSLSD") {
  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for ISLSDToken;

  ISLSDToken public immutable slsdToken; // SLSD token to escrow to/from
  EnumerableSet.AddressSet private _whitelistAddresses; // addresses allowed to send/receive eSLSD

  uint256 public minRedeemDurationInDays = 1;
  uint256 public maxRedeemDurationInDays = 20;
  uint256 public redeemRatioDenominator = 100;
  uint256[] public redeemRatios = [10, 30, 43, 52, 58, 64, 68, 72, 76, 79, 82, 85, 87, 89, 91, 93, 95, 97, 99, 100];
  mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances
  uint256 private _redeemFees;

  struct RedeemInfo {
    uint256 eslsdAmount; // eSLSD amount to redeem
    uint256 slsdAmount; // SLSD amount to receive when vesting has ended
    uint256 endTime;
  }

  constructor(ISLSDToken _slsdToken) {
    slsdToken = _slsdToken;
    _whitelistAddresses.add(address(this));
  }

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  /*
   * @dev returns redeemable SLSD for "amount" of eSLSD vested for "duration" seconds
   */
  function getSLSDAmountByVestingDuration(uint256 amount, uint256 durationInDays) public view returns (uint256) {
    require(durationInDays >= minRedeemDurationInDays, "getSLSDAmountByVestingDuration: durationInDays too short");

    uint256 durationInDaysCapped = durationInDays;
    if(durationInDaysCapped > maxRedeemDurationInDays) durationInDaysCapped = maxRedeemDurationInDays;

    uint256 ratio = redeemRatios[durationInDaysCapped.sub(1)];
    uint256 slsdAmount = amount.mul(ratio).div(redeemRatioDenominator);
    return slsdAmount < amount ? slsdAmount : amount;
  }

  /**
   * @dev returns quantity of "userAddress" pending redeems
   */
  function getUserRedeemsLength(address userAddress) external view returns (uint256) {
    return userRedeems[userAddress].length;
  }

  function getUserRedeem(address userAddress, uint256 redeemIndex) external view validateRedeem(userAddress, redeemIndex) returns (uint256 slsdAmount, uint256 eslsdAmount, uint256 endTime) {
    RedeemInfo storage _redeem = userRedeems[userAddress][redeemIndex];
    return (_redeem.slsdAmount, _redeem.eslsdAmount, _redeem.endTime);
  }

  function getWhitelistAddressesLength() external view returns (uint256) {
    return _whitelistAddresses.length();
  }

  function getWhitelistAddress(uint256 index) external view returns (address) {
    require(index < _whitelistAddresses.length(), "getWhitelistAddress: invalid index");
    return _whitelistAddresses.at(index);
  }

  function isAddressWhitelisted(address account) external view returns (bool) {
    return _whitelistAddresses.contains(account);
  }

  function redeemFees() external view returns (uint256) {
    return _redeemFees;
  }

  /*******************************************************/
  /****************** OWNABLE FUNCTIONS ******************/
  /*******************************************************/


  /**
   * @dev Adds or removes addresses from the whitelist
   */
  function setWhitelistAddress(address account, bool whitelisted) external nonReentrant onlyOwner {
    require(account != address(0), "Zero address detected");
    require(account != address(this), "setWhitelistAddress: Cannot remove eSLSD from whitelist");

    if(whitelisted) _whitelistAddresses.add(account);
    else _whitelistAddresses.remove(account);

    emit UpdateWhitelistAddress(account, whitelisted);
  }

  function withdrawRedeemFees(address to) external nonReentrant onlyOwner {
    require(to != address(0), "Zero address detected");
    require(_redeemFees > 0, 'No redeem fees to withdraw');

    _transfer(address(this), to, _redeemFees);
    emit RedeemFeesWithdrawn(to, _redeemFees);

    _redeemFees = 0;
  }

  /*****************************************************************/
  /******************  EXTERNAL PUBLIC FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Escrow caller's "amount" of SLSD to eSLSD
   */
  function escrow(uint256 amount) external nonReentrant {
    _escrow(amount, _msgSender());
  }

  /**
   * @dev Initiates redeem process (eSLSD to SLSD)
   */
  function redeem(uint256 eslsdAmount, uint256 vestingDurationInDays) external nonReentrant {
    require(eslsdAmount > 0, "eslsdAmount too small");
    require(eslsdAmount <= balanceOf(_msgSender()), "Redeem amount exceeds balance");

    _transfer(_msgSender(), address(this), eslsdAmount);

    uint256 slsdAmount = getSLSDAmountByVestingDuration(eslsdAmount, vestingDurationInDays);
    emit Redeem(_msgSender(), eslsdAmount, slsdAmount, vestingDurationInDays);

    userRedeems[_msgSender()].push(RedeemInfo(eslsdAmount, slsdAmount, block.timestamp.add(vestingDurationInDays.mul(1 days))));
  }

  /**
   * @dev Finalizes redeem process when vesting duration has been reached
   *
   * Can only be called by the redeem entry owner
   */
  function finalizeRedeem(uint256 redeemIndex) external nonReentrant validateRedeem(_msgSender(), redeemIndex) {
    RedeemInfo storage _redeem = userRedeems[_msgSender()][redeemIndex];
    require(block.timestamp >= _redeem.endTime, "finalizeRedeem: vesting duration has not ended yet");

    // console.log('balance, allocation amount: %s, redeeming amount: %s', balance.allocatedAmount, balance.redeemingAmount);
    _finalizeRedeem(_msgSender(), _redeem.eslsdAmount, _redeem.slsdAmount);

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }

  
  /**
   * @dev Cancels an ongoing redeem entry
   *
   * Can only be called by its owner.
   */
  function cancelRedeem(uint256 redeemIndex) external nonReentrant validateRedeem(_msgSender(), redeemIndex) {
    RedeemInfo storage _redeem = userRedeems[_msgSender()][redeemIndex];

    _transfer(address(this), _msgSender(), _redeem.eslsdAmount);

    emit CancelRedeem(_msgSender(), _redeem.eslsdAmount);

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }


  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Escrow caller's "amount" of SLSD into eSLSD to "to"
   */
  function _escrow(uint256 amount, address to) internal {
    require(amount != 0, "escrow: amount cannot be null");

    // mint new eSLSD
    _mint(to, amount);

    emit Escrow(_msgSender(), to, amount);
    slsdToken.safeTransferFrom(_msgSender(), address(this), amount);
  }

  function _finalizeRedeem(address userAddress, uint256 eslsdAmount, uint256 slsdAmount) internal {
    slsdToken.safeTransfer(userAddress, slsdAmount);
    _burn(address(this), slsdAmount);

    uint256 fees = eslsdAmount.sub(slsdAmount);
    if (fees > 0) {
      _redeemFees = _redeemFees.add(fees);
      emit RedeemFeesAccrued(_msgSender(), eslsdAmount, fees);
    }

    emit FinalizeRedeem(userAddress, eslsdAmount, slsdAmount);
  }


  function _deleteRedeemEntry(uint256 index) internal {
    userRedeems[_msgSender()][index] = userRedeems[_msgSender()][userRedeems[_msgSender()].length - 1];
    userRedeems[_msgSender()].pop();
  }

  /**
   * @dev Hook override to forbid transfers except from whitelisted addresses and minting
   */
  function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal view override {
    require(from == address(0) || _whitelistAddresses.contains(from) || _whitelistAddresses.contains(to), "transfer: not allowed");
  }

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /*
   * @dev Check if a redeem entry exists
   */
  modifier validateRedeem(address userAddress, uint256 redeemIndex) {
    require(redeemIndex < userRedeems[userAddress].length, "validateRedeem: invalid index");
    _;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Escrow(address indexed from, address to, uint256 amount);
  event Redeem(address indexed userAddress, uint256 eslsdAmount, uint256 slsdAmount, uint256 durationInDays);
  event FinalizeRedeem(address indexed userAddress, uint256 eslsdAmount, uint256 slsdAmount);
  event CancelRedeem(address indexed userAddress, uint256 eslsdAmount);
  event RedeemFeesAccrued(address indexed user, uint256 totalAmount, uint256 fees);
  event RedeemFeesWithdrawn(address indexed to, uint256 amount);
  event UpdateWhitelistAddress(address account, bool whitelisted);
}