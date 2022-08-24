// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ISpumeStaking } from "./interfaces/ISpumeStaking.sol";
import { SpumeStaking } from "./SpumeStaking.sol"; 
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract SpumeRewardPool is ReentrancyGuard, Ownable, Pausable {
  // Varriables
  using SafeERC20 for IERC20;
  IERC20 public s_rewardsToken;
  IERC20 public s_stakingToken;
  IERC20 public weth;
  ISpumeStaking public spumeStaking; 
  uint256 public rewardTokenBalance;
  uint256 public poolDistributionTotal; 
  uint256 public constant rewardRate = 100000000; 
  uint256 public createdAt; 
  uint256 public rewardRound;

  // Mappings
  mapping(address => uint256) public lastRewardRoundClaimed;
  mapping(address => bool) public depositor;

  // Events 
  event Deposited(uint256 indexed amount);
  event RewardSwap(address indexed user, uint256 indexed rewardTokenAmount, uint256 indexed wethAmount); 
  event RewardClaimAndSwap(address indexed user, uint256 indexed rewardTokenAmount, uint256 indexed wethAmount);

  constructor(address stakingToken, address rewardsToken, address Weth, address _spumeStaking) { 
    s_stakingToken = IERC20(stakingToken); 
    s_rewardsToken = IERC20(rewardsToken); 
    weth = IERC20(Weth); 
    spumeStaking = ISpumeStaking(_spumeStaking);
    createdAt = spumeStaking.getCreatedAt();
    depositor[msg.sender] = true; 
  }

  /*
   * @dev Deposits wETH to contract. 
   */ 
  function deposit(uint256 amount) external whenNotPaused {
    require(depositor[msg.sender] == true, "Not Authorized to make deposit"); 
    poolDistributionTotal += (amount);
    rewardRound += 1;
    emit Deposited(amount);
    weth.safeTransferFrom(msg.sender, address(this), amount); 
  }

  /*
   * @dev returns the reward per token 
   */
  function getRewardPerToken() public view returns (uint256){
    return poolDistributionTotal / (((block.timestamp - createdAt) * rewardRate) - rewardTokenBalance);
  }

  /*
   * @notice Swap rewardTokens from user if already claimed 
   * @param _rewardTokenAmount | Number of reward tokens user is swapping
   */
  function rewardSwap(uint256 _rewardTokenAmount) external nonReentrant whenNotPaused{ 
    require(lastRewardRoundClaimed[msg.sender] < rewardRound, "User already claimed this round");
    require(_rewardTokenAmount > 0, "Cannot Swap 0 Tokens");
    uint256 rewardAmount = getRewardPerToken() * _rewardTokenAmount;
    rewardTokenBalance += _rewardTokenAmount;
    poolDistributionTotal -= rewardAmount;
    lastRewardRoundClaimed[msg.sender] = rewardRound;
    emit RewardSwap(msg.sender, _rewardTokenAmount, rewardAmount);
    s_rewardsToken.safeTransferFrom(msg.sender, address(this), _rewardTokenAmount); 
    weth.safeTransfer(msg.sender, rewardAmount); 
  }

  /*
   * @notice Claim rewardTokens from Staking Contract and Swap for wETH 
   */
  function rewardClaimAndSwap() external nonReentrant whenNotPaused{
    require(lastRewardRoundClaimed[msg.sender] < rewardRound, "User already claimed this round");
    uint256 _rewardTokenAmount = spumeStaking.claimReward(msg.sender);
    require(_rewardTokenAmount > 0, "Cannot Swap 0 Tokens");
    uint256 rewardAmount = getRewardPerToken() * _rewardTokenAmount;
    rewardTokenBalance += _rewardTokenAmount;
    poolDistributionTotal -= rewardAmount;
    lastRewardRoundClaimed[msg.sender] = rewardRound;
    emit RewardClaimAndSwap(msg.sender, _rewardTokenAmount, rewardAmount);
    s_rewardsToken.safeTransferFrom(msg.sender, address(this), _rewardTokenAmount);
    weth.safeTransfer(msg.sender, rewardAmount);
  }

  /*
   * @notice Set new depositor address for Contract 
   */
  function setDepositor(address newDepositor) external onlyOwner {
    depositor[newDepositor] = true; 
  }

  /*
   * @notice Remove depositor address for Contract 
   */
  function removeDepositor(address newDepositor) external onlyOwner {
    depositor[newDepositor] = false; 
  }

  /*
   * @notice Pauses Contract 
   */
  function pauseRewardPool() external onlyOwner whenNotPaused {
    _pause(); 
  }

  /*
   * @notice Unpauses Contract 
   */
  function unPauseRewardPool() external onlyOwner whenPaused {
    _unpause(); 
  }

  /*
   * @notice Emergency Transfer of WETH can only be called when contract is paused 
   * @dev retreive WETH from contract only if paused 
   * @param amount | The amount of weth to emergency transfer
   */
  function EmergencyTransferWETH(uint256 amount) external onlyOwner whenPaused {
    poolDistributionTotal -= amount;
    weth.safeTransfer(msg.sender, amount);
  }
}