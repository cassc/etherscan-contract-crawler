// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IGeojamStakingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title GeoJam Rewards Distributor Contractd
 * @author Jorge A Martinez, CTO at Decentralized Solutions
 * @notice No staked funds are held in this contract; only JAM rewards.
 * @notice Funds can be loaded into contract as needed.
 * @notice Stakers should claim any eligible rewards before withdrawing their staked JAM.
 * @notice Withdrawing deposited funds in paired staking contract will not allow users to claim anymore rewards.
 */
contract GeojamRewardsDistributorV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STAKER DATA STRUCTURE ========== */

    struct Staker {
        uint256 claimedAmount;
        uint256 catchupPayment;
        bool specialRate;
    }

    /* ========== EXTERNAL CONTRACTS ========== */

    IERC20 public rewardToken;
    IGeojamStakingPool public geojamStakingPool;

    /* ========== STATE VARIABLES ========== */

    uint256 public stakingPeriodStartTimestamp = 1648684800;        // Midnight, March 31st, 2022
    uint256 public rewardsAccruableStartTimestamp = 1659312000;     // Midnight, July 31st, 2022
    uint256 public rewardsClaimableTimestamp = 1661583600;          // Midnight, Aug 27th, 2022
    uint256 public stakingPeriodEndTimestamp = 1711756800;          // Midnight, March 30th, 2024
    uint256 public rewardsPeriod = stakingPeriodEndTimestamp.sub(stakingPeriodStartTimestamp);
    uint256 public rewardAmount;
    uint256 public projectId;
    uint256 public poolId;

    mapping(address => Staker) public stakers;

    /* ========== EVENTS ========== */

    event Funded(uint256 reward);
    event FundsWithdrawn(uint256 fundsWithdrawn);
    event Claimed(
        address indexed staker, 
        uint256 indexed rewardAmount
    );
    event RewardPaid(
        address indexed staker, 
        uint256 reward
    );
    event StakerAdded(
        address indexed staker,
        bool indexed specialRate,
        uint256 indexed catchupPayment
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
     * @dev Returns the current timestamp or the last timestamp rewards are accrued. 
     */
    function rewardTime() public view returns (uint256) {
        return Math.min(block.timestamp, stakingPeriodEndTimestamp);
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
        if (block.timestamp >= rewardsAccruableStartTimestamp) {
            uint256 rate = 2000;
            if (stakers[_staker].specialRate) {
                rate = 2200;
            }
            totalEarned = jamStaked
                .mul(rate)
                .mul(rewardTime().sub(rewardsAccruableStartTimestamp))
                .div(rewardsPeriod)
                .div(1E4);
            totalEarned = totalEarned.add(stakers[_staker].catchupPayment);
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
        netEarned = grossEarnings(_staker).sub(stakers[_staker].claimedAmount);
    }

    /* ========== USER FUNCTIONS ========== */

    /**
     * @dev Calculates at given staker's claimable earnings.
     */
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
            block.timestamp >= rewardsClaimableTimestamp,
            "Rewards not claimable until Midnight Aug 27th UTC"
        );

        // calculate eligible rewards
        uint256 earnings = claimableEarnings(msg.sender);

        if (earnings > 0) {
            // update rewards paid and payout rewards
            stakers[msg.sender].claimedAmount = stakers[msg.sender].claimedAmount.add(
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
     * @dev Allows GeoJam Dev Team to change when rewards begin accruing.
     * @param _newRewardsAccruableTimestamp New timestamp rewards begin accruing.
     */
    function updateRewardsAccruableStart(uint256 _newRewardsAccruableTimestamp)
        external
        onlyOwner
    {
        rewardsAccruableStartTimestamp = _newRewardsAccruableTimestamp;
    }

    /**
     * @dev Allows GeoJam Dev Team to change when rewards are claimable.
     * @param _newRewardsClaimableTimestamp New timestamp rewards are claimable.
     */
    function updateRewardsClaimable(uint256 _newRewardsClaimableTimestamp)
        external
        onlyOwner
    {
        rewardsClaimableTimestamp = _newRewardsClaimableTimestamp;
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
     * @param _specialRate Whether or not staker will receive the special rate.
     * @param _catchupPayment Payment staker was aidropped.
     * @notice Every staker will be calculated a two year maturation date based on their earliest staking timestamp.
     */
    function addStaker(
        address _stakerAddress,
        bool _specialRate,
        uint256 _catchupPayment
    ) public onlyOwner {
        Staker memory staker;
        if (_specialRate) {
            staker.specialRate = _specialRate;
        }
        staker.catchupPayment = _catchupPayment;
        stakers[_stakerAddress] = staker;
        emit StakerAdded(
            _stakerAddress,
            _specialRate,
            _catchupPayment
        );
    }

    /**
     * @dev Allows GeoJam Dev Team to upload Stake data for existing Stakers in Staking contract.
     * @param _stakerAddresses Array of staker wallet addresses.
     * @param _specialRates Array of booleans indicating whether nor not a staker will receive the special rate.
     * @param _catchupPayments Array of payments stakers were airdropped.
     * @notice Passed in arrays are expected to be sorted and of equivalent length.
     */
    function addStakers(
        address[] memory _stakerAddresses,
        bool[] memory _specialRates,
        uint256[] memory _catchupPayments
    ) public onlyOwner {
        require(
            (_stakerAddresses.length == _catchupPayments.length
            &&  _catchupPayments.length == _specialRates.length),
            "Array lengths need to match!"
        );
        for (uint256 i = 0; i < _stakerAddresses.length; i++) {
            addStaker(
                _stakerAddresses[i],
                _specialRates[i],
                _catchupPayments[i]
            );
        }
    }
}