// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

import "./IERC20.sol";
import "./SafeMath.sol";

contract POLContract {

    event Received(address, uint);
    event onDeposit(address, uint256, uint256);
    event onWithdraw(address, uint256);

    using SafeMath for uint256;

    struct VestingPeriod {
      uint256 epoch;
      uint256 amount;
    }

    struct UserTokenInfo {
      uint256 deposited; // incremented on successful deposit
      uint256 withdrawn; // incremented on successful withdrawl
      VestingPeriod[] vestingPeriods; // added to on successful deposit
    }

    // map erc20 token to user address to release schedule
    mapping(address => mapping(address => UserTokenInfo)) tokenUserMap;

    struct LiquidityTokenomics {
      uint256[] epochs;
      mapping (uint256 => uint256) releaseMap; // map epoch -> amount withdrawable
    }

    // map erc20 token to release schedule
    mapping(address => LiquidityTokenomics) tokenEpochMap;

    
    // Fast mapping to prevent array iteration in solidity
    mapping(address => bool) public lockedTokenLookup;

    // A dynamically-sized array of currently locked tokens
    address[] public lockedTokens;
    
    // fee variables
    uint256 public feeNumerator;
    uint256 public feeDenominator;
    
    address public feeReserveAddress;
    address public owner;
    
    constructor() public {                  
      feeNumerator = 3;
      feeDenominator = 1000;
      feeReserveAddress = address(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
      owner = address(0xfCdd591498e86876F086524C0b2E9Af41a0c9FCD);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    modifier onlyOwner {
      require(msg.sender == owner, "You are not the owner");
      _;
    }
    
    function updateFee(uint256 numerator, uint256 denominator) onlyOwner public {
      feeNumerator = numerator;
      feeDenominator = denominator;
    }
    
    function calculateFee(uint256 amount) public view returns (uint256){
      require(amount >= feeDenominator, 'Deposit is too small');    
      uint256 amountInLarge = amount.mul(feeDenominator.sub(feeNumerator));
      uint256 amountIn = amountInLarge.div(feeDenominator);
      uint256 fee = amount.sub(amountIn);
      return (fee);
    }
    
    function depositTokenMultipleEpochs(address token, uint256[] memory amounts, uint256[] memory dates) public payable {
      require(amounts.length == dates.length, 'Amount and date arrays have differing lengths');
      for (uint i=0; i<amounts.length; i++) {
        depositToken(token, amounts[i], dates[i]);
      }
    }

    function depositToken(address token, uint256 amount, uint256 unlock_date) public payable {
      require(unlock_date < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
      require(amount > 0, 'Your attempting to trasfer 0 tokens');
      uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
      require(allowance >= amount, 'You need to set a higher allowance');
      // charge a fee
      uint256 fee = calculateFee(amount);
      uint256 amountIn = amount.sub(fee);
      require(IERC20(token).transferFrom(msg.sender, address(this), amountIn), 'Transfer failed');
      require(IERC20(token).transferFrom(msg.sender, address(feeReserveAddress), fee), 'Transfer failed');
      if (!lockedTokenLookup[token]) {
        lockedTokens.push(token);
        lockedTokenLookup[token] = true;
      }
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[token];
      // amount is required to be above 0 in the start of this block, therefore this works
      if (liquidityTokenomics.releaseMap[unlock_date] > 0) {
        liquidityTokenomics.releaseMap[unlock_date] = liquidityTokenomics.releaseMap[unlock_date].add(amountIn);
      } else {
        liquidityTokenomics.epochs.push(unlock_date);
        liquidityTokenomics.releaseMap[unlock_date] = amountIn;
      }
      UserTokenInfo storage uto = tokenUserMap[token][msg.sender];
      uto.deposited = uto.deposited.add(amountIn);
      VestingPeriod[] storage vp = uto.vestingPeriods;
      vp.push(VestingPeriod(unlock_date, amountIn));
      
      emit onDeposit(token, amount, unlock_date);
    }

    function withdrawToken(address token, uint256 amount) public {
      require(amount > 0, 'Your attempting to withdraw 0 tokens');
      uint256 withdrawable = getWithdrawableBalance(token, msg.sender);
      UserTokenInfo storage uto = tokenUserMap[token][msg.sender];
      uto.withdrawn = uto.withdrawn.add(amount);
      require(amount <= withdrawable, 'Your attempting to withdraw more than you have available');
      require(IERC20(token).transfer(msg.sender, amount), 'Transfer failed');
      emit onWithdraw(token, amount);
    }

    function getWithdrawableBalance(address token, address user) public view returns (uint256) {
      UserTokenInfo storage uto = tokenUserMap[token][address(user)];
      uint arrayLength = uto.vestingPeriods.length;
      uint256 withdrawable = 0;
      for (uint i=0; i<arrayLength; i++) {
        VestingPeriod storage vestingPeriod = uto.vestingPeriods[i];
        if (vestingPeriod.epoch < block.timestamp) {
          withdrawable = withdrawable.add(vestingPeriod.amount);
        }
      }
      withdrawable = withdrawable.sub(uto.withdrawn);
      return withdrawable;
    }
    
    function getUserTokenInfo (address token, address user) public view returns (uint256, uint256, uint256) {
      UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
      uint256 deposited = uto.deposited;
      uint256 withdrawn = uto.withdrawn;
      uint256 length = uto.vestingPeriods.length;
      return (deposited, withdrawn, length);
    }

    function getUserVestingAtIndex (address token, address user, uint index) public view returns (uint256, uint256) {
      UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
      VestingPeriod storage vp = uto.vestingPeriods[index];
      return (vp.epoch, vp.amount);
    }

    function getTokenReleaseLength (address token) public view returns (uint256) {
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
      return liquidityTokenomics.epochs.length;
    }

    function getTokenReleaseAtIndex (address token, uint index) public view returns (uint256, uint256) {
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
      uint256 epoch = liquidityTokenomics.epochs[index];
      uint256 amount = liquidityTokenomics.releaseMap[epoch];
      return (epoch, amount);
    }
    
    function lockedTokensLength() external view returns (uint) {
        return lockedTokens.length;
    }
}