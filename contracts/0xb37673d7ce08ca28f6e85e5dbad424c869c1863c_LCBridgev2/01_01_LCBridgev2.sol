// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}


contract LCBridgev2 is Ownable {
  uint256 public chainId;
  address public treasury;

  mapping (address => bool) public noFeeWallets;
  mapping (address => bool) public managers;

  uint256 public swapFee = 5000;
  uint256 public platformFee = 300000;
  uint256 private constant coreDecimal = 1000000;
  uint256 private constant MULTIPLIER = 1_0000_0000_0000_0000;

  struct StakeInfo {
    uint256 amount;   // Staked liquidity
    uint256 debtReward;
    uint256 rtr;
    uint256 updatedAt;
  }

  struct SwapVoucher {
    uint256 amount;
    uint256 outChain;
    address toAccount;
    address refundAccount;
  }

  uint256 public totalReward = 0;
  uint256 public prevReward = 0;
  uint256 public rtr = 0;
  uint256 public tvl;
  mapping (address => StakeInfo) public userInfo;
  uint256 private swapIndex = 1;
  uint256 private unstakeDebtIndex = 1;
  mapping (uint256 => SwapVoucher) public voucherLists;

  modifier onlyManager() {
    require(managers[msg.sender], "LCBridgev2: !manager");
    _;
  }

  event Swap(address operator, address receiver, address refund, uint256 amount, uint256 srcChainId, uint256 desChainId, uint256 swapIndex);
  event Redeem(address operator, address account, uint256 amount, uint256 srcChainId, uint256 swapIndex);
  event Stake(address account, uint256 amount);
  event Unstake(address account, uint256 amount, bool force);
  event UnstakeDebt(address account, uint256 amount, uint256 chainId, uint256 index);
  event DebtUnstake(address account, uint256 amount, uint256 chainId, uint256 index);
  event Claim(address acccount, uint256 amount);
  event Refund(address operator, address account, uint256 index, uint256 amount);
  event CutFee(uint256 fee, address treasury, uint256 treasuryFee, uint256 totalFee, uint256 tvl);

  constructor(
    uint256 _chainId,
    address _treasury
  )
  {
    require(_treasury != address(0), "LCBridgev2: Treasury");
    
    chainId = _chainId;
    treasury = _treasury;
    managers[msg.sender] = true;
  }

  function swap(address _to, address _refund, uint256 _outChainID) public payable returns(uint256) {
    uint256 amount = msg.value;
    if (noFeeWallets[msg.sender] == false) {
      amount = _cutFee(amount);
    }
    voucherLists[swapIndex] = SwapVoucher(amount, _outChainID, _to, _refund);
    emit Swap(msg.sender, _to, _refund, amount, chainId, _outChainID, swapIndex);
    swapIndex ++;
    return amount;
  }

  function redeem(address account, uint256 amount, uint256 srcChainId, uint256 _swapIndex, uint256 operatorFee) public onlyManager returns(uint256) {
    require(amount <= address(this).balance, "LCBridgev2: Few redeem liquidity");
    require(amount >= operatorFee, "LCBridgev2: Few redeem liquidity");

    amount -= operatorFee;
    if (amount > 0) {
      (bool success, ) = payable(account).call{value: amount}("");
      require(success, "LCBridgev2: Failed refund manager fee");
      emit Redeem(msg.sender, account, amount, srcChainId, _swapIndex);
    }

    if (operatorFee > 0) {
      (bool success, ) = payable(msg.sender).call{value: operatorFee}("");
      require(success, "LCBridgev2: Failed refund manager fee");
    }
    return amount;
  }

  function refund(uint256 _index, uint256 _fee) public onlyManager returns(uint256) {
    uint256 amount = voucherLists[_index].amount;
    amount -= _fee;
    (bool success, ) = payable(voucherLists[_index].refundAccount).call{value: amount}("");
    require(success, "LCBridgev2: Failed refund");
    if (_fee > 0) {
      (success, ) = payable(msg.sender).call{value: _fee}("");
      require(success, "LCBridgev2: Failed operator fee");
    }
    emit Refund(msg.sender, voucherLists[_index].refundAccount, _index, amount);
    return amount;
  }

  function stake(address account) public payable returns(uint256) {
    userInfo[account].debtReward += getReward(account);

    uint256 amount = msg.value;
    if (tvl > 0) {
      rtr += (totalReward - prevReward) * MULTIPLIER / tvl;
    }
    else {
      rtr = 0;
    }
    prevReward = totalReward;
    tvl += amount;
    
    userInfo[account].amount += amount;
    userInfo[account].rtr = rtr;
    userInfo[account].updatedAt = block.timestamp;
    emit Stake(account, amount);
    return amount;
  }

  function unstake(address account, uint256 amount, bool force) public returns(uint256) {
    require(account == msg.sender || managers[msg.sender] == true, "LCBridgev2: wrong account");
    if (amount > userInfo[account].amount) {
      amount = userInfo[account].amount;
    }

    uint256 reward = getReward(account);
    if (reward > 0) {
      claimReward(account);
    }

    if (amount > 0) {
      uint256 liquidity = address(this).balance;
      uint256 unstakeAmount = amount;
      if (liquidity < amount) {
        unstakeAmount = liquidity;
        if (force) {
          emit UnstakeDebt(account, amount - liquidity, chainId, unstakeDebtIndex);
          unstakeDebtIndex ++;
        }
        else {
          amount = liquidity;
        }
      }

      (bool success, ) = payable(account).call{value: unstakeAmount}("");
      require(success, "LCBridgev2: Failed to unstake");

      tvl -= amount;
      userInfo[account].amount -= amount;
      emit Unstake(account, amount, force);
    }
    return amount;
  }

  function forceUnstake(address account, uint256 amount, uint256 _chainId, uint256 _debtIndex) public onlyManager {
    (bool success, ) = payable(account).call{value: amount}("");
    require(success, "LCBridgev2: Failed to debt unstake");
    emit DebtUnstake(account, amount, _chainId, _debtIndex);
  }

  function getReward(address account) public view returns(uint256) {
    uint256 reward = userInfo[account].debtReward;
    if (userInfo[account].amount > 0) {
      uint256 currentRtr = tvl > 0 ? (totalReward - prevReward) * MULTIPLIER / tvl : 0;
      currentRtr += rtr;
      if (currentRtr >= userInfo[account].rtr) {
        reward += (currentRtr - userInfo[account].rtr) * userInfo[account].amount / MULTIPLIER;
      }
    }
    return reward;
  }

  function claimReward(address account) public returns(uint256) {
    uint256 reward = getReward(account);
    if (reward > 0) {
      (bool success, ) = payable(account).call{value: reward}("");
      require(success, "LCBridgev2: Failed to claim reward");
    }
    uint256 currentRtr = tvl > 0 ? (totalReward - prevReward) * MULTIPLIER / tvl : 0;
    rtr += currentRtr;
    prevReward = totalReward;

    userInfo[account].debtReward = 0;
    userInfo[account].rtr = rtr;
    userInfo[account].updatedAt = block.timestamp;
    emit Claim(account, reward);
    return reward;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setNoFeeWallets(address account, bool access) public onlyManager {
    noFeeWallets[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setPlatformFee(uint256 _platformFee) public onlyManager {
    platformFee = _platformFee;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function _cutFee(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / coreDecimal;
      uint256 treasuryFee = fee * platformFee / coreDecimal;
      if (treasuryFee > 0) {
        (bool success, ) = payable(treasury).call{value: treasuryFee}("");
        require(success, "LCBridgev2: Failed cut fee");
      }
      if (tvl > 0) {
        totalReward += (fee - treasuryFee);
      }
      emit CutFee(fee, treasury, treasuryFee, totalReward, tvl);
      return _amount - fee;
    }
    return 0;
  }
}