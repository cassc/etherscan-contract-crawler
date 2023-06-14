// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../PenpieOFT.sol";
import "../rewards/BaseRewardPoolV2.sol";
import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IVLPenpieBaseRewarder.sol";
import "../interfaces/IVLPenpie.sol";
import "../libraries/ERC20FactoryLib.sol";
import "../interfaces/IMintableERC20.sol";

/// @title A contract for managing all reward pools
/// @author Magpie Team
/// @notice Mater penpie emit `PNP` reward token based on Time. For a pool,

contract MasterPenpie is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 available; // in case of locking
        uint256 unClaimedPenpie;
        //
        // We do some fancy math here. Basically, any point in time, the amount of Penpies
        // entitled to a user but is pending to be distributed is:
        //
        // pending reward = (user.amount * pool.accPenpiePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws staking tokens to a pool. Here's what happens:
        //   1. The pool's `accPenpiePerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        uint256 allocPoint; // How many allocation points assigned to this pool. Penpies to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that Penpies distribution occurs.
        uint256 accPenpiePerShare; // Accumulated Penpies per share, times 1e12. See below.
        uint256 totalStaked;
        address rewarder;
        bool isActive; // if the pool is active
    }

    /* ============ State Variables ============ */

    // The Penpie TOKEN!
    IERC20 public penpieOFT;
    IVLPenpie public vlPenpie;

    // penpie tokens created per second.
    uint256 public penpiePerSec;

    // Registered staking tokens
    address[] public registeredToken;
    // Info of each pool.
    mapping(address => PoolInfo) public tokenToPoolInfo;
    // mapping of staking -> receipt Token
    mapping(address => address) public receiptToStakeToken;
    // Info of each user that stakes staking tokens [_staking][_account]
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when Penpie mining starts.
    uint256 public startTimestamp;

    mapping(address => bool) public PoolManagers;
    mapping(address => bool) public AllocationManagers;

    /* ============ Events ============ */

    event Add(
        uint256 _allocPoint,
        address indexed _stakingToken,
        address indexed _receiptToken,
        IBaseRewardPool indexed _rewarder
    );
    event Set(
        address indexed _stakingToken,
        uint256 _allocPoint,
        IBaseRewardPool indexed _rewarder
    );
    event Deposit(
        address indexed _user,
        address indexed _stakingToken,
        address indexed _receiptToken,
        uint256 _amount
    );
    event Withdraw(
        address indexed _user,
        address indexed _stakingToken,
        address indexed _receiptToken,
        uint256 _amount
    );
    event UpdatePool(
        address indexed _stakingToken,
        uint256 _lastRewardTimestamp,
        uint256 _lpSupply,
        uint256 _accPenpiePerShare
    );
    event HarvestPenpie(
        address indexed _account,
        address indexed _receiver,
        uint256 _amount,
        bool isLock
    );
    event UpdateEmissionRate(
        address indexed _user,
        uint256 _oldPenpiePerSec,
        uint256 _newPenpiePerSec
    );
    event UpdatePoolAlloc(
        address _stakingToken,
        uint256 _oldAllocPoint,
        uint256 _newAllocPoint
    );
    event PoolManagerStatus(address _account, bool _status);
    event VlPenpieUpdated(address _newvlPenpie, address _oldvlPenpie);
    event DepositNotAvailable(
        address indexed _user,
        address indexed _stakingToken,
        uint256 _amount
    );
    event PenpieOFTSet(address _penpie);

    /* ============ Errors ============ */

    error OnlyPoolManager();
    error OnlyReceiptToken();
    error OnlyStakingToken();
    error OnlyActivePool();
    error PoolExisted();
    error InvalidStakingToken();
    error WithdrawAmountExceedsStaked();
    error UnlockAmountExceedsLocked();
    error MustBeContractOrZero();
    error OnlyVlPenpie();
    error PenpieOFTSetAlready();
    error MustBeContract();
    error LengthMismatch();
    error OnlyWhiteListedAllocaUpdator();

    /* ============ Constructor ============ */

    constructor() {
        _disableInitializers();
    }

    function __MasterPenpie_init(
        address _penpieOFT,
        uint256 _penpiePerSec,
        uint256 _startTimestamp
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        penpieOFT = IERC20(_penpieOFT);
        penpiePerSec = _penpiePerSec;
        startTimestamp = _startTimestamp;
        totalAllocPoint = 0;
        PoolManagers[owner()] = true;
    }

    /* ============ Modifiers ============ */

    modifier _onlyPoolManager() {
        if (!PoolManagers[msg.sender] && msg.sender != address(this))
            revert OnlyPoolManager();
        _;
    }

    modifier _onlyWhiteListed() {
        if (
            AllocationManagers[msg.sender] ||
            PoolManagers[msg.sender] ||
            msg.sender == owner()
        ) {
            _;
        } else {
            revert OnlyWhiteListedAllocaUpdator();
        }
    }

    modifier _onlyReceiptToken() {
        address stakingToken = receiptToStakeToken[msg.sender];
        if (msg.sender != address(tokenToPoolInfo[stakingToken].receiptToken))
            revert OnlyReceiptToken();
        _;
    }

    modifier _onlyVlPenpie() {
        if (msg.sender != address(vlPenpie)) revert OnlyVlPenpie();
        _;
    }

    /* ============ External Getters ============ */

    /// @notice Returns number of registered tokens, tokens having a registered pool.
    /// @return Returns number of registered tokens
    function poolLength() external view returns (uint256) {
        return registeredToken.length;
    }

    /// @notice Gives information about a Pool. Used for APR calculation and Front-End
    /// @param _stakingToken Staking token of the pool we want to get information from
    /// @return emission - Emissions of Penpie from the contract, allocpoint - Allocated emissions of Penpie to the pool,sizeOfPool - size of Pool, totalPoint total allocation points

    function getPoolInfo(
        address _stakingToken
    )
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        )
    {
        PoolInfo memory pool = tokenToPoolInfo[_stakingToken];
        return (
            ((penpiePerSec * pool.allocPoint) / totalAllocPoint),
            pool.allocPoint,
            pool.totalStaked,
            totalAllocPoint
        );
    }

    /**
     * @dev Get staking information for a user.
     * @param _stakingToken The address of the staking token.
     * @param _user The address of the user.
     * @return stakedAmount The amount of tokens staked by the user.
     * @return availableAmount The available amount of tokens for the user to withdraw.
     */
    function stakingInfo(
        address _stakingToken,
        address _user
    ) public view returns (uint256 stakedAmount, uint256 availableAmount) {
        return (
            userInfo[_stakingToken][_user].amount,
            userInfo[_stakingToken][_user].available
        );
    }

    /// @notice View function to see pending reward tokens on frontend.
    /// @param _stakingToken Staking token of the pool
    /// @param _user Address of the user
    /// @param _rewardToken Specific pending reward token, apart from Penpie
    /// @return pendingPenpie - Expected amount of Penpie the user can claim, bonusTokenAddress - token, bonusTokenSymbol - token Symbol,  pendingBonusToken - Expected amount of token the user can claim
    function pendingTokens(
        address _stakingToken,
        address _user,
        address _rewardToken
    )
        external
        view
        returns (
            uint256 pendingPenpie,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        pendingPenpie = _calPenpieReward(_stakingToken, _user);

        // If it's a multiple reward farm, we return info about the specific bonus token
        if (
            address(pool.rewarder) != address(0) && _rewardToken != address(0)
        ) {
            (bonusTokenAddress, bonusTokenSymbol) = (
                _rewardToken,
                IERC20Metadata(_rewardToken).symbol()
            );
            pendingBonusToken = IBaseRewardPool(pool.rewarder).earned(
                _user,
                _rewardToken
            );
        }
    }

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingPenpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        )
    {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        pendingPenpie = _calPenpieReward(_stakingToken, _user);

        // If it's a multiple reward farm, we return all info about the bonus tokens
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddresses, bonusTokenSymbols) = IBaseRewardPool(
                pool.rewarder
            ).rewardTokenInfos();
            pendingBonusRewards = IBaseRewardPool(pool.rewarder).allEarned(
                _user
            );
        }
    }

    /* ============ External Functions ============ */

    /// @notice Deposits staking token to the pool, updates pool and distributes rewards
    /// @param _stakingToken Staking token of the pool
    /// @param _amount Amount to deposit to the pool
    function deposit(
        address _stakingToken,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        IMintableERC20(pool.receiptToken).mint(msg.sender, _amount);

        IERC20(pool.stakingToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit Deposit(msg.sender, _stakingToken, pool.receiptToken, _amount);
    }

    function depositFor(
        address _stakingToken,
        address _for,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        IMintableERC20(pool.receiptToken).mint(_for, _amount);

        IERC20(pool.stakingToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit Deposit(_for, _stakingToken, pool.receiptToken, _amount);
    }

    /// @notice Withdraw staking tokens from Master Penpie.
    /// @param _stakingToken Staking token of the pool
    /// @param _amount amount to withdraw
    function withdraw(
        address _stakingToken,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        IMintableERC20(pool.receiptToken).burn(msg.sender, _amount);

        IERC20(pool.stakingToken).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _stakingToken, pool.receiptToken, _amount);
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _stakingToken Staking token of the pool
    function updatePool(address _stakingToken) public whenNotPaused {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        if (
            block.timestamp <= pool.lastRewardTimestamp || totalAllocPoint == 0
        ) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
        uint256 penpieReward = (multiplier * penpiePerSec * pool.allocPoint) /
            totalAllocPoint;

        pool.accPenpiePerShare =
            pool.accPenpiePerShare +
            ((penpieReward * 1e12) / lpSupply);
        pool.lastRewardTimestamp = block.timestamp;

        emit UpdatePool(
            _stakingToken,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accPenpiePerShare
        );
    }

    /// @notice Update reward variables for all pools. Be mindful of gas costs!
    function massUpdatePools() public whenNotPaused {
        for (uint256 pid = 0; pid < registeredToken.length; ++pid) {
            updatePool(registeredToken[pid]);
        }
    }

    /// @notice Claims for each of the pools with specified rewards to claim for each pool
    function multiclaimSpecPNP(
        address[] calldata _stakingTokens,
        address[][] memory _rewardTokens,
        bool _withPNP
    ) external whenNotPaused {
        _multiClaim(_stakingTokens, msg.sender, msg.sender, _rewardTokens, _withPNP);
    }


    /// @notice Claims for each of the pools with specified rewards to claim for each pool
    function multiclaimSpec(
        address[] calldata _stakingTokens,
        address[][] memory _rewardTokens
    ) external whenNotPaused {
        _multiClaim(_stakingTokens, msg.sender, msg.sender, _rewardTokens, true);
    }

    /// @notice Claims for each of the pools with specified rewards to claim for each pool
    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] memory _rewardTokens,
        address _account
    ) external whenNotPaused {
        _multiClaim(_stakingTokens, _account, _account, _rewardTokens, true);
    }

    /// @notice Claim for all rewards for the pools
    function multiclaim(
        address[] calldata _stakingTokens
    ) external whenNotPaused {
        address[][] memory rewardTokens = new address[][](
            _stakingTokens.length
        );
        _multiClaim(_stakingTokens, msg.sender, msg.sender, rewardTokens, true);
    }

    /* ============ penpie receipToken interaction Functions ============ */

    function beforeReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external _onlyReceiptToken {
        address _stakingToken = receiptToStakeToken[msg.sender];
        updatePool(_stakingToken);

        if (_from != address(0)) _harvestRewards(_stakingToken, _from);

        if (_to != address(0)) _harvestRewards(_stakingToken, _to);
    }

    function afterReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external _onlyReceiptToken {
        address _stakingToken = receiptToStakeToken[msg.sender];
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];

        if (_from != address(0)) {
            UserInfo storage from = userInfo[_stakingToken][_from];
            from.amount = from.amount - _amount;
            from.available = from.available - _amount;
            from.rewardDebt = (from.amount * pool.accPenpiePerShare) / 1e12;
        } else {
            // mint
            tokenToPoolInfo[_stakingToken].totalStaked += _amount;
        }

        if (_to != address(0)) {
            UserInfo storage to = userInfo[_stakingToken][_to];
            to.amount = to.amount + _amount;
            to.available = to.available + _amount;
            to.rewardDebt = (to.amount * pool.accPenpiePerShare) / 1e12;
        } else {
            // brun
            tokenToPoolInfo[_stakingToken].totalStaked -= _amount;
        }
    }

    /* ============ vlPenpie interaction Functions ============ */

    function depositVlPenpieFor(
        uint256 _amount,
        address _for
    ) external whenNotPaused nonReentrant _onlyVlPenpie {
        _deposit(address(vlPenpie), msg.sender, _for, _amount, true);
    }

    function withdrawVlPenpieFor(
        uint256 _amount,
        address _for
    ) external whenNotPaused nonReentrant _onlyVlPenpie {
        _withdraw(address(vlPenpie), _for, _amount, true);
    }

    /* ============ Internal Functions ============ */

    /// @notice internal function to deal with deposit staking token
    function _deposit(
        address _stakingToken,
        address _from,
        address _for,
        uint256 _amount,
        bool _isLock
    ) internal {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][_for];

        updatePool(_stakingToken);
        _harvestRewards(_stakingToken, _for);

        user.amount = user.amount + _amount;
        if (!_isLock) {
            user.available = user.available + _amount;
            IERC20(pool.stakingToken).safeTransferFrom(
                address(_from),
                address(this),
                _amount
            );
        }
        user.rewardDebt = (user.amount * pool.accPenpiePerShare) / 1e12;

        if (_amount > 0) {
            pool.totalStaked += _amount;
            if (!_isLock)
                emit Deposit(_for, _stakingToken, pool.receiptToken, _amount);
            else emit DepositNotAvailable(_for, _stakingToken, _amount);
        }
    }

    /// @notice internal function to deal with withdraw staking token
    function _withdraw(
        address _stakingToken,
        address _account,
        uint256 _amount,
        bool _isLock
    ) internal {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][_account];

        if (!_isLock && user.available < _amount)
            revert WithdrawAmountExceedsStaked();
        else if (user.amount < _amount && _isLock)
            revert UnlockAmountExceedsLocked();

        updatePool(_stakingToken);
        _harvestPenpie(_stakingToken, _account);
        _harvestBaseRewarder(_stakingToken, _account);

        user.amount = user.amount - _amount;
        if (!_isLock) {
            user.available = user.available - _amount;
            IERC20(tokenToPoolInfo[_stakingToken].stakingToken).safeTransfer(
                address(msg.sender),
                _amount
            );
        }
        user.rewardDebt = (user.amount * pool.accPenpiePerShare) / 1e12;

        pool.totalStaked -= _amount;

        emit Withdraw(_account, _stakingToken, pool.receiptToken, _amount);
    }

    function _multiClaim(
        address[] calldata _stakingTokens,
        address _user,
        address _receiver,
        address[][] memory _rewardTokens,
        bool _withPnp
    ) internal nonReentrant {
        uint256 length = _stakingTokens.length;
        if (length != _rewardTokens.length) revert LengthMismatch();

        uint256 vlPenpiePoolAmount;
        uint256 defaultPoolAmount;

        for (uint256 i = 0; i < length; ++i) {
            address _stakingToken = _stakingTokens[i];
            UserInfo storage user = userInfo[_stakingToken][_user];

            updatePool(_stakingToken);
            uint256 claimablePenpie = _calNewPenpie(_stakingToken, _user) +
                user.unClaimedPenpie;

            // if claim with PNP, then unclamed is 0
            if (_withPnp) {
                if (_stakingToken == address(vlPenpie)) {
                    vlPenpiePoolAmount += claimablePenpie;
                } else {
                    defaultPoolAmount += claimablePenpie;
                }
                user.unClaimedPenpie = 0;
            } else {
                user.unClaimedPenpie = claimablePenpie;
            }

            user.rewardDebt =
                (user.amount *
                    tokenToPoolInfo[_stakingToken].accPenpiePerShare) /
                1e12;
            _claimBaseRewarder(
                _stakingToken,
                _user,
                _receiver,
                _rewardTokens[i]
            );
        }

        // if not claiming PNP, early return
        if (!_withPnp) return;

        if (vlPenpiePoolAmount > 0) {
            _sendPenpieForVlPenpiePool(_user, _receiver, vlPenpiePoolAmount);
        }

        if (defaultPoolAmount > 0) {
            _sendPenpie(_user, _receiver, defaultPoolAmount);
        }
    }

    /// @notice calculate Penpie reward based at current timestamp, for frontend only
    function _calPenpieReward(
        address _stakingToken,
        address _user
    ) internal view returns (uint256 pendingPenpie) {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][_user];
        uint256 accPenpiePerShare = pool.accPenpiePerShare;

        if (
            block.timestamp > pool.lastRewardTimestamp && pool.totalStaked != 0
        ) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint256 penpieReward = (multiplier *
                penpiePerSec *
                pool.allocPoint) / totalAllocPoint;
            accPenpiePerShare =
                accPenpiePerShare +
                (penpieReward * 1e12) /
                pool.totalStaked;
        }

        pendingPenpie =
            (user.amount * accPenpiePerShare) /
            1e12 -
            user.rewardDebt;
        pendingPenpie += user.unClaimedPenpie;
    }

    function _harvestRewards(address _stakingToken, address _account) internal {
        if (userInfo[_stakingToken][_account].amount > 0) {
            _harvestPenpie(_stakingToken, _account);
        }
        _harvestBaseRewarder(_stakingToken, _account);
    }

    /// @notice Harvest Penpie for an account
    /// only update the reward counting but not sending them to user
    function _harvestPenpie(address _stakingToken, address _account) internal {
        // Harvest Penpie
        uint256 pending = _calNewPenpie(_stakingToken, _account);
        userInfo[_stakingToken][_account].unClaimedPenpie += pending;
    }

    /// @notice calculate Penpie reward based on current accPenpiePerShare
    function _calNewPenpie(
        address _stakingToken,
        address _account
    ) internal view returns (uint256) {
        UserInfo storage user = userInfo[_stakingToken][_account];
        uint256 pending = (user.amount *
            tokenToPoolInfo[_stakingToken].accPenpiePerShare) /
            1e12 -
            user.rewardDebt;
        return pending;
    }

    /// @notice Harvest reward token in BaseRewarder for an account. NOTE: Baserewarder use user staking token balance as source to
    /// calculate reward token amount
    function _claimBaseRewarder(
        address _stakingToken,
        address _account,
        address _receiver,
        address[] memory _rewardTokens
    ) internal {
        IBaseRewardPool rewarder = IBaseRewardPool(
            tokenToPoolInfo[_stakingToken].rewarder
        );
        if (address(rewarder) != address(0)) {
            if (_rewardTokens.length > 0)
                rewarder.getRewards(_account, _receiver, _rewardTokens);
                // if not specifiying any reward token, just claim them all
            else rewarder.getReward(_account, _receiver);
        }
    }

    /// only update the reward counting on in base rewarder but not sending them to user
    function _harvestBaseRewarder(
        address _stakingToken,
        address _account
    ) internal {
        IBaseRewardPool rewarder = IBaseRewardPool(
            tokenToPoolInfo[_stakingToken].rewarder
        );
        if (address(rewarder) != address(0)) rewarder.updateFor(_account);
    }

    function _sendPenpieForVlPenpiePool(
        address _account,
        address _receiver,
        uint256 _amount
    ) internal {
        address vlPenpieRewarder = tokenToPoolInfo[address(vlPenpie)].rewarder;
        penpieOFT.safeApprove(vlPenpieRewarder, _amount);
        IVLPenpieBaseRewarder(vlPenpieRewarder).queuePenpie(
            _amount,
            _account,
            _receiver
        );

        emit HarvestPenpie(_account, _receiver, _amount, false);
    }

    function _sendPenpie(
        address _account,
        address _receiver,
        uint256 _amount
    ) internal {
        penpieOFT.safeTransfer(_receiver, _amount);

        emit HarvestPenpie(_account, _receiver, _amount, false);
    }

    function _addPool(
        uint256 _allocPoint,
        address _stakingToken,
        address _receiptToken,
        address _rewarder
    ) internal {
        if (
            !Address.isContract(address(_stakingToken)) ||
            !Address.isContract(address(_receiptToken))
        ) revert InvalidStakingToken();

        if (
            !Address.isContract(address(_rewarder)) &&
            address(_rewarder) != address(0)
        ) revert MustBeContractOrZero();

        if (tokenToPoolInfo[_stakingToken].isActive) revert PoolExisted();

        massUpdatePools();
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        registeredToken.push(_stakingToken);
        // it's receipt token as the registered token
        tokenToPoolInfo[_stakingToken] = PoolInfo({
            receiptToken: _receiptToken,
            stakingToken: _stakingToken,
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accPenpiePerShare: 0,
            totalStaked: 0,
            rewarder: _rewarder,
            isActive: true
        });

        receiptToStakeToken[_receiptToken] = _stakingToken;

        emit Add(
            _allocPoint,
            _stakingToken,
            _receiptToken,
            IBaseRewardPool(_rewarder)
        );
    }

    /* ============ Admin Functions ============ */
    /// @notice Used to give edit rights to the pools in this contract to a Pool Manager
    /// @param _account Pool Manager Adress
    /// @param _allowedManager True gives rights, False revokes them
    function setPoolManagerStatus(
        address _account,
        bool _allowedManager
    ) external onlyOwner {
        PoolManagers[_account] = _allowedManager;

        emit PoolManagerStatus(_account, PoolManagers[_account]);
    }

    function setPenpie(address _penpieOFT) external onlyOwner {
        if (address(penpieOFT) != address(0)) revert PenpieOFTSetAlready();

        if (!Address.isContract(_penpieOFT)) revert MustBeContract();

        penpieOFT = IERC20(_penpieOFT);
        emit PenpieOFTSet(_penpieOFT);
    }

    function setVlPenpie(address _vlPenpie) external onlyOwner {
        address oldvlPenpie = address(vlPenpie);
        vlPenpie = IVLPenpie(_vlPenpie);
        emit VlPenpieUpdated(address(vlPenpie), oldvlPenpie);
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Add a new rewarder to the pool. Can only be called by a PoolManager.
    /// @param _receiptToken receipt token of the pool
    /// @param mainRewardToken Token that will be rewarded for staking in the pool
    /// @return address of the rewarder created
    function createRewarder(
        address _receiptToken,
        address mainRewardToken
    ) external _onlyPoolManager returns (address) {
        BaseRewardPoolV2 _rewarder = new BaseRewardPoolV2(
            _receiptToken,
            mainRewardToken,
            address(this),
            msg.sender
        );
        return address(_rewarder);
    }

    /// @notice Add a new penlde marekt pool. Explicitly for Pendle Market pools and should be called from Pendle Staking.
    function add(
        uint256 _allocPoint,
        address _stakingToken,
        address _receiptToken,
        address _rewarder
    ) external _onlyPoolManager {
        _addPool(_allocPoint, _stakingToken, _receiptToken, _rewarder);
    }

    /// @notice Add a new pool that does not mint receipt token. Mainly for locker pool such as vlPNP, mPendleSV
    function createNoReceiptPool(
        uint256 _allocPoint,
        address _stakingToken,
        address _rewarder
    ) external onlyOwner {
        _addPool(_allocPoint, _stakingToken, _stakingToken, _rewarder);
    }

    function createPool(
        uint256 _allocPoint,
        address _stakingToken,
        string memory _receiptName,
        string memory _receiptSymbol
    ) external onlyOwner {
        IERC20 newToken = IERC20(
            ERC20FactoryLib.createReceipt(
                address(_stakingToken),
                address(this),
                _receiptName,
                _receiptSymbol
            )
        );

        address rewarder = this.createRewarder(address(newToken), address(0));

        _addPool(_allocPoint, _stakingToken, address(newToken), rewarder);
    }

    /// @notice Updates the given pool's Penpie allocation point, rewarder address and locker address if overwritten. Can only be called by a Pool Manager.
    /// @param _stakingToken Staking token of the pool
    /// @param _allocPoint Allocation points of Penpie to the pool
    /// @param _rewarder Address of the rewarder for the pool
    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _rewarder
    ) external _onlyPoolManager {
        if (
            !Address.isContract(address(_rewarder)) &&
            address(_rewarder) != address(0)
        ) revert MustBeContractOrZero();

        if (!tokenToPoolInfo[_stakingToken].isActive) revert OnlyActivePool();

        massUpdatePools();

        totalAllocPoint =
            totalAllocPoint -
            tokenToPoolInfo[_stakingToken].allocPoint +
            _allocPoint;

        tokenToPoolInfo[_stakingToken].allocPoint = _allocPoint;
        tokenToPoolInfo[_stakingToken].rewarder = _rewarder;

        emit Set(
            _stakingToken,
            _allocPoint,
            IBaseRewardPool(tokenToPoolInfo[_stakingToken].rewarder)
        );
    }

    /// @notice Update the emission rate of Penpie for MasterMagpie
    /// @param _penpiePerSec new emission per second
    function updateEmissionRate(uint256 _penpiePerSec) public onlyOwner {
        massUpdatePools();
        uint256 oldEmissionRate = penpiePerSec;
        penpiePerSec = _penpiePerSec;

        emit UpdateEmissionRate(msg.sender, oldEmissionRate, penpiePerSec);
    }

    function updatePoolsAlloc(
        address[] calldata _stakingTokens,
        uint256[] calldata _allocPoints
    ) external _onlyWhiteListed {
        massUpdatePools();

        if (_stakingTokens.length != _allocPoints.length)
            revert LengthMismatch();

        for (uint256 i = 0; i < _stakingTokens.length; i++) {
            uint256 oldAllocPoint = tokenToPoolInfo[_stakingTokens[i]]
                .allocPoint;

            totalAllocPoint = totalAllocPoint - oldAllocPoint + _allocPoints[i];

            tokenToPoolInfo[_stakingTokens[i]].allocPoint = _allocPoints[i];

            emit UpdatePoolAlloc(
                _stakingTokens[i],
                oldAllocPoint,
                _allocPoints[i]
            );
        }
    }

    function updateWhitelistedAllocManager(
        address _account,
        bool _allowed
    ) external onlyOwner {
        AllocationManagers[_account] = _allowed;
    }

    function updateRewarderQueuer(
        address _rewarder,
        address _manager,
        bool _allowed
    ) external onlyOwner {
        IBaseRewardPool rewarder = IBaseRewardPool(_rewarder);
        rewarder.updateRewardQueuer(_manager, _allowed);
    }
}