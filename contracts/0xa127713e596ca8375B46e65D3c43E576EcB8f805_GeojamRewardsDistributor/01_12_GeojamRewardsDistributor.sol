// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IGeojamStakingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

/**
 * @title GeoJam Rewards Distributor Contract
 * @author Jorge A Martinez, CTO at Decentralized Solutions
 * @notice No staked funds are held in this contract; only JAM rewards.
 * @notice Funds can be loaded into contract as needed.
 * @notice Stakers should claim any eligible rewards before withdrawing their staked JAM.
 * @notice Withdrawing deposited funds in paired staking contract will not allow users to claim anymore rewards.
 */
contract GeojamRewardsDistributor is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STAKER DATA STRUCTURE ========== */

    struct Staker {
        uint256 rewardPaid;
        uint256 rewardRate;
        uint256 earliestStakeTimestamp;
    }

    /* ========== EXTERNAL CONTRACTS ========== */

    IERC20 public rewardToken;
    IGeojamStakingPool public geojamStakingPool;

    /* ========== STATE VARIABLES ========== */

    uint256 public constant oneYear = 365 days;
    uint256 public rewardsPeriod = oneYear.mul(2);
    uint256 public rewardsClaimableStart = 1662015600; // Midnight, Aug 31st, 2022
    uint256 public rewardAmount;
    uint256 public projectId;
    uint256 public poolId;

    mapping(address => Staker) public stakers;

    /* ========== EVENTS ========== */

    event Funded(uint256 reward);
    event FundsWithdrawn(uint256 fundsWithdrawn);
    event Claimed(address indexed staker, uint256 indexed rewardAmount);
    event RewardPaid(address indexed staker, uint256 reward);
    event StakerAdded(
        address indexed staker,
        uint256 indexed stakedTimestamp,
        uint256 indexed rewardRate
    );

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Sets the owner and ADS addreses.
     * @param _geojamStakingPool GeoJam Staking contract address.
     * @param _jamToken $JAM contract address.
     * @param _projectId Project ID on staking contract linked with.
     * @param _poolId Pool ID on staking cotnract linked with.
     */
    constructor(
        IGeojamStakingPool _geojamStakingPool,
        IERC20 _jamToken,
        uint256 _projectId,
        uint256 _poolId
    ) {
        require(
            address(_geojamStakingPool) != address(0),
            "Cannot set _geojamStakingPool to the zero address"
        );
        require(
            address(_jamToken) != address(0),
            "Cannot set _jamToken to the zero address"
        );
        rewardToken = _jamToken;
        geojamStakingPool = _geojamStakingPool;
        projectId = _projectId;
        poolId = _poolId;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns time passed since rewards begin being accrued.
     */
    function timePassedSinceRewardsClaimable() public view returns (uint256) {
        if (block.timestamp >= rewardsClaimableStart) {
            return block.timestamp.sub(rewardsClaimableStart);
        } else return 0;
    }

    /**
     * @dev Since every staker has a unique maturation timestamp, this function returns their unique remaining reward period.
     * @param _staker The staked wallet whose reward period you want to see.
     */
    function stakersUniqueRewardPeriod(address _staker)
        public
        view
        returns (uint256)
    {
        return
            rewardsPeriod.sub(
                rewardsClaimableStart.sub(
                    stakers[_staker].earliestStakeTimestamp
                )
            );
    }

    /**
     * @dev Returns either whichever is smaller between the stakers staked time and 
     * @param _staker The staked wallet whose eligible time staked we need to find.
     */
    function eligibleTimeStaked(address _staker) public view returns (uint256) {
        return Math.min(timePassedSinceRewardsClaimable(), stakersUniqueRewardPeriod(_staker));
    }

    /**
     * @dev Calculate at given staker's gross earnings.
     * @param _staker The staked wallet whose gross earnings you want to see.
     */
    function grossEarnings(address _staker)
        public
        view
        returns (uint256 totalEarned)
    {
        uint256 jamStaked = geojamStakingPool.userStakedAmount(
            projectId,
            poolId,
            _staker
        );
        if (block.timestamp >= rewardsClaimableStart) {
            totalEarned = jamStaked
                .mul(stakers[_staker].rewardRate)
                .mul(eligibleTimeStaked(_staker))
                .mul(2)
                .div(stakersUniqueRewardPeriod(_staker))
                .div(1E4);
        } else {
            totalEarned = 0;
        }
    }

    /**
     * @dev Calculates at given staker's claimable earnings.
     * @param _staker The staked wallet whose claimable earnings you want to see.
     */
    function claimableEarnings(address _staker)
        public
        view
        returns (uint256 netEarned)
    {
        netEarned = grossEarnings(_staker).sub(stakers[_staker].rewardPaid);
    }

    /* ========== USER FUNCTIONS ========== */

    function claim() external nonReentrant {
        require(
            !geojamStakingPool.didUserWithdrawFunds(
                projectId,
                poolId,
                msg.sender
            ),
            "You have already withdrawn your JAM"
        );
        require(
            block.timestamp >= rewardsClaimableStart,
            "Rewards not claimable until Midnight Aug 31st UTC"
        );

        // calculate eligible rewards
        uint256 earnings = claimableEarnings(msg.sender);

        if (earnings > 0) {
            // update rewards paid and payout rewards
            stakers[msg.sender].rewardPaid = stakers[msg.sender].rewardPaid.add(
                earnings
            );
            rewardToken.safeTransfer(msg.sender, earnings);
            emit Claimed(msg.sender, earnings);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Allows GeoJam Dev Team to change ERC20 reward token should it be necessary.
     * @param _newRewardToken Address of new reward token.
     */
    function updateRewardToken(IERC20 _newRewardToken) external onlyOwner {
        rewardToken = _newRewardToken;
    }

    /**
     * @dev Allows GeoJam Dev Team to change when rewards are claimable.
     * @param _newRewardsClaimableTimestamp New timestamp rewards are claimable.
     */
    function updateRewardsClaimable(uint256 _newRewardsClaimableTimestamp)
        external
        onlyOwner
    {
        rewardsClaimableStart = _newRewardsClaimableTimestamp;
    }

    /**
     * @dev Allows GeoJam Dev Team to change the Project ID this contract is linked with.
     * @param _projectId New Project ID to link with.
     * @notice Meant to be used in case an error is made when initializing contract.
     */
    function updateProjectId(uint256 _projectId) external onlyOwner {
        projectId = _projectId;
    }

    /**
     * @dev Allows GeoJam Dev Team to change the Pool ID this contract is linked with.
     * @param _poolId New Pool ID to link with.
     * @notice Meant to be used in case an error is made when initializing contract.
     */
    function updatePoolId(uint256 _poolId) external onlyOwner {
        poolId = _poolId;
    }

    /**
     * @dev Allows GeoJam Dev Team to change the Pool ID this contract is linked with.
     * @param _fundAmount Amount of reward token to fund this contract with.
     * @notice Assumes an 18 Decimal Token like JAM token.
     */
    function fundRewardPool(uint256 _fundAmount) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), _fundAmount);
        emit Funded(_fundAmount);
    }

    /**
     * @dev Allows GeoJam Dev Team to quickly withdraw all JAM this contract holds.
     * @notice Meant to be used in case of an emergency or to remove leftoverJAM after staking ends.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 contractRewardBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(owner(), contractRewardBalance);
        emit FundsWithdrawn(contractRewardBalance);
    }

    /**
     * @dev Allows GeoJam Dev Team to upload Stake data for existing Stakers in Staking contract.
     * @param _stakerAddress Wallet address of staker.
     * @param _stakeTimestamp Earliest timestamp a staker originally staked.
     * @param _rewardRate Reward rate Staker will receive based on time staked during staking period.
     * @notice Every staker will be calculated a two year maturation date based on their earliest staking timestamp.
     */
    function addStaker(
        address _stakerAddress,
        uint256 _stakeTimestamp,
        uint256 _rewardRate,
        uint256 _rewardPaid
    ) public onlyOwner {
        Staker memory staker;
        staker.earliestStakeTimestamp = _stakeTimestamp;
        staker.rewardRate = _rewardRate;
        staker.rewardPaid = _rewardPaid;
        stakers[_stakerAddress] = staker;

        emit StakerAdded(
            _stakerAddress,
            staker.earliestStakeTimestamp,
            _rewardRate
        );
    }

    /**
     * @dev Allows GeoJam Dev Team to upload Stake data for existing Stakers in Staking contract.
     * @param _stakerAddresses Array of staker wallet addresses.
     * @param _stakeTimestamps Array of staker stake timestamps.
     * @param _rewardRates Array of staker reward rates.
     * @notice Passed in arrays are expected to be sorted, parallel, and
     */
    function addStakers(
        address[] memory _stakerAddresses,
        uint256[] memory _stakeTimestamps,
        uint256[] memory _rewardRates,
        uint256[] memory _rewardsPaid
    ) public onlyOwner {
        require(
            (_stakerAddresses.length == _stakeTimestamps.length &&
                _stakerAddresses.length == _rewardRates.length),
            "Array lengths need to match!"
        );
        for (uint256 i = 0; i < _stakerAddresses.length; i++) {
            addStaker(
                _stakerAddresses[i],
                _stakeTimestamps[i],
                _rewardRates[i],
                _rewardsPaid[i]
            );
        }
    }
}