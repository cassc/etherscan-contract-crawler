// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStakingFactory.sol";
import "./USBStaking.sol";


contract USBStakingYield is Initializable, PausableUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev The USBStaking contract.
     */
    USBStaking public usbStaking;

    /** 
     * @dev address of yield reward token contract 
     */
    ERC20Upgradeable public yieldRewardToken;
   
    /**
     * @notice amount of reward token to be distribute for one block 
     * @dev [yieldRewardPerBlock]=yieldRewardToken/block
     */ 
    uint256 public yieldRewardPerBlock;

    /** 
     * @notice block number when staking starts
     * @dev [startBlock]=block
     */
    uint256 public startBlock;

    /**
     * @notice block number when staking ends
     * @dev [endBlock]=block
     */
    uint256 public endBlock;
   
    /**
     * @notice block number when latest reward was accrued
     * @dev [lastYieldRewardBlock]=block
     */
    uint256 public lastYieldRewardBlock;
    
    /**
     * @notice accumulated reward tokens per stake token. Accumulates with every update() call
     * @dev [accumulatedYieldRewardTokenPerStakeToken]=yieldRewardToken/stakeToken
     */
    uint256 public accumulatedYieldRewardTokenPerStakeToken;

    /**
     * @notice total pending reward token. If you want to get current pending reward call `getTotalPendingReward(0)`
     * @dev [totalPendingYieldReward]=rewardToken
     */
    uint256 public totalPendingYieldReward;

    /**
     * @notice total reward token claimed by stakers
     * @dev totalClaimedYieldReward = sum of all claimedReward by all users
     * @dev [totalClaimedYieldReward]=rewardToken
     */
    uint256 public totalClaimedYieldReward;
    
    /**
     * @notice user yield position
     * @dev user address => UserYieldPosition
     */
    mapping (address => UserYieldPosition) public userYieldPosition;

    struct UserYieldPosition {
        uint256 pendingYieldReward;
        uint256 claimedYieldReward;
        uint256 instantAccumulatedShareOfYieldReward;
    }

    event ClaimYieldReward(address indexed user, uint256 yieldRewardAmount);
    event SetYieldRewardPerBlock(uint256 yieldRewardPerBlock);
    event SetYieldPeriod(uint256 startBlock, uint256 endBlock);

    modifier onlyAdmin() {
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingYield: Caller is not the Admin");
        _;
    }

    modifier onlyManager() {
        bytes32 managerRole = usbStaking.MANAGER_ROLE();
        require(usbStaking.hasRole(managerRole, msg.sender), "USBStakingYield: Caller is not the Manager");
        _;
    }

    modifier onlyUsbStaking() {
        require(msg.sender == address(usbStaking), "USBStakingYield: Caller is not the Manager");
        _;
    }

    /**
     * @dev initializer of USBStakingYield
     * @param _usbStaking address of usbStaking
     * @param _yieldRewardToken address of yield token
     * @param _initialYieldReward the amount of reward token to be initial reward
     * @param _yieldRewardPerBlock the amount of reward to be distributed for one block
     * @param _startBlock the block number when staking starts
     * @param _endBlock the block number when staking ends
     */
    function initialize(
        address _usbStaking,
        address _yieldRewardToken,
        uint256 _initialYieldReward,
        uint256 _yieldRewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external initializer {
        __Pausable_init();

        usbStaking = USBStaking(_usbStaking);
        yieldRewardToken = ERC20Upgradeable(_yieldRewardToken);

        if(_initialYieldReward > 0) {
            yieldRewardToken.safeTransferFrom(msg.sender, address(this), _initialYieldReward);
        }

        _setYieldRewardPerBlock(_yieldRewardPerBlock);
        _setYieldPeriod(_startBlock, _endBlock);
    }

    //************* ADMIN FUNCTIONS *************//

    /**
     * @dev transfer any tokens from yield staking
     * @param _token address of token to be transferred
     * @param _recipient address of receiver of tokens
     * @param _amount amount of token to be transferred
     */
    function sweepTokens(address _token, address _recipient, uint256 _amount) external onlyAdmin {
        require(_amount > 0, "USBStaking: amount=0");
        ERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
    }

    /**
     * @dev pause yield rewarding
     */
    function pause() external onlyAdmin {
        update();
        super._pause();
    }
   
    /**
     * @dev unpause yield rewarding
     */
    function unpause() external onlyAdmin {
        lastYieldRewardBlock = block.number;
        super._unpause();
    }

    //************* END ADMIN FUNCTIONS *************//
    //************* MANAGER FUNCTIONS *************//

    /**
     * @dev sets yield reward per block
     * @param _yieldRewardPerBlock amount of `yieldRewardToken` to be rewarded each block
     */
    function setYieldRewardPerBlock(uint256 _yieldRewardPerBlock) external onlyManager {
        _setYieldRewardPerBlock(_yieldRewardPerBlock);
    }

    /**
     * @dev sets yield reward per block
     * @param _yieldRewardPerBlock amount of `yieldRewardToken` to be rewarded each block
     */
    function _setYieldRewardPerBlock(uint256 _yieldRewardPerBlock) internal {
        update();
        yieldRewardPerBlock = _yieldRewardPerBlock;
        emit SetYieldRewardPerBlock(_yieldRewardPerBlock);
    }

    /**
     * @dev sets period of yield rewarding
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setYieldPeriod(uint256 _startBlock, uint256 _endBlock) external onlyManager {
        _setYieldPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets period of yield rewarding
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function _setYieldPeriod(uint256 _startBlock, uint256 _endBlock) internal {
        require(_startBlock < _endBlock, "USBStakingYield: should be startBlock<endBlock");
        startBlock = _startBlock;
        endBlock = _endBlock;
        emit SetYieldPeriod(_startBlock, _endBlock);
    }

    //************* END MANAGER FUNCTIONS *************//
    //************* MAIN FUNCTIONS *************//

    /**
     * @dev update the `accumulatedYieldRewardTokenPerStakeToken`
     */
    function update() public whenNotPaused {
        if (block.number <= lastYieldRewardBlock) {
            return;
        }
        uint256 totalStaked = usbStaking.totalStake();
        if (totalStaked == 0) {
            lastYieldRewardBlock = block.number;
            return;
        }
        uint256 rewardAmount = calculateTotalPendingYieldReward(0);
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        accumulatedYieldRewardTokenPerStakeToken += rewardAmount * accumulatorMultiplier / totalStaked;
        totalPendingYieldReward += rewardAmount;
        lastYieldRewardBlock = block.number;
    }

    /**
     * @dev update the `pendingYieldReward`
     * @param user address of user
     */
    function updatePendingYieldReward(address user) external onlyUsbStaking {
        _updatePendingYieldReward(user);
    }

    /**
     * @dev update the `pendingYieldReward`
     * @param user address of user
     */
    function _updatePendingYieldReward(address user) internal {
        UserYieldPosition storage userYield = userYieldPosition[user];
        uint256 accumulatedShareOfYieldReward = getAccumulatedShareOfYieldReward(user);
        if (accumulatedShareOfYieldReward > userYield.instantAccumulatedShareOfYieldReward){
            userYield.pendingYieldReward += accumulatedShareOfYieldReward - userYield.instantAccumulatedShareOfYieldReward;
        }
    }
    
    /**
     * @dev update the `instantAccumulatedShareOfYieldReward`
     * @param user address of user
     */
    function updateInstantAccumulatedShareOfYieldReward(address user) external onlyUsbStaking {
        _updateInstantAccumulatedShareOfYieldReward(user);
    }
    
    /**
     * @dev update the `instantAccumulatedShareOfYieldReward`
     * @param user address of user
     */
    function _updateInstantAccumulatedShareOfYieldReward(address user) internal {
        userYieldPosition[user].instantAccumulatedShareOfYieldReward = getAccumulatedShareOfYieldReward(user);
    }

    /**
     * @notice claim the yield reward to `msg.sender`
     */
    function claimYieldReward() external whenNotPaused {
        update();
        _updatePendingYieldReward(msg.sender);
        _updateInstantAccumulatedShareOfYieldReward(msg.sender);
        UserYieldPosition storage userYield = userYieldPosition[msg.sender];
        uint256 pendingYieldReward = userYield.pendingYieldReward;
        if (pendingYieldReward > 0) {
            totalClaimedYieldReward += pendingYieldReward;
            userYield.claimedYieldReward += pendingYieldReward;
            userYield.pendingYieldReward = 0;
            _safeYieldRewardTokenTransfer(msg.sender, pendingYieldReward);
            emit ClaimYieldReward(msg.sender, pendingYieldReward);
        }
    }

    /**
     * @notice claim the yield reward to user address
     * @param beneficiary the address of user
     */
    function claimYieldRewardTo(address beneficiary) external onlyUsbStaking whenNotPaused {
        update();
        _updatePendingYieldReward(beneficiary);
        _updateInstantAccumulatedShareOfYieldReward(beneficiary);
        UserYieldPosition storage userYield = userYieldPosition[beneficiary];
        uint256 pendingYieldReward = userYield.pendingYieldReward;
        if (pendingYieldReward > 0) {
            totalClaimedYieldReward += pendingYieldReward;
            userYield.claimedYieldReward += pendingYieldReward;
            userYield.pendingYieldReward = 0;
            _safeYieldRewardTokenTransfer(beneficiary, pendingYieldReward);
            emit ClaimYieldReward(beneficiary, pendingYieldReward);
        }
    }

    /**
     * @dev internal transfer of yield reward token
     * @param beneficiar address of receiver
     * @param amount amount of reward token `beneficiar` will receive
     */
    function _safeYieldRewardTokenTransfer(address beneficiar, uint256 amount) internal {
        uint256 yieldTokenBalance = getYieldRewardTokenAmount();
        if (amount > yieldTokenBalance) {
            yieldRewardToken.safeTransfer(beneficiar, yieldTokenBalance);
            uint256 shortfall = amount - yieldTokenBalance;
            totalClaimedYieldReward -= shortfall;
            userYieldPosition[beneficiar].claimedYieldReward -= shortfall;
            userYieldPosition[beneficiar].pendingYieldReward += shortfall;
        } else {
            yieldRewardToken.safeTransfer(beneficiar, amount);
        }
    }
    
    //************* END MAIN FUNCTIONS *************//
    //************* VIEW FUNCTIONS *************//

    /**
     * @dev return the share of reward of `user` by his stake
     */
    function getAccumulatedShareOfYieldReward(address user) public view returns (uint256) {
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        (uint256 userStake,,,) = usbStaking.userPosition(user);
        return userStake * accumulatedYieldRewardTokenPerStakeToken / accumulatorMultiplier;
    }
    
    /**
     * @dev calculates the pending reward from `lastRewardBlock` to current block + `blocks`
     * @param blocks the number of blocks to get the pending reward
     */
    function calculateTotalPendingYieldReward(uint256 blocks) public view returns (uint256) {
        uint256 blockDelta = getBlockDelta(lastYieldRewardBlock, block.number + blocks);
        return blockDelta * yieldRewardPerBlock;
    }

    /**
     * @dev return sum of all rewardsPerBlock to current block + `blocks`
     * @param blocks the number of blocks
     */
    function getTotalPendingYieldReward(uint256 blocks) public view returns (uint256) {
        return totalPendingYieldReward + calculateTotalPendingYieldReward(blocks);
    }

    /**
     * @dev return the unclaimed rewards amount
     */
    function getUnclaimedRewardAmount() external view returns (uint256 unclaimedYieldRewards) {
        uint256 _totalPendingYieldReward = getTotalPendingYieldReward(0);
        if (_totalPendingYieldReward >= totalClaimedYieldReward) {
            unclaimedYieldRewards = _totalPendingYieldReward - totalClaimedYieldReward;
        }
    }

    /**
     * @dev return the amount of reward token on contract
     */
    function getYieldRewardTokenAmount() public view returns (uint256) {
        return yieldRewardToken.balanceOf(address(this));
    }
    
    /** 
     * @dev return reward blockDelta over the given `from` to `to` block 
     */
    function getBlockDelta(uint256 from, uint256 to) public view returns (uint256 blockDelta) {
        require (from <= to, "USBStakingYield: incorrect from/to sequence");
        uint256 _startBlock = startBlock;
        uint256 _endBlock = endBlock;
        if (_startBlock == 0 || to <= _startBlock || from >= _endBlock) {
            return 0;
        }
        uint256 lastBlock = to <= _endBlock ? to : _endBlock;
        uint256 firstBlock = from >= _startBlock ? from : _startBlock;
        blockDelta = lastBlock - firstBlock;
    }

    /**
     * @dev return user position as (total yield rewarded, intime pending reward)
     */
    function getUserYieldPosition(address user) external view returns (uint256 userClaimedYieldReward, uint256 userPendingYieldReward) {
        UserYieldPosition memory userYield = userYieldPosition[user];
        (uint256 userStake,,,) = usbStaking.userPosition(user);
        uint256 totalStaked = usbStaking.totalStake();
        uint256 accumulatedYieldRewardTokenPerStakeTokenLocal = accumulatedYieldRewardTokenPerStakeToken;
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        userPendingYieldReward = userYield.pendingYieldReward;
        if (block.number > lastYieldRewardBlock && totalStaked != 0) {
            uint256 blockDelta = getBlockDelta(lastYieldRewardBlock, block.number);
            uint256 rewardAmount = blockDelta * yieldRewardPerBlock;
            accumulatedYieldRewardTokenPerStakeTokenLocal += rewardAmount * accumulatorMultiplier / totalStaked;
            uint256 accumulatedShareOfReward = userStake * accumulatedYieldRewardTokenPerStakeTokenLocal / accumulatorMultiplier;
            if (accumulatedShareOfReward > userYield.instantAccumulatedShareOfYieldReward) {
                userPendingYieldReward += accumulatedShareOfReward - userYield.instantAccumulatedShareOfYieldReward;
            }
        }
        return (userYield.claimedYieldReward, userPendingYieldReward);
    }

    /**
     * @dev returns the accumulator multiplier for accumulatedYieldRewardTokenPerStakeToken
     */
    function getAccumulatorMultiplier() public view returns (uint256 accumulatorMultiplier) {
        uint8 stakeTokenDecimals = usbStaking.stakeToken().decimals();
        uint8 yieldRewardTokenDecimals = yieldRewardToken.decimals();
        if (stakeTokenDecimals >= yieldRewardTokenDecimals){
            accumulatorMultiplier = 10 ** (12 + stakeTokenDecimals - yieldRewardTokenDecimals);
        } else {
            accumulatorMultiplier =  10 ** stakeTokenDecimals;
        }
    }

    //************* END VIEW FUNCTIONS *************//

}