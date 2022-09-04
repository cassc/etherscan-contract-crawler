// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityMiningLogic is AccessControl {
    struct MarketState {
        uint256 index; // sum of reward_at_block_i / total_stake_at_block_i (i is the block number) before the current block
        uint256 lastBlockNum;
        uint256 epoch;
    }
    using SafeERC20 for IERC20;
    enum STAGE { NO_REWARD_PERIOD, COLD_START, AFTER_COLD_START, END_REWARD_PERIOD}


    uint256 constant MAX_INT = type(uint256).max;
    // every week, the reward per block will be decreased by 4 percent, so we need this constant
    uint256 constant BLOCKS_PER_WEEK = 6000 * 7;
    uint256 public rewardSpeed;
    uint256 public totalStake;
    uint256 public endColdStartBlockNum;
    uint256 public admin_speed;
    uint256 public totalRewardAccrued;
    bool public emergency;

    STAGE public contract_stage;
    MarketState public marketState;
    IERC20 public immutable DFI;

    mapping(address => uint256) public stakingMap;
    mapping(address => uint256) public rewardAccrueds;
    mapping(address => uint256) public recipientIndexes;

    event REWARD_CLAIMED(
        address indexed recipient,
        uint256 amount,
        bool hasDFILeft
    );
    event LIQUIDITY_ADDED(address indexed user, uint256 liquidityAdded);
    event LIQUIDITY_REMOVED(address indexed user, uint256 liquidityRemoved);

    constructor(address _DFI, uint256 _admin_speed) {
        DFI = IERC20(_DFI);
        marketState = MarketState({
            index: 0,
            lastBlockNum: block.number,
            epoch: 0
        });
        admin_speed = _admin_speed;
        contract_stage = STAGE.NO_REWARD_PERIOD;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice Update the sum of reward per stake up to before the current block
     * (by leveraging the periods of constant total stake)
     * State vars to be updated: 
     * - rewardSpeed
     * - marketState.index 
     * - marketState.epoch
     * - marketState.lastBlockNum
     * - totalRewardAccrued
     */
    function _updateRewardIndex() internal {
        uint256 blockNumber = block.number;
        uint256 rewardAccrued;
        if (contract_stage == STAGE.COLD_START) {
            rewardAccrued =
                rewardSpeed *
                (blockNumber - marketState.lastBlockNum);
        } else if (contract_stage == STAGE.AFTER_COLD_START) {
            uint256 updateEpoch = (blockNumber - endColdStartBlockNum) /
                BLOCKS_PER_WEEK;
            if (updateEpoch > marketState.epoch) {
                uint256 checkPoint = (marketState.epoch + 1) *
                    BLOCKS_PER_WEEK +
                    endColdStartBlockNum;
                uint256 rewardAccruedBeforeFirstEpochEnds = rewardSpeed *
                    (checkPoint - marketState.lastBlockNum);
                checkPoint += BLOCKS_PER_WEEK;
                uint256 _rewardSpeed = rewardSpeed;
                while (checkPoint <= blockNumber) {
                    _rewardSpeed = (_rewardSpeed * 96) / 100;
                    rewardAccrued += _rewardSpeed * BLOCKS_PER_WEEK;
                    checkPoint += BLOCKS_PER_WEEK;
                }
                _rewardSpeed = (_rewardSpeed * 96) / 100;
                uint256 rewardAccruedInTheFinalEpoch = _rewardSpeed *
                    (blockNumber + BLOCKS_PER_WEEK - checkPoint);
                rewardAccrued +=
                    rewardAccruedBeforeFirstEpochEnds +
                    rewardAccruedInTheFinalEpoch;
                marketState.epoch = updateEpoch;
                rewardSpeed = _rewardSpeed;
            } else
                rewardAccrued =
                    rewardSpeed *
                    (blockNumber - marketState.lastBlockNum);
        }
        
        marketState.lastBlockNum = blockNumber;
        if (totalStake != 0) {
            marketState.index += (rewardAccrued * 1e18) / totalStake;
            totalRewardAccrued += rewardAccrued;
        }
    }

    /**
     * @notice Update the accrued reward of a recipient
     * @param recipient The recipient of the reward
     */
    function _distributeRewards(address recipient) internal {
        uint256 marketIndex = marketState.index;
        uint256 deltaIndex = marketIndex - recipientIndexes[recipient];
        recipientIndexes[recipient] = marketIndex;

        uint256 recipientDelta = (stakingMap[recipient] * deltaIndex) / 1e18;
        rewardAccrueds[recipient] += recipientDelta;
    }

    /**
     * @notice used to update the reward index and
     * and update the reward accrued of the recipient
     * @param recipient the recipient of the reward
     */
    function beforeHook(address recipient) public notInEmergency {
        // if beforeHook fails, addliquidity/ removeliquidity functions will fail (except for removeLiquidity that is enabled in emergency mode)
        // and claimRewards will also fail
        // calculate the index up to before the current block
        _updateRewardIndex();
        // distribute reward to the recipient (reward is calculated up to before the current block)
        _distributeRewards(recipient);
    }

    /**
     * @notice Claim rewards and transfer these DFI rewards to recipient
     * anyone can call this function
     * @param recipient the recipient of the reward
     */
    function claimRewards(address recipient) external {
        beforeHook(recipient);
        _claimRewards(recipient);
    }

    /**
     * @notice internal function to claim rewards
     * @param recipient the recipient of the DFI rewards
     */
    function _claimRewards(address recipient) internal {
        if (rewardAccrueds[recipient] == 0) return;
        uint256 proxyBalance = DFI.balanceOf(address(this));
        if (proxyBalance == 0) return;
        if (proxyBalance > rewardAccrueds[recipient]) {
            uint256 rewardToTransfer = rewardAccrueds[recipient];
            rewardAccrueds[recipient] = 0;
            DFI.safeTransfer(recipient, rewardToTransfer);
            emit REWARD_CLAIMED(recipient, rewardToTransfer, true);
        } else {
            rewardAccrueds[recipient] -= proxyBalance;
            DFI.safeTransfer(recipient, proxyBalance);
            emit REWARD_CLAIMED(recipient, proxyBalance, false);
        }
    }

    /**
     * @notice internal function to add liquidity
     * @param requester requester of the addition of liquidity
     * @param liquidity the LP tokens added to the smart contract
     */
    function _addLiquidity(address requester, uint256 liquidity) internal {
        stakingMap[requester] += liquidity;
        totalStake += liquidity;
    }

    /**
     * @notice internal function to remove liquidity
     * @param requester requester of the removal of liquidity
     * @param liquidity the LP tokens to be removed from the smart contract
     */
    function _removeLiquidity(address requester, uint256 liquidity) internal {
        stakingMap[requester] -= liquidity;
        totalStake -= liquidity;
    }

    /**
     * @notice Enter Emergency mode, in case our rewardMechanism fails
     */
    function enterEmergencyMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emergency = true;
        DFI.safeTransfer(msg.sender, DFI.balanceOf(address(this)));
    }

    /**
     * @notice For the contract to enter the next stage 
     * 1. enter stage COLD_START when we want to start accruing liquidity mining rewards to users (1%)
     * 2. enter stage AFTER_COLD_START when we want to start normal liquidity mining campaign
     * 3. enter stage END_REWARD_PERIOD when we want to end the accrual of Liquidity Mining rewards to users,
     */
    function enterNextStage() external notInEmergency onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateRewardIndex();
        if (contract_stage == STAGE.NO_REWARD_PERIOD) { 
            rewardSpeed = admin_speed/100;
            contract_stage = STAGE.COLD_START;
        }
        else if (contract_stage == STAGE.COLD_START) {
            rewardSpeed = admin_speed;
            endColdStartBlockNum = block.number;
            contract_stage = STAGE.AFTER_COLD_START;            
        }
        else if (contract_stage == STAGE.AFTER_COLD_START) {
            rewardSpeed = 0;
            contract_stage = STAGE.END_REWARD_PERIOD;
        }
    }

    /**
     * @notice modifier in case of emergency
     */
    modifier notInEmergency() {
        require(!emergency, "In emergency mode now");
        _;
    }

    /**
    * @notice a function to check reward related matters of the contract
    * @param recipient the address we want to check the reward on
    * @return _rewardForRecipient an estimate of reward claimable by a recipient up till now
    * @return _totalRewardAccrued an estimate of totalReward that the contract accrue to all of its users (including the tokens that have been claimed by users)
    */ 
    function checkReward(address recipient) external view returns(uint256 _rewardForRecipient, uint256 _totalRewardAccrued) {
        uint256 blockNumber = block.number;
        uint256 rewardAccrued;
        uint256 _rewardSpeed = rewardSpeed;
        uint256 _marketIndex = marketState.index;
        _totalRewardAccrued = totalRewardAccrued;

        if (contract_stage == STAGE.COLD_START) {
            rewardAccrued =
                _rewardSpeed *
                (blockNumber - marketState.lastBlockNum);
        } else if (contract_stage == STAGE.AFTER_COLD_START) {
            uint256 updateEpoch = (blockNumber - endColdStartBlockNum) /
                BLOCKS_PER_WEEK;
            if (updateEpoch > marketState.epoch) {
                uint256 checkPoint = (marketState.epoch + 1) *
                    BLOCKS_PER_WEEK +
                    endColdStartBlockNum;
                uint256 rewardAccruedBeforeFirstEpochEnds = _rewardSpeed *
                    (checkPoint - marketState.lastBlockNum);
                checkPoint += BLOCKS_PER_WEEK;
                while (checkPoint <= blockNumber) {
                    _rewardSpeed = (_rewardSpeed * 96) / 100;
                    rewardAccrued += _rewardSpeed * BLOCKS_PER_WEEK;
                    checkPoint += BLOCKS_PER_WEEK;
                }
                _rewardSpeed = (_rewardSpeed * 96) / 100;
                uint256 rewardAccruedInTheFinalEpoch = _rewardSpeed *
                    (blockNumber + BLOCKS_PER_WEEK - checkPoint);
                rewardAccrued +=
                    rewardAccruedBeforeFirstEpochEnds +
                    rewardAccruedInTheFinalEpoch;
            } else
                rewardAccrued =
                    _rewardSpeed *
                    (blockNumber - marketState.lastBlockNum);
        }
        if (totalStake != 0) {
            _marketIndex += (rewardAccrued * 1e18) / totalStake;
            _totalRewardAccrued += rewardAccrued;
        }

        uint256 deltaIndex = _marketIndex - recipientIndexes[recipient];

        uint256 recipientDelta = (stakingMap[recipient] * deltaIndex) / 1e18;
        _rewardForRecipient = rewardAccrueds[recipient] + recipientDelta;
    }
}