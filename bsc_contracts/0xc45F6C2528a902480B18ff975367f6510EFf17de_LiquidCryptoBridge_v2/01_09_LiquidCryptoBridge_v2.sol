// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/IWETH.sol";
import "./../interface/IUniswapRouterETH.sol";

contract LiquidCryptoBridge_v2 is ERC20, Ownable {
  uint256 public swapFee = 500;
  uint256 public platformFee = 30000;
  uint256 public feeDecimals = 100000;
  address public unirouter;
  address public native;
  address public stable;
  address[] public nativeToStable;
  address public treasury;

  uint256 private totalEarned = 0;
  uint256 private totalReward = 0;
  uint256 private lastTotalTs;
  uint256 private totalUserShare = 0;
  uint256 private totalUserClaimed = 0;

  uint256 public swapIndex = 0;

  struct SwapVoucher {
    uint256 iAmount;
    uint256 stableAmount;
    uint256 outChain;
    address toAccount;
    address refundAccount;
  }

  struct StakeInfo {
    uint256 amount;
    uint256 startedAt;
    uint256 debtReward;
  }

  mapping (uint256 => SwapVoucher) public voucherLists;
  mapping (address => bool) public managers;
  mapping (address => StakeInfo) public userInfo;

  event Stake(address account, uint256 amount, uint256 totalStake, uint256 totalShare);
  event Unstake(address account, uint256 amount, uint256 totalStake, uint256 totalShare);
  event Claimed(address account, uint256 amount);
  event Swap(uint256 index, address from, address to, uint256 outChain, uint256 inAmout, uint256 stableAmount);
  event Redeem(address to, uint256 stableAmount, uint256 outAmout);
  event Refund(uint256 index, address to, uint256 amount);
  event APY(uint256 totalStake, uint256 totalReward);

  constructor(
    address _unirouter,
    address[] memory _nativeToStable,
    address _treasury
  )
    ERC20("LCBridgeLP_v2", "BPv2")
  {
    unirouter = _unirouter;
    
    native = _nativeToStable[0];
    stable = _nativeToStable[_nativeToStable.length - 1];
    nativeToStable = _nativeToStable;

    treasury = _treasury;

    managers[msg.sender] = true;
    lastTotalTs = block.timestamp;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LC Bridge v2: !manager");
    _;
  }

  function swap(address _to, address _refund, uint256 _outChainID) public payable returns(uint256) {
    uint256 amount = msg.value;
    address account = msg.sender;

    amount = _cutFee(amount);
    uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsOut(amount, nativeToStable);

    swapIndex ++;
    uint256 stableAmount = amounts[amounts.length-1];
    voucherLists[swapIndex] = SwapVoucher(amount, stableAmount, _outChainID, _to, _refund);
    emit Swap(swapIndex, account, _to, _outChainID, msg.value, stableAmount);
    emit APY(totalSupply(), totalEarned);
    return stableAmount;
  }

  function redeem(uint256 _amount, address _to, uint256 _fee, bool wrapped) public onlyManager returns(uint256){
    uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsIn(_amount, nativeToStable);
    uint256 amount = amounts[0];
    require(amount <= address(this).balance, "LC Bridge v2: Few redeem liquidity");
    require(amount >= _fee, "LC Bridge v2: Few redeem liquidity");
    amount -= _fee;

    if (amount > 0) {
      if (wrapped) {
        IWETH(native).deposit{value: amount}();
        IWETH(native).transfer(_to, amount);
      }
      else {
        (bool success, ) = payable(_to).call{value: amount}("");
        require(success, "LC Bridge v2: Failed redeem");
      }
    }
    if (_fee > 0) {
      (bool success, ) = payable(msg.sender).call{value: _fee}("");
      require(success, "LC Bridge v2: Failed refund manager fee");
    }
    emit Redeem(_to, _amount, amount);
    return amount;
  }

  function refund(uint256 _index, uint256 _fee) public onlyManager {
    uint256 amount = voucherLists[_index].iAmount;
    (bool success, ) = payable(voucherLists[_index].refundAccount).call{value: amount - _fee}("");
    require(success, "LC Bridge v2: Failed refund");
    if (_fee > 0) {
      (success, ) = payable(msg.sender).call{value: _fee}("");
      require(success, "LC Bridge v2: Failed refund manager fee");
    }
  }

  function getAmountsIn(uint256 _amount) public view returns(uint256 coin) {
    uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsIn(_amount, nativeToStable);
    coin = amounts[0];
  }

  function getAmountsOut(uint256 _amount) public view returns(uint256 stableAmount) {
    uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsOut(_amount, nativeToStable);
    stableAmount = amounts[amounts.length-1];
  }

  function stake() public payable {
    uint256 amount = msg.value;
    address account = msg.sender;
    uint256 _now = block.timestamp;
    
    totalUserShare += totalSupply() * (_now - lastTotalTs);
    lastTotalTs = _now;
    StakeInfo storage tmpInfo = userInfo[account];
    tmpInfo.debtReward += tmpInfo.amount * (_now - tmpInfo.startedAt);
    tmpInfo.amount += amount;
    tmpInfo.startedAt = _now;

    _mint(msg.sender, amount);

    emit Stake(account, amount, totalSupply(), totalUserShare);
    emit APY(totalSupply(), totalEarned);
  }

  function unstake(uint256 _amount) public {
    require(_amount <= balanceOf(msg.sender), "LC Bridge v2: Exceed amount");
    require(_amount <= address(this).balance, "LC Bridge v2: Few unstake liquidity");

    uint256 _now = block.timestamp;
    address account = msg.sender;
    uint256 userReward = getReward(msg.sender);
    if (userReward > 0) {
      claimReward(msg.sender, userReward);
    }
    StakeInfo storage tmpInfo = userInfo[account];
    tmpInfo.amount -= _amount;
    totalUserShare += totalSupply() * (_now - lastTotalTs);
    lastTotalTs = _now;

    if (_amount > address(this).balance) {
      _amount = address(this).balance;
    }
    _burn(account, _amount);

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "LC Bridge v2: Failed to unstake");

    emit Unstake(account, _amount, totalSupply(), totalUserShare);
    emit APY(totalSupply(), totalEarned);
  }

  function getReward(address _account) public view returns(uint256) {
    uint256 _now = block.timestamp;
    uint256 tmpTotalShare = totalUserShare + totalSupply() * (_now - lastTotalTs);
    if (tmpTotalShare <= totalUserClaimed) return 0;
    tmpTotalShare -= totalUserClaimed;
    uint256 tmpUserTotal = userInfo[_account].debtReward + userInfo[_account].amount * (_now - userInfo[_account].startedAt);
    return totalReward * tmpUserTotal / tmpTotalShare;
  }

  function claimReward(address _account, uint256 _amount) public {
    uint256 userReward = getReward(_account);
    if (userReward < _amount) {
      _amount = userReward;
    }
    if (_amount > address(this).balance) {
      _amount = address(this).balance;
    }

    uint256 _now = block.timestamp;
    StakeInfo storage tmpInfo = userInfo[_account];
    tmpInfo.debtReward = (tmpInfo.debtReward + tmpInfo.amount * (_now - tmpInfo.startedAt)) * (userReward - _amount) / userReward;
    tmpInfo.startedAt = _now;
    uint256 tmpTotalShare = totalUserShare + totalSupply() * (_now - lastTotalTs);
    if (tmpTotalShare < totalUserClaimed) {
      totalUserClaimed = tmpTotalShare;
    }
    else {
     tmpTotalShare -= totalUserClaimed;
     totalUserClaimed += (tmpTotalShare * _amount / totalReward);
    }
    totalReward -= _amount;

    if (_amount > 0) {
      (bool success, ) = payable(_account).call{value: _amount}("");
      require(success, "LC Bridge v2: Failed to claim reward");
    }

    emit Claimed(_account, _amount);
  }
  
  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setPlatformFee(uint256 _platformFee) public onlyManager {
    platformFee = _platformFee;
  }

  function setUnirouterInfo(address _unirouter, address[] memory _nativeToStable) public onlyManager {
    unirouter = _unirouter;
    native = _nativeToStable[0];
    stable = _nativeToStable[_nativeToStable.length - 1];
    nativeToStable = _nativeToStable;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function deposit() public payable onlyManager {
    if (totalSupply() > address(this).balance) {
      uint256 needAmount = totalSupply() - address(this).balance;
      if (msg.value > needAmount) {
        uint256 refund = msg.value - needAmount;
        (bool success, ) = msg.sender.call{value: refund}("");
        require(success, "LC Bridge v2: Failed depoist overflow");
      }
    }
  }

  function withdraw() public onlyManager {
    if (totalSupply() < address(this).balance) {
      uint256 availableAmount = address(this).balance - totalSupply();
      (bool success1, ) = msg.sender.call{value: availableAmount}("");
      require(success1, "LC Bridge v2: Failed revoke");
    }
  }

  function _cutFee(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / feeDecimals;
      uint256 treasuryFee = fee * platformFee / feeDecimals;
      if (treasuryFee > 0) {
        (bool success, ) = payable(treasury).call{value: treasuryFee}("");
        require(success, "LC Bridge v2: Failed cut fee");
      }
      totalEarned += (fee - treasuryFee);
      totalReward += (fee - treasuryFee);
      return _amount - fee;
    }
    return 0;
  }
}