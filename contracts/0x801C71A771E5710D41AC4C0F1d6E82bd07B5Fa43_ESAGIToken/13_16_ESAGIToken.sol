// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/tokens/IAGIToken.sol";
import "./interfaces/tokens/IESAGIToken.sol";
import "./interfaces/IESAGITokenUsage.sol";

/*
 * ESAGI is AGILITY's escrowed governance token obtainable by converting AGI to it
 * It's non-transferable, except from/to whitelisted addresses
 * It can be converted back to AGI through a vesting process
 * This contract is made to receive esAGI deposits from users in order to allocate them to Usages (plugins) contracts
 */

contract ESAGIToken is Ownable, ReentrancyGuard, ERC20("AGILITY escrowed token", "esAGI"), IESAGIToken {
  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IAGIToken;

  struct ESAGIBalance {
    uint256 allocatedAmount; // Amount of ESAGI allocated to a Usage
    uint256 redeemingAmount; // Total amount of ESAGI  currently being redeemed
  }

  struct RedeemInfo {
    uint256 agiAmount; // AGI amount to receive when vesting has ended
    uint256 ESAGIAmount; // ESAGI amount to redeem
    uint256 endTime;
    IESAGITokenUsage dividendsAddress;
    uint256 dividendsAllocation; // Share of redeeming ESAGI to allocate to the Dividends Usage contract
  }

  IAGIToken public immutable agiToken; // AGI token to convert to/from
  IESAGITokenUsage public dividendsAddress; // AGILITY dividends contract

  EnumerableSet.AddressSet private _transferWhitelist; // addresses allowed to send/receive ESAGI

  mapping(address => mapping(address => uint256)) public usageApprovals; // Usage approvals to allocate ESAGI
  mapping(address => mapping(address => uint256)) public override usageAllocations; // Active ESAGI allocations to usages

  uint256 public constant MAX_DEALLOCATION_FEE = 200; // 2%
  mapping(address => uint256) public usagesDeallocationFee; // Fee paid when deallocating ESAGI

  uint256 public constant MAX_FIXED_RATIO = 100; // 100%

  // Redeeming min/max settings
  uint256 public minRedeemRatio = 50; // 1:0.5
  uint256 public maxRedeemRatio = 100; // 1:1
  uint256 public minRedeemDuration = 3 days; // 1296000s
  uint256 public maxRedeemDuration = 14 days; // 7776000s
  // Adjusted dividends rewards for redeeming ESAGI
  uint256 public redeemDividendsAdjustment = 0; // 50%

  mapping(address => ESAGIBalance) public ESAGIBalances; // User's ESAGI balances
  mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances


  constructor(IAGIToken agiToken_) {
    agiToken = agiToken_;
    _transferWhitelist.add(address(this));
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event ApproveUsage(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Convert(address indexed from, address to, uint256 amount);
  event UpdateRedeemSettings(uint256 minRedeemRatio, uint256 maxRedeemRatio, uint256 minRedeemDuration, uint256 maxRedeemDuration, uint256 redeemDividendsAdjustment);
  event UpdateDividendsAddress(address previousDividendsAddress, address newDividendsAddress);
  event UpdateDeallocationFee(address indexed usageAddress, uint256 fee);
  event SetTransferWhitelist(address account, bool add);
  event Redeem(address indexed userAddress, uint256 ESAGIAmount, uint256 agiAmount, uint256 duration);
  event FinalizeRedeem(address indexed userAddress, uint256 ESAGIAmount, uint256 agiAmount);
  event CancelRedeem(address indexed userAddress, uint256 ESAGIAmount);
  event UpdateRedeemDividendsAddress(address indexed userAddress, uint256 redeemIndex, address previousDividendsAddress, address newDividendsAddress);
  event Allocate(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Deallocate(address indexed userAddress, address indexed usageAddress, uint256 amount, uint256 fee);

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /*
   * @dev Check if a redeem entry exists
   */
  modifier validateRedeem(address userAddress, uint256 redeemIndex) {
    require(redeemIndex < userRedeems[userAddress].length, "validateRedeem: redeem entry does not exist");
    _;
  }

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  /*
   * @dev Returns user's ESAGI balances
   */
  function getESAGIBalance(address userAddress) external view returns (uint256 allocatedAmount, uint256 redeemingAmount) {
    ESAGIBalance storage balance = ESAGIBalances[userAddress];
    return (balance.allocatedAmount, balance.redeemingAmount);
  }

  /*
   * @dev returns redeemable agi for "amount" of ESAGI vested for "duration" seconds
   */
  function getagiByVestingDuration(uint256 amount, uint256 duration) public view returns (uint256) {
    if(duration < minRedeemDuration) {
      return 0;
    }

    // capped to maxRedeemDuration
    if (duration > maxRedeemDuration) {
      return amount.mul(maxRedeemRatio).div(100);
    }

    uint256 ratio = minRedeemRatio.add(
      (duration.sub(minRedeemDuration)).mul(maxRedeemRatio.sub(minRedeemRatio))
      .div(maxRedeemDuration.sub(minRedeemDuration))
    );

    return amount.mul(ratio).div(100);
  }

  /**
   * @dev returns quantity of "userAddress" pending redeems
   */
  function getUserRedeemsLength(address userAddress) external view returns (uint256) {
    return userRedeems[userAddress].length;
  }

  /**
   * @dev returns "userAddress" info for a pending redeem identified by "redeemIndex"
   */
  function getUserRedeem(address userAddress, uint256 redeemIndex) external view validateRedeem(userAddress, redeemIndex) returns (uint256 agiAmount, uint256 ESAGIAmount, uint256 endTime, address dividendsContract, uint256 dividendsAllocation) {
    RedeemInfo storage _redeem = userRedeems[userAddress][redeemIndex];
    return (_redeem.agiAmount, _redeem.ESAGIAmount, _redeem.endTime, address(_redeem.dividendsAddress), _redeem.dividendsAllocation);
  }

  /**
   * @dev returns approved ESAGI to allocate from "userAddress" to "usageAddress"
   */
  function getUsageApproval(address userAddress, address usageAddress) external view returns (uint256) {
    return usageApprovals[userAddress][usageAddress];
  }

  /**
   * @dev returns allocated ESAGI from "userAddress" to "usageAddress"
   */
  function getUsageAllocation(address userAddress, address usageAddress) external view returns (uint256) {
    return usageAllocations[userAddress][usageAddress];
  }

  /**
   * @dev returns length of transferWhitelist array
   */
  function transferWhitelistLength() external view returns (uint256) {
    return _transferWhitelist.length();
  }

  /**
   * @dev returns transferWhitelist array item's address for "index"
   */
  function transferWhitelist(uint256 index) external view returns (address) {
    return _transferWhitelist.at(index);
  }

  /**
   * @dev returns if "account" is allowed to send/receive ESAGI
   */
  function isTransferWhitelisted(address account) external override view returns (bool) {
    return _transferWhitelist.contains(account);
  }

  /*******************************************************/
  /****************** OWNABLE FUNCTIONS ******************/
  /*******************************************************/

  /**
   * @dev Updates all redeem ratios and durations
   *
   * Must only be called by owner
   */
  function updateRedeemSettings(uint256 minRedeemRatio_, uint256 maxRedeemRatio_, uint256 minRedeemDuration_, uint256 maxRedeemDuration_, uint256 redeemDividendsAdjustment_) external onlyOwner {
    require(minRedeemRatio_ <= maxRedeemRatio_, "updateRedeemSettings: wrong ratio values");
    require(minRedeemDuration_ < maxRedeemDuration_, "updateRedeemSettings: wrong duration values");
    // should never exceed 100%
    require(maxRedeemRatio_ <= MAX_FIXED_RATIO && redeemDividendsAdjustment_ <= MAX_FIXED_RATIO, "updateRedeemSettings: wrong ratio values");

    minRedeemRatio = minRedeemRatio_;
    maxRedeemRatio = maxRedeemRatio_;
    minRedeemDuration = minRedeemDuration_;
    maxRedeemDuration = maxRedeemDuration_;
    redeemDividendsAdjustment = redeemDividendsAdjustment_;

    emit UpdateRedeemSettings(minRedeemRatio_, maxRedeemRatio_, minRedeemDuration_, maxRedeemDuration_, redeemDividendsAdjustment_);
  }

  /**
   * @dev Updates dividends contract address
   *
   * Must only be called by owner
   */
  function updateDividendsAddress(IESAGITokenUsage dividendsAddress_) external onlyOwner {
    // if set to 0, also set divs earnings while redeeming to 0
    if(address(dividendsAddress_) == address(0)) {
      redeemDividendsAdjustment = 0;
    }

    emit UpdateDividendsAddress(address(dividendsAddress), address(dividendsAddress_));
    dividendsAddress = dividendsAddress_;
  }

  /**
   * @dev Updates fee paid by users when deallocating from "usageAddress"
   */
  function updateDeallocationFee(address usageAddress, uint256 fee) external onlyOwner {
    require(fee <= MAX_DEALLOCATION_FEE, "updateDeallocationFee: too high");

    usagesDeallocationFee[usageAddress] = fee;
    emit UpdateDeallocationFee(usageAddress, fee);
  }

  /**
   * @dev Adds or removes addresses from the transferWhitelist
   */
  function updateTransferWhitelist(address account, bool add) external onlyOwner {
    require(account != address(this), "updateTransferWhitelist: Cannot remove ESAGI from whitelist");

    if(add) _transferWhitelist.add(account);
    else _transferWhitelist.remove(account);

    emit SetTransferWhitelist(account, add);
  }

  /*****************************************************************/
  /******************  EXTERNAL PUBLIC FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Approves "usage" address to get allocations up to "amount" of ESAGI from msg.sender
   */
  function approveUsage(IESAGITokenUsage usage, uint256 amount) external nonReentrant {
    require(address(usage) != address(0), "approveUsage: approve to the zero address");

    usageApprovals[msg.sender][address(usage)] = amount;
    emit ApproveUsage(msg.sender, address(usage), amount);
  }

  /**
   * @dev Convert caller's "amount" of agi to ESAGI
   */
  function convert(uint256 amount) external nonReentrant {
    _convert(amount, msg.sender);
  }

  /**
   * @dev Convert caller's "amount" of agi to ESAGI to "to" address
   */
  function convertTo(uint256 amount, address to) external override nonReentrant {
    require(address(msg.sender).isContract(), "convertTo: not allowed");
    _convert(amount, to);
  }

  /**
   * @dev Initiates redeem process (ESAGI to agi)
   *
   * Handles dividends' compensation allocation during the vesting process if needed
   */
  function redeem(uint256 ESAGIAmount, uint256 duration) external nonReentrant {
    require(ESAGIAmount > 0, "redeem: ESAGIAmount cannot be null");
    require(duration >= minRedeemDuration, "redeem: duration too low");

    _transfer(msg.sender, address(this), ESAGIAmount);
    ESAGIBalance storage balance = ESAGIBalances[msg.sender];

    // get corresponding agi amount
    uint256 agiAmount = getagiByVestingDuration(ESAGIAmount, duration);
    emit Redeem(msg.sender, ESAGIAmount, agiAmount, duration);

    // if redeeming is not immediate, go through vesting process
    if(duration > 0) {
      // add to SBT total
      balance.redeemingAmount = balance.redeemingAmount.add(ESAGIAmount);

      // handle dividends during the vesting process
      uint256 dividendsAllocation = ESAGIAmount.mul(redeemDividendsAdjustment).div(100);
      // only if compensation is active
      if(dividendsAllocation > 0) {
        // allocate to dividends
        dividendsAddress.allocate(msg.sender, dividendsAllocation, new bytes(0));
      }

      // add redeeming entry
      userRedeems[msg.sender].push(RedeemInfo(agiAmount, ESAGIAmount, _currentBlockTimestamp().add(duration), dividendsAddress, dividendsAllocation));
    } else {
      // immediately redeem for agi
      _finalizeRedeem(msg.sender, ESAGIAmount, agiAmount);
    }
  }

  /**
   * @dev Finalizes redeem process when vesting duration has been reached
   *
   * Can only be called by the redeem entry owner
   */
  function finalizeRedeem(uint256 redeemIndex) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
    ESAGIBalance storage balance = ESAGIBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];
    require(_currentBlockTimestamp() >= _redeem.endTime, "finalizeRedeem: vesting duration has not ended yet");

    // remove from SBT total
    balance.redeemingAmount = balance.redeemingAmount.sub(_redeem.ESAGIAmount);
    _finalizeRedeem(msg.sender, _redeem.ESAGIAmount, _redeem.agiAmount);

    // handle dividends compensation if any was active
    if(_redeem.dividendsAllocation > 0) {
      // deallocate from dividends
      IESAGITokenUsage(_redeem.dividendsAddress).deallocate(msg.sender, _redeem.dividendsAllocation, new bytes(0));
    }

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }

  /**
   * @dev Updates dividends address for an existing active redeeming process
   *
   * Can only be called by the involved user
   * Should only be used if dividends contract was to be migrated
   */
  function updateRedeemDividendsAddress(uint256 redeemIndex) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
    RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

    // only if the active dividends contract is not the same anymore
    if(dividendsAddress != _redeem.dividendsAddress && address(dividendsAddress) != address(0)) {
      if(_redeem.dividendsAllocation > 0) {
        // deallocate from old dividends contract
        _redeem.dividendsAddress.deallocate(msg.sender, _redeem.dividendsAllocation, new bytes(0));
        // allocate to new used dividends contract
        dividendsAddress.allocate(msg.sender, _redeem.dividendsAllocation, new bytes(0));
      }

      emit UpdateRedeemDividendsAddress(msg.sender, redeemIndex, address(_redeem.dividendsAddress), address(dividendsAddress));
      _redeem.dividendsAddress = dividendsAddress;
    }
  }

  /**
   * @dev Cancels an ongoing redeem entry
   *
   * Can only be called by its owner
   */
  function cancelRedeem(uint256 redeemIndex) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
    ESAGIBalance storage balance = ESAGIBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

    // make redeeming ESAGI available again
    balance.redeemingAmount = balance.redeemingAmount.sub(_redeem.ESAGIAmount);
    _transfer(address(this), msg.sender, _redeem.ESAGIAmount);

    // handle dividends compensation if any was active
    if(_redeem.dividendsAllocation > 0) {
      // deallocate from dividends
      IESAGITokenUsage(_redeem.dividendsAddress).deallocate(msg.sender, _redeem.dividendsAllocation, new bytes(0));
    }

    emit CancelRedeem(msg.sender, _redeem.ESAGIAmount);

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }


  /**
   * @dev Allocates caller's "amount" of available ESAGI to "usageAddress" contract
   *
   * args specific to usage contract must be passed into "usageData"
   */
  function allocate(address usageAddress, uint256 amount, bytes calldata usageData) external nonReentrant {
    _allocate(msg.sender, usageAddress, amount);

    // allocates ESAGI to usageContract
    IESAGITokenUsage(usageAddress).allocate(msg.sender, amount, usageData);
  }

  /**
   * @dev Allocates "amount" of available ESAGI from "userAddress" to caller (ie usage contract)
   *
   * Caller must have an allocation approval for the required ESAGI ESAGI from "userAddress"
   */
  function allocateFromUsage(address userAddress, uint256 amount) external override nonReentrant {
    _allocate(userAddress, msg.sender, amount);
  }

  /**
   * @dev Deallocates caller's "amount" of available ESAGI from "usageAddress" contract
   *
   * args specific to usage contract must be passed into "usageData"
   */
  function deallocate(address usageAddress, uint256 amount, bytes calldata usageData) external nonReentrant {
    _deallocate(msg.sender, usageAddress, amount);

    // deallocate ESAGI into usageContract
    IESAGITokenUsage(usageAddress).deallocate(msg.sender, amount, usageData);
  }

  /**
   * @dev Deallocates "amount" of allocated ESAGI belonging to "userAddress" from caller (ie usage contract)
   *
   * Caller can only deallocate ESAGI from itself
   */
  function deallocateFromUsage(address userAddress, uint256 amount) external override nonReentrant {
    _deallocate(userAddress, msg.sender, amount);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Convert caller's "amount" of agi into ESAGI to "to"
   */
  function _convert(uint256 amount, address to) internal {
    require(amount != 0, "convert: amount cannot be null");

    // mint new ESAGI
    _mint(to, amount);

    emit Convert(msg.sender, to, amount);
    agiToken.safeTransferFrom(msg.sender, address(this), amount);
  }

  /**
   * @dev Finalizes the redeeming process for "userAddress" by transferring him "AGIAmount" and removing "ESAGIAmount" from supply
   *
   * Any vesting check should be ran before calling this
   * agi excess is automatically burnt
   */
  function _finalizeRedeem(address userAddress, uint256 ESAGIAmount, uint256 AGIAmount) internal {
    uint256 agiExcess = ESAGIAmount.sub(AGIAmount);

    // sends due agi tokens
    agiToken.safeTransfer(userAddress, AGIAmount);

    // burns agi excess if any
    agiToken.burn(agiExcess);
    _burn(address(this), ESAGIAmount);

    emit FinalizeRedeem(userAddress, ESAGIAmount, AGIAmount);
  }

  /**
   * @dev Allocates "userAddress" user's "amount" of available ESAGI to "usageAddress" contract
   *
   */
  function _allocate(address userAddress, address usageAddress, uint256 amount) internal {
    require(amount > 0, "allocate: amount cannot be null");

    ESAGIBalance storage balance = ESAGIBalances[userAddress];

    // approval checks if allocation request amount has been approved by userAddress to be allocated to this usageAddress
    uint256 approvedESAGI = usageApprovals[userAddress][usageAddress];
    require(approvedESAGI >= amount, "allocate: non authorized amount");

    // remove allocated amount from usage's approved amount
    usageApprovals[userAddress][usageAddress] = approvedESAGI.sub(amount);

    // update usage's allocatedAmount for userAddress
    usageAllocations[userAddress][usageAddress] = usageAllocations[userAddress][usageAddress].add(amount);

    // adjust user's ESAGI balances
    balance.allocatedAmount = balance.allocatedAmount.add(amount);
    _transfer(userAddress, address(this), amount);

    emit Allocate(userAddress, usageAddress, amount);
  }

  /**
   * @dev Deallocates "amount" of available ESAGI to "usageAddress" contract
   *
   * args specific to usage contract must be passed into "usageData"
   */
  function _deallocate(address userAddress, address usageAddress, uint256 amount) internal {
    require(amount > 0, "deallocate: amount cannot be null");

    // check if there is enough allocated ESAGI to this usage to deallocate
    uint256 allocatedAmount = usageAllocations[userAddress][usageAddress];
    require(allocatedAmount >= amount, "deallocate: non authorized amount");

    // remove deallocated amount from usage's allocation
    usageAllocations[userAddress][usageAddress] = allocatedAmount.sub(amount);

    uint256 deallocationFeeAmount = amount.mul(usagesDeallocationFee[usageAddress]).div(10000);

    // adjust user's ESAGI balances
    ESAGIBalance storage balance = ESAGIBalances[userAddress];
    balance.allocatedAmount = balance.allocatedAmount.sub(amount);
    _transfer(address(this), userAddress, amount.sub(deallocationFeeAmount));
    // burn corresponding agi and ESAGI
    agiToken.burn(deallocationFeeAmount);
    _burn(address(this), deallocationFeeAmount);

    emit Deallocate(userAddress, usageAddress, amount, deallocationFeeAmount);
  }

  function _deleteRedeemEntry(uint256 index) internal {
    userRedeems[msg.sender][index] = userRedeems[msg.sender][userRedeems[msg.sender].length - 1];
    userRedeems[msg.sender].pop();
  }

  /**
   * @dev Hook override to forbid transfers except from whitelisted addresses and minting
   */
  function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal view override {
    require(from == address(0) || _transferWhitelist.contains(from) || _transferWhitelist.contains(to), "transfer: not allowed");
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    /* solhint-disable not-rely-on-time */
    return block.timestamp;
  }

}