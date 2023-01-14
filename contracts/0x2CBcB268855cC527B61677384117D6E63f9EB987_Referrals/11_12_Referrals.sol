// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

interface IVestingRewards {
  function createRewardWallet(
    address beneficiary,
    uint256 lockup,
    uint256 start,
    uint256 end,
    uint256 periods,
    uint256 amount
  ) external;
} 

interface ILock {
  function getStageEnd(uint8 _numStage) external view returns(uint256);
  function getRate() external view returns(uint256);
}

interface ICalc {
  function getClaimRewards(uint256 amount) external view returns (uint);
  function getVestingRewards(uint256 amount, uint256 rate) external view returns (uint);
}

contract Referrals is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Metadata;

  struct Stage {
    uint256 start;
    uint256 end;
    uint256 amount;
    uint256 price;
  }

  uint256 public immutable VESTING_PERIOD = 2592000; // 30 days in seconds
  uint8 public claimStage;
  uint8 public lockup;
  uint8 public vesting;
 
  // referral => stage => amount of nft minted
  mapping(address => mapping(uint8 => uint256)) public refStageMints;
  mapping(address => uint256) public refClaims;
  mapping(address => uint256) public refVests;

  mapping(address => bool) internal admins;

  ILock public lockContract;

  // Payment token (USDT)
  IERC20Metadata public paymentToken;

  address public tokenWallet;

  IVestingRewards public vestingRewards;

  ICalc public calc;

  event RewardClaimed(address sender, uint256 claimAmount, uint256 vestAmount, uint256 timestamp); 
  event LockContractChanged(address newContract);
  event VestingRewardsContractChanged(address newVestingRewardsContract);
  event CalcContractChanged(address newCalcContract);
  event TokenWalletChanged(address wallet);

  modifier onlyAdmin() {
    require(admins[msg.sender], "Caller is not admin");
    _;
  }

  constructor(address _paymentToken, address _tokenWallet) {
    paymentToken = IERC20Metadata(_paymentToken);
    tokenWallet = _tokenWallet;
    addAdmin(msg.sender);
  }

  function claimRewards() public whenNotPaused nonReentrant {
    uint256 rate = lockContract.getRate();
    uint256 totalAmount = getTotalAmount(msg.sender, claimStage);
    uint256 claimAmount = getClaimRewards(msg.sender, totalAmount);
    require(claimAmount > 0, "Nothing to claim");
    uint256 stageEnd = lockContract.getStageEnd(claimStage); 
    require((stageEnd > 0) && (stageEnd < block.timestamp), "Stage not finished");
    paymentToken.safeTransferFrom(tokenWallet, msg.sender, claimAmount);
    refClaims[msg.sender] = refClaims[msg.sender].add(claimAmount);
    uint256 vestingAmount = getVestingRewards(msg.sender, totalAmount, rate); 
    uint256 start = block.timestamp + lockup * VESTING_PERIOD; 
    uint256 end = start + vesting * VESTING_PERIOD; 
    vestingRewards.createRewardWallet(msg.sender, block.timestamp, start, end, vesting, vestingAmount);
    refVests[msg.sender] = refVests[msg.sender].add(vestingAmount);

    emit RewardClaimed(msg.sender, claimAmount, vestingAmount, block.timestamp); 
  }

  function getClaimRewards(address _referral, uint256 _totalAmount) public view returns(uint256) {
    return calc.getClaimRewards(_totalAmount).sub(refClaims[_referral]);
  }

  function getVestingRewards(address _referral, uint256 _totalAmount, uint256 _rate) public view returns(uint256) {
    return calc.getVestingRewards(_totalAmount, _rate).sub(refVests[_referral]);
  }

  function getTotalAmount(address _referral, uint8 _stage) public view returns(uint256) {
    if (_stage == 0) {
      return 0;
    }
    uint256 amount;
    for (uint8 i = 1; i <= _stage; i++) {
      amount = amount + refStageMints[_referral][i];
    }
    return amount;
  }

  function getRefStageMints(address _referral, uint8 _stage) external view returns(uint256) {
    return refStageMints[_referral][_stage];
  }

  function setRefStageMints(address _referral, uint8 _stage, uint256 _amount) external onlyOwner {
    refStageMints[_referral][_stage] = _amount;
  }

  function setRefStageMintsArr(address[] memory _referrals, uint8[] memory _stages, uint256[] memory _amounts) external onlyOwner {
    for (uint i = 0; i < _referrals.length; i++) {
      refStageMints[_referrals[i]][_stages[i]] = _amounts[i];
    }
  }

  function getRefClaims(address _referral) external view returns (uint256) {
    return refClaims[_referral];
  }

  function getRefVests(address _referral) external view returns (uint256) {
    return refVests[_referral];
  }
  
  function getClaimStage() external view returns(uint8) {
    return claimStage;
  }

  function setClaimStage(uint8 _stage) external onlyOwner {
    claimStage = _stage;
  }

  function setLockup(uint8 _lockup) external onlyOwner {
    lockup = _lockup;
  }

  function getLockup() external view returns(uint8) {
    return lockup;
  }

  function setVesting(uint8 _vesting) external onlyOwner {
    vesting = _vesting;
  }

  function getVesting() external view returns(uint8) {
    return vesting;
  }

  function setLockContract(address newContract) external onlyOwner {
    lockContract = ILock(newContract);
    emit LockContractChanged(newContract);
  }

  function setVestingRewardsContract(address newVestingRewardsContract) external onlyOwner {
    vestingRewards = IVestingRewards(newVestingRewardsContract);
    emit VestingRewardsContractChanged(newVestingRewardsContract);
  }

  function setCalcContract(address newCalcContract) external onlyOwner {
    calc = ICalc(newCalcContract);
    emit CalcContractChanged(newCalcContract);
  }

  function setTokenWallet(address _wallet) external onlyOwner {
		tokenWallet = _wallet;
    emit TokenWalletChanged(tokenWallet);
	}

  function getTokenWallet() external view returns(address) {
    return tokenWallet;
  }

  function addAdmin(address _admin) public onlyOwner {
    admins[_admin] = true;
  }

  function removeAdmin(address _admin) external onlyOwner {
    admins[_admin] = false;
  }

  function isAdmin(address _acount) external view returns(bool) {
    return admins[_acount];
  }

  receive() external payable {
      revert();
  }

  fallback() external payable {
      revert();
  }
}