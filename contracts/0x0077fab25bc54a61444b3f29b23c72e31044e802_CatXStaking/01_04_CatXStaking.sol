// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom errors
error AprAlreadySet(uint256 _apr);
error InvalidApr();
error InvalidStakeDuration();
error StakingPeriodNotOver();
error NotEnoughTokensIntoStakingPool();
error NothingToWithdraw();

/**
 * @title CatX Staking (CATX) Granny said "Don't you dare GO to the Moon!" 
 * @author Blue$hip (aka Blue__Ship, ∞lue_ship; ∞lue_8hip; 8lue_Ship) with the assistant of the OpenAI gpt-4 model
 * @notice [email protected] Websites www.CatX.ai https://github.com/8lueShip/catx.ai Social Networks Telegram https://t.me/+S8_jaol3wvtlYzU0 Discord https://discord.gg/k3Z25ynY (Admin will NEVER Direct Message (DM) You). Legal disclaimer The information and content provided on this solidity script are intended for informational purposes only and do not constitute financial, investment, or other professional advice. Investing in cryptocurrencies, such as CATX, carries inherent risks, and users should conduct their own research and consult professional advisors before making any decisions. CATX and its team members disclaim any liability for any direct or indirect losses, damages, or consequences that may arise from the use of the information provided on this script. This disclaimer is governed by and construed in accordance with international law, and any disputes relating to this disclaimer shall be subject to the jurisdiction of the courts within which the offense was made. 
 * @dev CatX Staking
 */

