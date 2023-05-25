// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IPancakeRouter } from "./interfaces/IPancakeRouter.sol";
import { IPancakeFactory } from "./interfaces/IPancakeFactory.sol";

contract NOVC is ERC20, Ownable {
  using Address for address payable;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public constant FEE_DENOMINATOR = 10000;

  IPancakeRouter public immutable pancekeRouter;
  address public immutable weth;
  uint256 public immutable minRewardUserAmt;
  uint256 public immutable rewardDistTime;
  uint256 public immutable fee;
  uint256 public immutable startBlockNumber;
  uint256 public immutable startBlockTS;
  uint256 public immutable startLimitBlockCount;
  uint256 public immutable startLimitAmount;
  address private immutable forLiquidity;

  event OnlyBuySellTaxSetted(bool enabled);
  event EnabledAsRewardAddress(address indexed account, bool indexed enabled);
  event ExcludedFromRewards(address indexed account, bool indexed excluded);
  event ExcludedFromFees(address indexed account, bool indexed excluded);
  event RewardDistributed(
    address indexed account,
    uint256 indexed tokenAmount,
    uint256 indexed nativeAmount,
    uint256 timeStamp
  );
  event DexAddressAdded(address indexed dex, bool indexed addded);

  mapping(address => bool) public excludedFromRewards;
  mapping(address => bool) public excludedFromFees;
  mapping(address => bool) public isDex;
  bool public onlyBuySellTax;
  address public rewardsAddress;
  uint256 public lastRewardDist;

  EnumerableSet.AddressSet private rewardAddresses_;

  constructor(
    string memory _name,
    string memory _symbol,
    address _rewardsAddress,
    address _forLiquidity,
    uint256 _initialAmount,
    IPancakeRouter _pancakeRouter,
    uint256 _minRewardUserAmt,
    uint256 _rewardDistTime,
    uint256 _fee,
    uint256 _startLimitBlockCount,
    uint256 _startLimitAmount
  ) ERC20(_name, _symbol) {
    uint256 amountforLiquidity = _initialAmount * 4 / 100;
    uint256 amountforBurn = _initialAmount - amountforLiquidity;
    _mint(_forLiquidity, amountforLiquidity);
    _mint(address(this), amountforBurn);
    _burn(address(this), amountforBurn);
    forLiquidity = _forLiquidity;
    minRewardUserAmt = _minRewardUserAmt;
    rewardsAddress = _rewardsAddress;
    pancekeRouter = _pancakeRouter;
    rewardDistTime = _rewardDistTime;
    fee = _fee;
    address _weth = _pancakeRouter.WETH();
    weth = _weth;
    require(_fee < FEE_DENOMINATOR, "Unpossible fee amount");
    address pair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _weth);
    _excludeFromRewards(address(this));
    _excludeFromFee(_forLiquidity, true);
    rewardAddresses_.add(_forLiquidity);
    lastRewardDist = block.timestamp;
    startBlockNumber = block.number;
    startBlockTS = block.timestamp;
    startLimitBlockCount = _startLimitBlockCount;
    startLimitAmount = _startLimitAmount;
    _setAsDex(pair, true);
    _approve(address(this), address(_pancakeRouter), type(uint256).max);
    emit EnabledAsRewardAddress(_forLiquidity, true);
  }

  function excludeFromFee(address _account, bool _exclude) external onlyOwner {
    _excludeFromFee(_account, _exclude);
  }

  function _excludeFromFee(address _account, bool _exclude) internal {
    excludedFromFees[_account] = _exclude;
    emit ExcludedFromFees(_account, _exclude);
  }

  function setOnlyBuySellTax(bool enable) external onlyOwner {
    onlyBuySellTax = enable;
    emit OnlyBuySellTaxSetted(enable);
  }

  function setAsDex(address _dex, bool _isDex) external onlyOwner {
    _setAsDex(_dex, _isDex);
  }

  function _setAsDex(address _dex, bool _isDex) internal {
    isDex[_dex] = _isDex;
    emit DexAddressAdded(_dex, _isDex);

    _isDex ? _excludeFromRewards(_dex) : _includeToRewards(_dex);
  }

  function excludeFromRewards(address _account) external onlyOwner {
    _excludeFromRewards(_account);
  }

  function includeToRewards(address _account) external onlyOwner {
    _includeToRewards(_account);
  }

  function _excludeFromRewards(address _account) internal {
    excludedFromRewards[_account] = true;
    emit ExcludedFromRewards(_account, true);
    bool removed = rewardAddresses_.remove(_account);
    if (removed) {
      emit EnabledAsRewardAddress(_account, false);
    }
  }

  function _includeToRewards(address _account) internal {
    excludedFromRewards[_account] = false;
    emit ExcludedFromRewards(_account, false);
    if (balanceOf(_account) > minRewardUserAmt) {
      bool added = rewardAddresses_.add(_account);
      if (added) {
        emit EnabledAsRewardAddress(_account, true);
      }
    }
  }

  function _calcFee(
    address _from,
    address _to,
    uint256 _amount
  ) internal view returns (uint256 _amtWithoutFee, uint256 _feeAmt) {
    uint _fee = fee;
    if (onlyBuySellTax && !isDex[_from] && !isDex[_to]) {
      _fee = 0;
    } else if (excludedFromFees[_from]) {
      _fee = 0;
    }
    _feeAmt = (_amount * _fee) / FEE_DENOMINATOR;
    _amtWithoutFee = _amount - _feeAmt;
  }

  function _transfer(address _from, address _to, uint256 _amount) internal override {
    if (
      block.number - startBlockNumber <= startLimitBlockCount &&
      (_from != owner() && _to != owner()) &&
      (_from != forLiquidity && _to != forLiquidity)
    ) {
      require(_amount <= startLimitAmount, "Big amount transfer in the launch!");
    }
    if(startBlockTS + 3 days > block.timestamp){
      super._transfer(_from, _to, _amount);
      _addToRewardAddressList(_from, _to);
      return;
    }
    if (_from == address(this) || _to == address(this) || _from == owner()) {
      super._transfer(_from, _to, _amount);
      _addToRewardAddressList(_from, _to);
      return;
    }

    (uint256 _amtWithoutFee, uint256 _feeAmt) = _calcFee(_from, _to, _amount);
    if (_feeAmt != 0) {
      super._transfer(_from, _to, _amtWithoutFee);
      super._transfer(_from, address(this), _feeAmt);
    } else {
      super._transfer(_from, _to, _amtWithoutFee);
    }
    _addToRewardAddressList(_from, _to);
    if(!isDex[_from] && !isDex[_to]){
      _distributeRewards();
    }
  }

  function distributeRewards() external {
    _distributeRewards();
  }

  function _distributeRewards() internal {
    uint256 len = rewardAddresses_.length();
    if (len == 0 || lastRewardDist + rewardDistTime > block.timestamp) {
      return;
    }
    lastRewardDist = block.timestamp;
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = weth;

    try
      pancekeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        balanceOf(address(this)) / 2,
        0,
        path,
        address(this),
        block.timestamp
      )
    {} catch {}
    uint256 tokenTransferAmt = balanceOf(address(this)) / 2;
    uint256 nativeTransferAmt = address(this).balance / 2;
    uint256 rand = block.prevrandao % len;
    address randUser = rewardAddresses_.at(rand);
    // transfer the tokens
    _transfer(address(this), rewardsAddress, tokenTransferAmt);
    _transfer(address(this), randUser, tokenTransferAmt);
    // transfer the natives
    payable(rewardsAddress).sendValue(nativeTransferAmt);
    payable(randUser).sendValue(nativeTransferAmt);
    emit RewardDistributed(randUser, tokenTransferAmt, nativeTransferAmt, block.timestamp);
  }

  function _addToRewardAddressList(address _from, address _to) internal {
    uint256 _fromBal = balanceOf(_from);
    uint256 _toBal = balanceOf(_to);
    if (!excludedFromRewards[_from] && _fromBal < minRewardUserAmt) {
      bool removed = rewardAddresses_.remove(_from);
      if (removed) {
        emit EnabledAsRewardAddress(_from, false);
      }
    }
    if (!excludedFromRewards[_to] && _toBal >= minRewardUserAmt) {
      bool added = rewardAddresses_.add(_to);
      if (added) {
        emit EnabledAsRewardAddress(_to, true);
      }
    }
  }

  function withdrawEth() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(msg.sender).sendValue(amount);
  }
    
  function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner{
    require(tokenAddress != address(this), "Not possible to withdraw this token");
    ERC20 token = ERC20(tokenAddress);
    require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
    token.transfer(msg.sender, amount);
  }

  receive() external payable {}
}