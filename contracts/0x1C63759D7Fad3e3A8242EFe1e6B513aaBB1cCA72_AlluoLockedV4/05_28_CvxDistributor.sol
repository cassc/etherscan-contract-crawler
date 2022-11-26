// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./../interfaces/curve/mainnet/ICvxBooster.sol";
import "./../interfaces/curve/mainnet/ICvxBaseRewardPool.sol";
import "../interfaces/IExchange.sol";
import "./../interfaces/curve/mainnet/ICurveCVXETH.sol";

contract CvxDistributor is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 public constant distributionTime = 14 days;

    IERC20MetadataUpgradeable public constant crvCVXETH =
        IERC20MetadataUpgradeable(0x3A283D9c08E8b55966afb64C515f5143cf907611);
    IERC20MetadataUpgradeable public constant cvxRewards =
        IERC20MetadataUpgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20MetadataUpgradeable public constant crvRewards =
        IERC20MetadataUpgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20MetadataUpgradeable public constant WETH =
        IERC20MetadataUpgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    ICurveCVXETH public constant CurveCVXETH =
        ICurveCVXETH(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    uint256 public constant crvCVXETHPoolId = 64;

    ///@dev Stakers info by token holders.
    mapping(address => Staker) public _stakers;

    // Staker contains info related to each staker.
    struct Staker {
        uint256 amount; // tokens currently staked to the contract
        uint256 rewardAllowed; // rewards allowed to be paid out
        uint256 rewardDebt; // param is needed for correct calculation staker's share
        uint256 distributed; // amount of distributed tokens
    }

    struct RewardData {
        address token;
        uint256 amount;
    }
    
    ///@dev ERC20 token earned by stakers as reward.
    IERC20MetadataUpgradeable public rewardToken;

    // Locking's reward amount produced per distribution time.
    uint256 public rewardTotal;

    // Auxiliary parameter (tpl) for locking's math
    uint256 public tokensPerStake;
    // Аuxiliary parameter for locking's math
    uint256 public rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 public allProduced;
    // Аuxiliary parameter for locking's math
    uint256 public producedTime;

    // Amount of currently locked tokens from all users (in lp).
    uint256 public totalStaked;
    // Amount of currently claimed rewards by the users (in CVX-ETH LP).
    uint256 public totalDistributed;

    // flag for upgrades availability
    bool public upgradeStatus;

    // Convex rewards pool
    ICvxBaseRewardPool rewards;

    // Alluo exchange address
    address public exchangeAddress;

    /**
     * @dev Emitted in `receiveStakeInfo` when the user locked the tokens
     */
    event StakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event CvxClaimed(uint256 amount, uint256 time, address indexed sender);
    
    /**
     * @dev Emitted in `receiveUnstakeInfo` when the user unbinded his locked tokens
     */
    event UnstakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Contract constructor without parameters
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Contract initializer 
     */
    function initialize(
        address _multiSigWallet,
        address vlAlluo,
        address rewardTokenAddress,
        address _exchangeAddress
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        producedTime = block.timestamp;
        rewardToken = IERC20MetadataUpgradeable(rewardTokenAddress);

        _setupRole(PROTOCOL_ROLE, vlAlluo);
        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);

        rewards = getCvxRewardPool(crvCVXETHPoolId);
        exchangeAddress = _exchangeAddress;

        crvRewards.safeApprove(exchangeAddress, type(uint256).max);

        crvCVXETH.approve(address(cvxBooster), type(uint256).max);

        cvxRewards.safeApprove(address(CurveCVXETH), type(uint256).max);
        WETH.safeApprove(address(CurveCVXETH), type(uint256).max);
    }

    /**
     * @dev Receive info about user token locking event. Should be called by AlluoLocked contract
     * @param user User who locked tokens
     * @param _amount An amount of Alluo locked
     */
    function receiveStakeInfo(address user, uint256 _amount)
        external
        onlyRole(PROTOCOL_ROLE)
    {
        Staker storage staker = _stakers[user];

        if (totalStaked > 0) {
            update();
        }
        staker.rewardDebt =
            staker.rewardDebt +
            ((_amount * tokensPerStake) / 1e20);

        totalStaked = totalStaked + _amount;
        staker.amount = staker.amount + _amount;

        emit StakeInfoReceived(_amount, block.timestamp, user);
    }

    /**
     * @dev Receive info about user token unlocking event. Should be called by AlluoLocked contract
     * @param user User who unlocked tokens
     * @param _amount An amount of Alluo unlocked
     */
    function receiveUnstakeInfo(address user, uint256 _amount)
        external
        onlyRole(PROTOCOL_ROLE)
    {
        Staker storage staker = _stakers[user];

        update();

        staker.rewardAllowed =
            staker.rewardAllowed +
            ((_amount * tokensPerStake) / 1e20);
        staker.amount = staker.amount - _amount;
        totalStaked = totalStaked - _amount;

        emit UnstakeInfoReceived(_amount, block.timestamp, user);
    }

    /**
     * @dev Сlaims available rewards for user. Should be called by AlluoLocked contract
     * @param user User to claim for
     */
    function claim(address user) external onlyRole(PROTOCOL_ROLE) {
        if (totalStaked > 0) {
            update();
        }

        uint256 reward = calcReward(user, tokensPerStake);
        if (reward == 0) {
            return;
        }
        Staker storage staker = _stakers[user];

        staker.distributed = staker.distributed + reward;
        totalDistributed = totalDistributed + reward;

        rewards.withdrawAndUnwrap(reward, false);

        uint256 rewardPure = CurveCVXETH.remove_liquidity_one_coin(
            reward,
            1,
            0,
            false
        );

        cvxRewards.safeTransfer(user, rewardPure);
        emit CvxClaimed(reward, block.timestamp, user);
    }

    /**
     * @dev Receive information about incoming CVX-ETH LP tokens that have to be distributed to lockers
     * @param _amount Amount on LP tokens received
     */
    function receiveReward(uint256 _amount) external onlyRole(PROTOCOL_ROLE) {
        _amount += getRewards();
        allProduced = produced();
        producedTime = block.timestamp;
        rewardTotal = _amount;

        cvxBooster.deposit(crvCVXETHPoolId, _amount, true);

        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Deposit LP tokens to Convex pool
     * @param _amount Amount on LP tokens received
     */
    function forceDeposit(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cvxBooster.deposit(crvCVXETHPoolId, _amount, true);
    }

    /**
     * @dev Withdraw LP tokens from Convex pool
     * @param _amount Amount on LP tokens to get
     */
    function forceWithdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewards.withdrawAndUnwrap(_amount, false);
    }

    /**
     * @dev Claim contract available rewards and re-invest them into Convex pools
     */
    function forceClaimCycle() external onlyRole(DEFAULT_ADMIN_ROLE) {
        getRewards();
    }

    /**
     * @dev Сalculates available reward
     * @param _staker Address of the locker
     * @param _tps Tokens per lock parameter
     */
    function calcReward(address _staker, uint256 _tps)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = _stakers[_staker];

        reward =
            ((staker.amount * _tps) / 1e20) +
            staker.rewardAllowed -
            staker.distributed -
            staker.rewardDebt;

        return reward;
    }

    /**
     * @dev Calculates the necessary parameters for staking
     * @return Totally produced rewards
     */
    function produced() private view returns (uint256) {
        uint256 timePassed = (block.timestamp - producedTime);
        if (timePassed > distributionTime) {
            timePassed = distributionTime;
        }
        return
            allProduced +
            (rewardTotal * timePassed) /
            distributionTime;
    }

    /**
     * @dev Returns staker's available rewards
     * @param _staker Address of the staker
     * @return reward Available reward to claim
     */
    function getClaim(address _staker) public view returns (uint256 reward) {
        uint256 _tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tps = _tps + ((producedNew * 1e20) / totalStaked);
            }
        }
        uint256 rewardLp = calcReward(_staker, _tps);

        return
            rewardLp == 0 ? 0 : CurveCVXETH.calc_withdraw_one_coin(rewardLp, 1);
    }

    /**
     * @dev Updates the produced rewards parameter for staking
     */
    function update() public onlyRole(PROTOCOL_ROLE) {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake =
                    tokensPerStake +
                    (producedNew * 1e20) /
                    totalStaked;
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    /**
     * @dev allows and prohibits to upgrade contract
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    /**
     * @dev admin function for adding/changing exchange address
     * @param _exchangeAddress new exchange address
     */
    function addExchange(address _exchangeAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchangeAddress = _exchangeAddress;
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20MetadataUpgradeable(withdrawToken).safeTransfer(to, amount);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "Upgrade !allowed");
        upgradeStatus = false;
    }

    function getRewards() private returns (uint256) {
        rewards.getReward(address(this), true);

        uint256 crvAmount = crvRewards.balanceOf(address(this));
        uint256 cvxAmount = cvxRewards.balanceOf(address(this));

        uint256 wethReceived;

        if (crvAmount > 0) {
            wethReceived = IExchange(exchangeAddress).exchange(
                address(crvRewards),
                address(WETH),
                crvAmount,
                0
            );
        }

        if (crvAmount > 0 || cvxAmount > 0) {
            return CurveCVXETH.add_liquidity([wethReceived, cvxAmount], 0);
        } else {
            return 0;
        }
    }

    function accruedRewards() public view returns (RewardData[] memory) {
        (, , , address pool, , ) = cvxBooster.poolInfo(crvCVXETHPoolId);
        ICvxBaseRewardPool mainCvxPool = ICvxBaseRewardPool(pool);
        uint256 extraRewardsLength = mainCvxPool.extraRewardsLength();
        RewardData[] memory rewardArray = new RewardData[](extraRewardsLength + 1);
        rewardArray[0] = RewardData(mainCvxPool.rewardToken(),mainCvxPool.earned(address(this)));
        for (uint256 i; i < extraRewardsLength; i++) {
            ICvxBaseRewardPool extraReward = ICvxBaseRewardPool(mainCvxPool.extraRewards(i));

            rewardArray[i+1] = (RewardData(extraReward.rewardToken(), extraReward.earned(address(this))));
        }
        return rewardArray;
    }

    function stakerAccruedRewards(address _staker) public view returns (RewardData[] memory) {
        RewardData[] memory accruals = accruedRewards();
        Staker memory staker = _stakers[_staker];

        uint256 stakerAmount = staker.amount;
        uint256 totalStakedAmount = totalStaked;

        for (uint256 i; i < accruals.length; i++) {
            uint256 stakerShareOfaccruals = accruals[i].amount * stakerAmount / totalStakedAmount;
            accruals[i].amount = stakerShareOfaccruals;
        }

        return (accruals);
    }

    function getCvxRewardPool(uint256 poolId)
        private
        view
        returns (ICvxBaseRewardPool)
    {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(pool);
    }
}