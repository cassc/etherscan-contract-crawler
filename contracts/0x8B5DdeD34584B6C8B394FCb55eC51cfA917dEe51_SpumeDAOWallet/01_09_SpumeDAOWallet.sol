// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import { ISpumeStaking } from "./interfaces/ISpumeStaking.sol";
import { ISpumeRewardPool } from "./interfaces/ISpumeRewardPool.sol";


/*
 * @title SpumeDAOWallet for custody for the Spume DAO
 * @dev This contract handles the custody and staking of SPUME ERC20 tokens. 
 */
contract SpumeDAOWallet is Pausable, Ownable {
    //Varriables 
    using SafeERC20 for IERC20;
    IERC20 public spumeToken;
    IERC20 public rewardToken;
    IERC20 public WETH;  
    uint256 private spumeTotal;
    ISpumeStaking public spumeStaking;
    ISpumeRewardPool public spumeRewardPool;
    uint256 public lastPausedTimestamp;
    uint256 MAX_UINT = 2**256 - 1; 

    /*
     * @dev Sets the Address of Spume Token, WETH, RewardPool contract and Staking Contract.
     */
    constructor(
        address _spumeToken,
        address _rewardToken,
        address _spumeStaking,
        address _spumeRewardPool,
        address _WETH
    ) {
        spumeStaking = ISpumeStaking(_spumeStaking);
        spumeRewardPool = ISpumeRewardPool(_spumeRewardPool);
        spumeToken = IERC20(_spumeToken); 
        rewardToken = IERC20(_rewardToken);
        WETH = IERC20(_WETH); 
    }

    /*
     * @dev Deposit Spume Tokens 
     */
    function depositSpume(uint256 amount) external onlyOwner whenNotPaused returns(uint256) {
        spumeToken.transferFrom(msg.sender, address(this), amount); 
        return(amount); 
    }

    /*
     * @notice Transfer SPUME tokens back to owner
     * @dev It is for emergency purposes. Only for owner.
     * @param amount amount to withdraw
     */
    function withdrawSpume(uint256 amount) external onlyOwner whenPaused {
        require(amount > 0, "Cannot Withdraw 0");
        spumeToken.safeTransfer(msg.sender, amount);
    }

    /*
     * @notice Stake Spume Tokens  
     */
    function stakeSpume(uint256 amount) external whenNotPaused onlyOwner returns(uint256){
        spumeToken.approve(address(spumeStaking), amount);
        spumeStaking.stake(amount);
        return(amount);
    }

    /*
     * @notice Unstake Spume Tokens 
     */
    function unstakeSpume(uint256 amount) external whenNotPaused onlyOwner returns(uint256){
        spumeStaking.unstake(amount);
        return(amount);
    }

    /*
     * @notice Claim Staking Rewards 
     */
    function claimAndSwapRewards() external whenNotPaused onlyOwner {
        rewardToken.approve(address(spumeRewardPool), MAX_UINT);
        spumeRewardPool.rewardClaimAndSwap();
    }

    /*
     * @notice Withdraw WETH Rewards from contract 
     */
    function withdrawWeth(uint256 amount) external whenNotPaused onlyOwner returns(uint256) {
        require(amount > 0, "WETH Amount must be greater than 0"); 
        WETH.transfer(msg.sender, amount);
        return(amount);
    }

    /*
     * @notice Pauses Contract 
     */
    function pauseWallet() external onlyOwner whenNotPaused {
        lastPausedTimestamp = block.timestamp; 
        _pause(); 
    }

    /*
     * @notice Unpauses Contract 
     */
    function unPauseWallet() external onlyOwner whenPaused {
        _unpause(); 
    }
}