contract CatXStaking is Ownable {

    // Custom events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event DepositStakingPool(uint256 amount);
    event AprUpdated(uint256 apr);
    event BulkAprUpdated(uint aprNinetyDays, uint aprOneEightyDays, uint aprThreeSixtyDays);
    event WithdrawStakingPool(uint256 amount);
    /* ========== STATE VARIABLES ========== */

    IERC20 public ercToken;
    uint64 private constant NinetyDaysInSeconds = 7776000;
    uint64 private constant OneEightyDaysInSeconds = 15552000;
    uint64 private constant ThreeSixtyDaysInSeconds = 31104000;

    // APR are in percentage
    uint256 public aprNinety = 400;
    uint256 public aprOneEighty = 600;
    uint256 public aprThreeSixty = 800;

    struct Stake {
        uint256 unlockTime;
        uint256 stakedAmount;
        uint256 userReward;
    }

    mapping(address => Stake) public stakesNinety;
    mapping(address => Stake) public stakesOneEighty;
    mapping(address => Stake) public stakesThreeSixty;

    uint256 public stakingPoolNinety;
    uint256 public stakingPoolOneEighty;
    uint256 public stakingPoolThreeSixty;


    /* ========== CONSTRUCTOR ========== */

    constructor(address _tokenAddress, address owner_ ) {
        transferOwnership(owner_);
        ercToken = IERC20(_tokenAddress);
    }


    /* ========== VIEW FUNCTIONS ========== */


    /**
     * @notice Returns the timestamp unlocking time of the user's stake
     * @param _user the address of the user
     * @param _stakingPeriod one of the three staking periods: 90, 180 or 360 days
     */
    function unlockTimeOf(address _user, uint256 _stakingPeriod) external view returns (uint256) {
        if (_stakingPeriod == 90) {
            return stakesNinety[_user].unlockTime;
        } else if (_stakingPeriod == 180) {
            return stakesOneEighty[_user].unlockTime;
        } else if (_stakingPeriod == 360) {
            return stakesThreeSixty[_user].unlockTime;
        } else {
            revert InvalidStakeDuration();
        }
    }

    /**
     * @notice Returns the amount of tokens that the user has staked
     * @param _user the address of the user
     * @param _stakingPeriod one of the three staking periods: 90, 180 or 360 days
     */
    function stakedAmountOf(address _user, uint256 _stakingPeriod) external view returns (uint256) {
        if (_stakingPeriod == 90) {
            return stakesNinety[_user].stakedAmount;
        } else if (_stakingPeriod == 180) {
            return stakesOneEighty[_user].stakedAmount;
        } else if (_stakingPeriod == 360) {
            return stakesThreeSixty[_user].stakedAmount;
        } else {
            revert InvalidStakeDuration();
        }
    }


    /* ========== SETTER FUNCTIONS ========== */

    /**
     * @notice Set the APR for the 90 days staking period
     * @param _apr the new APR
     */
    function setAprNinetyDays(uint256 _apr) external onlyOwner {
        if (_apr == 0)
            revert InvalidApr();
        if (aprNinety == _apr)
            revert AprAlreadySet(_apr);
        aprNinety = _apr;
        emit AprUpdated(_apr);
    }

    /**
     * @notice Set the APR for the 180 days staking period
     * @param _apr the new APR
     */
    function setAprOneEightyDays(uint256 _apr) external onlyOwner {
        if (_apr == 0)
            revert InvalidApr();
        if (aprOneEighty == _apr)
            revert AprAlreadySet(_apr);
        aprOneEighty = _apr;
        emit AprUpdated(_apr);
    }

    /**
     * @notice Set the APR for the 360 days staking period
     * @param _apr the new APR
     */
    function setAprThreeSixtyDays(uint256 _apr) external onlyOwner {
        if (_apr == 0)
            revert InvalidApr();
        if (aprThreeSixty == _apr)
            revert AprAlreadySet(_apr);
        aprThreeSixty = _apr;
        emit AprUpdated(_apr);
    }

    /**
     * @notice Set the APR for the 90, 180 and 360 days staking period
     * @param _aprNinetyDays the new APR for the 90 days staking period
     * @param _aprOneEightyDays the new APR for the 180 days staking period
     * @param _aprThreeSixtyDays the new APR for the 360 days staking period
     */
    function bulkSetApr(uint256 _aprNinetyDays, uint256 _aprOneEightyDays, uint256 _aprThreeSixtyDays) external onlyOwner {
        if (_aprNinetyDays == 0 || _aprOneEightyDays == 0 || _aprThreeSixtyDays == 0)
            revert InvalidApr();
        aprNinety = _aprNinetyDays;
        aprOneEighty = _aprOneEightyDays;
        aprThreeSixty = _aprThreeSixtyDays;
        emit BulkAprUpdated(_aprNinetyDays, _aprOneEightyDays, _aprThreeSixtyDays);
    }

    /**
     * @notice Deposit tokens into the 90 days staking pool
     * @param _amount the amount of tokens to deposit
     * @dev the tokens must be approved to this contract before calling this function
     */
    function depositStakingPoolNinetyDays(uint256 _amount) external onlyOwner {
        ercToken.transferFrom(msg.sender, address(this), _amount);

        stakingPoolNinety += _amount;
        emit DepositStakingPool(_amount);
    }

    /**
     * @notice Deposit tokens into the 180 days staking pool
     * @param _amount the amount of tokens to deposit
     * @dev the tokens must be approved to this contract before calling this function
     */
    function depositStakingPoolOneEightyDays(uint256 _amount) external onlyOwner {
        ercToken.transferFrom(msg.sender, address(this), _amount);

        stakingPoolOneEighty += _amount;
        emit DepositStakingPool(_amount);
    }

    /**
     * @notice Deposit tokens into the 360 days staking pool
     * @param _amount the amount of tokens to deposit
     * @dev the tokens must be approved to this contract before calling this function
     */
    function depositStakingPoolThreeSixtyDays(uint256 _amount) external onlyOwner {
        ercToken.transferFrom(msg.sender, address(this), _amount);

        stakingPoolThreeSixty += _amount;
        emit DepositStakingPool(_amount);
    }

    /**
     * @notice Withdraw tokens from the 90 days staking pool
     * @param _amount the amount of tokens to withdraw
     * @dev can only withdraw available tokens, this can't impact current staked and rewards
     */
    function withdrawStakingPoolNinetyDays(uint256 _amount) external onlyOwner {
        if (stakingPoolNinety < _amount)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolNinety -= _amount;
        ercToken.transfer(owner(), _amount);
        emit WithdrawStakingPool(_amount);
    }

    /**
     * @notice Withdraw tokens from the 180 days staking pool
     * @param _amount the amount of tokens to withdraw
     * @dev can only withdraw available tokens, this can't impact current staked and rewards
     */
    function withdrawStakingPoolOneEightyDays(uint256 _amount) external onlyOwner {
        if (stakingPoolOneEighty < _amount)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolOneEighty -= _amount;
        ercToken.transfer(owner(), _amount);
        emit WithdrawStakingPool(_amount);
    }

    /**
     * @notice Withdraw tokens from the 360 days staking pool
     * @param _amount the amount of tokens to withdraw
     * @dev can only withdraw available tokens, this can't impact current staked and rewards
     */
    function withdrawStakingPoolThreeSixtyDays(uint256 _amount) external onlyOwner {
        if (stakingPoolThreeSixty < _amount)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolThreeSixty -= _amount;
        ercToken.transfer(owner(), _amount);
        emit WithdrawStakingPool(_amount);
    }

    /* ========== WRITE FUNCTIONS ========== */

    /**
     * @notice Stake tokens for 90 days
     * @param _amount the amount of tokens to stake
     * @dev the tokens must be approved to this contract before calling this function
     */
    function stakeNinetyDays(uint256 _amount) external {
        if (stakingPoolNinety < _amount * aprNinety / 100 / 4)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolNinety -= _amount * aprNinety / 100 / 4;
        stakesNinety[msg.sender].unlockTime = block.timestamp + NinetyDaysInSeconds;
        stakesNinety[msg.sender].userReward += _amount * aprNinety / 100 / 4;
        stakesNinety[msg.sender].stakedAmount += _amount;

        ercToken.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Stake tokens for 180 days
     * @param _amount the amount of tokens to stake
     * @dev the tokens must be approved to this contract before calling this function
     */
    function stakeOneEightyDays(uint256 _amount) external {
        if (stakingPoolOneEighty < _amount * aprOneEighty / 100 / 2)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolOneEighty -= _amount * aprOneEighty / 100 / 2;
        stakesOneEighty[msg.sender].unlockTime = block.timestamp + OneEightyDaysInSeconds;
        stakesOneEighty[msg.sender].userReward += _amount * aprOneEighty / 100 / 2;
        stakesOneEighty[msg.sender].stakedAmount += _amount;

        ercToken.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Stake tokens for 360 days
     * @param _amount the amount of tokens to stake
     * @dev the tokens must be approved to this contract before calling this function
     */
    function stakeThreeSixtyDays(uint256 _amount) external {
        if (stakingPoolThreeSixty < _amount * aprThreeSixty / 100)
            revert NotEnoughTokensIntoStakingPool();

        stakingPoolThreeSixty -= _amount * aprThreeSixty / 100;
        stakesThreeSixty[msg.sender].unlockTime = block.timestamp + ThreeSixtyDaysInSeconds;
        stakesThreeSixty[msg.sender].userReward += _amount * aprThreeSixty / 100;
        stakesThreeSixty[msg.sender].stakedAmount += _amount;

        ercToken.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Withdraw both staked tokens and rewards from the 90 days staking pool
     * @dev can only withdraw after the unlock time
     */
    function withdrawNinetyDays() external {
        uint256 currentTime = block.timestamp;

        if(stakesNinety[msg.sender].stakedAmount == 0)
            revert NothingToWithdraw();

        if (currentTime <= stakesNinety[msg.sender].unlockTime)
            revert StakingPeriodNotOver();

        uint256 transferAmount = stakesNinety[msg.sender].stakedAmount + stakesNinety[msg.sender].userReward;
        stakesNinety[msg.sender].stakedAmount = 0;
        stakesNinety[msg.sender].userReward = 0;

        ercToken.transfer(msg.sender, transferAmount);

        emit Withdrawn(msg.sender, transferAmount);
    }

    /**
     * @notice Withdraw both staked tokens and rewards from the 180 days staking pool
     * @dev can only withdraw after the unlock time
     */
    function withdrawOneEightyDays() external {
        uint256 currentTime = block.timestamp;

        if(stakesOneEighty[msg.sender].stakedAmount == 0)
            revert NothingToWithdraw();

        if (currentTime <= stakesOneEighty[msg.sender].unlockTime)
            revert StakingPeriodNotOver();

        uint256 transferAmount = stakesOneEighty[msg.sender].stakedAmount + stakesOneEighty[msg.sender].userReward;
        stakesOneEighty[msg.sender].stakedAmount = 0;
        stakesOneEighty[msg.sender].userReward = 0;

        ercToken.transfer(msg.sender, transferAmount);

        emit Withdrawn(msg.sender, transferAmount);
    }

    /**
     * @notice Withdraw both staked tokens and rewards from the 360 days staking pool
     * @dev can only withdraw after the unlock time
     */
    function withdrawThreeSixtyDays() external {
        uint256 currentTime = block.timestamp;

        if(stakesThreeSixty[msg.sender].stakedAmount == 0)
            revert NothingToWithdraw();

        if (currentTime <= stakesThreeSixty[msg.sender].unlockTime)
            revert StakingPeriodNotOver();

        uint256 transferAmount = stakesThreeSixty[msg.sender].stakedAmount + stakesThreeSixty[msg.sender].userReward;
        stakesThreeSixty[msg.sender].stakedAmount = 0;
        stakesThreeSixty[msg.sender].userReward = 0;

        ercToken.transfer(msg.sender, transferAmount);

        emit Withdrawn(msg.sender, transferAmount);
    }
}