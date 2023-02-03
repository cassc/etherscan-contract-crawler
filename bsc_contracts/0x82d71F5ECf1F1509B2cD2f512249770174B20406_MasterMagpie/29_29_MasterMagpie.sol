// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "../Mgp.sol";
import "./BaseRewardPoolV2.sol";
import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IvlmgpPBaseRewarder.sol";
import "../interfaces/IHarvesttablePoolHelper.sol";
import "../interfaces/IVLMGP.sol";
import "../interfaces/ILocker.sol";

// MasterMagpie is a boss. He says "go f your blocks lego boy, I'm gonna use timestamp instead".
// And to top it off, it takes no risks. Because the biggest risk is operator error.
// So we make it virtually impossible for the operator of this contract to cause a bug with people's harvests.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MGP is sufficiently
// distributed and the community can show to govern itself.
//
/// @title A contract for managing all reward pools
/// @author Magpie Team
/// @notice You can use this contract for depositing MGP, MWOM, and Liquidity Pool tokens.
/// @dev All the ___For() function are function which are supposed to be called by other contract designed by Magpie's team

contract MasterMagpie is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 available; // in case of locking
        //
        // We do some fancy math here. Basically, any point in time, the amount of MGPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMGPPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws staking tokens to a pool. Here's what happens:
        //   1. The pool's `accMGPPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakingToken; // Address of staking token contract to be staked.
        uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
        uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
        address rewarder;
        address helper;
        bool    helperNeedsHarvest;
    }

    /* ============ State Variables ============ */

    // The MGP TOKEN!
    MGP public mgp;

    IVLMGP public vlmgp;

    // MGP tokens created per second.
    uint256 public mgpPerSec;

    // Registered staking tokens 
    address[] public registeredToken;
    // Info of each pool.
    mapping(address => PoolInfo) public tokenToPoolInfo;
    // Set of all staking tokens that have been added as pools
    mapping(address => bool) private openPools;
    // Info of each user that stakes staking tokens [_staking][_account]
    mapping(address => mapping(address => UserInfo)) private userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when MGP mining starts.
    uint256 public startTimestamp;

    mapping(address => bool) public PoolManagers;

    address public compounder;

    /* ==== variable added for first upgrade === */

    mapping(address => bool) public MPGRewardPool; // pools that emit MGP otherwise, vlMGP

    /* ==== variable added for second upgrade === */
    mapping(address => mapping (address => uint256)) public unClaimedMgp; // unclaimed mgp reward before lastRewardTimestamp
    mapping(address => address) public legacyRewarder; // old rewarder

    /* ============ Events ============ */

    event Add(
        uint256 _allocPoint,
        address indexed _stakingToken,
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
        uint256 _amount
    );
    event Withdraw(
        address indexed _user,
        address indexed _stakingToken,
        uint256 _amount
    );
    event UpdatePool(
        address indexed _stakingToken,
        uint256 _lastRewardTimestamp,
        uint256 _lpSupply,
        uint256 _accMGPPerShare
    );
    event HarvestMGP(
        address indexed _account,
        address indexed _receiver,
        uint256 _amount,
        bool isLock
    );
    event EmergencyWithdraw(
        address indexed _user,
        address indexed _stakingToken,
        uint256 _amount
    );
    event UpdateEmissionRate(address indexed _user, uint256 _oldMgpPerSec, uint256 _newMgpPerSec);
    event UpdatePoolAlloc(address _stakingToken, uint256 _oldAllocPoint, uint256 _newAllocPoint);
    event PoolManagerStatus(address _account, bool _status);
    event CompounderUpated(address _newCompounder, address _oldCompounder);
    event VLMGPUpdated(address _newVlmgp, address _oldVlmgp);
    event DepositNotAvailable(address indexed _user,  address indexed _stakingToken, uint256 _amount);
    event MGPSet(address _mgp);
    event LockFreePoolUpdated(address _stakingToken, bool _isRewardMGP);    

    /* ============ Errors ============ */

    error OnlyPoolManager();
    error OnlyPoolHelper();
    error OnlyActivePool();
    error PoolExsisted();
    error InvalidStakingToken();
    error WithdrawAmountExceedsStaked();
    error UnlockAmountExceedsLocked();
    error MustBeContractOrZero();
    error OnlyCompounder();
    error OnlyVlMgp();
    error MGPsetAlready();
    error MustBeContract();
    error LengthMismatch();

    /* ============ Constructor ============ */    

    function __MasterMagpie_init(
        address _mgp,
        uint256 _mgpPerSec,
        uint256 _startTimestamp
    ) public initializer {

        __Ownable_init();        
        mgp = MGP(_mgp);
        mgpPerSec = _mgpPerSec;
        startTimestamp = _startTimestamp;
        totalAllocPoint = 0;
        PoolManagers[owner()] = true;
    }

    /* ============ Modifiers ============ */
    
    modifier _onlyPoolManager() {
        if (!PoolManagers[msg.sender])
            revert OnlyPoolManager();
        _;
    }

    modifier _onlyPoolHelper(address _stakedToken) {
        if (msg.sender != tokenToPoolInfo[_stakedToken].helper)
            revert OnlyPoolHelper();
        _;            
    }

    modifier _onlyVlMgp() {
        if (msg.sender != address(vlmgp))
            revert OnlyVlMgp();
        _;
    }

    modifier _onlyCompounder() {
        if (msg.sender != compounder)
            revert OnlyCompounder();
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
    /// @return emission - Emissions of MGP from the contract, allocpoint - Allocated emissions of MGP to the pool,sizeOfPool - size of Pool, totalPoint total allocation points

    function getPoolInfo(address _stakingToken)
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
            (mgpPerSec * pool.allocPoint / totalAllocPoint),
            pool.allocPoint,
            _calLpSupply(_stakingToken),
            totalAllocPoint
        );
    }

    /// @notice Provides available amount for a specific user for a specific pool.
    /// @param _stakingToken Staking token of the pool
    /// @param _user Address of the user

    function stakingInfo(address _stakingToken, address _user)
        public
        view
        returns (uint256 stakedAmount, uint256 availableAmount)
    {
        return (userInfo[_stakingToken][_user].amount, userInfo[_stakingToken][_user].available);
    }

    /// @notice View function to see pending reward tokens on frontend.
    /// @param _stakingToken Staking token of the pool
    /// @param _user Address of the user
    /// @param _rewardToken Specific pending reward token, apart from MGP
    /// @return pendingMGP - Expected amount of MGP the user can claim, bonusTokenAddress - token, bonusTokenSymbol - token Symbol,  pendingBonusToken - Expected amount of token the user can claim
    function pendingTokens(
        address _stakingToken,
        address _user,
        address _rewardToken
    )
        external
        view
        returns (
            uint256 pendingMGP,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        pendingMGP = _calMGPReward(_stakingToken, _user);

        // If it's a multiple reward farm, we return info about the specific bonus token
        if (address(pool.rewarder) != address(0)) {
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

    function allPendingTokens(address _stakingToken, address _user)
        external view returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        )
    {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        pendingMGP = _calMGPReward(_stakingToken, _user);

        // If it's a multiple reward farm, we return all info about the bonus tokens
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddresses, bonusTokenSymbols) = IBaseRewardPool(pool.rewarder).rewardTokenInfos();
            pendingBonusRewards = IBaseRewardPool(pool.rewarder).allEarned(_user);
        }
    }

    function rewarderBonusTokenInfo(address _stakingToken) public view
        returns (address[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols)
    {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        if (address(pool.rewarder) == address(0)) {
            return (bonusTokenAddresses, bonusTokenSymbols);
        }

        (bonusTokenAddresses, bonusTokenSymbols) = IBaseRewardPool(pool.rewarder).rewardTokenInfos();
    }

    /* ============ External Functions ============ */
    /// @notice Deposits staking token to the pool, updates pool and distributes rewards
    /// @param _stakingToken Staking token of the pool
    /// @param _amount Amount to deposit to the pool
    function deposit(address _stakingToken, uint256 _amount) external whenNotPaused nonReentrant {
        _deposit(_stakingToken, msg.sender, _amount, false);
    }

    /// @notice Withdraw staking tokens from Master Mgapie.
    /// @param _stakingToken Staking token of the pool
    /// @param _amount amount to withdraw
    function withdraw(address _stakingToken, uint256 _amount) external whenNotPaused nonReentrant {
        _withdraw(_stakingToken, msg.sender, _amount, false);
    }

    /// @notice Deposit staking tokens to Master Magpie. Can only be called by pool helper
    /// @param _stakingToken Staking token of the pool
    /// @param _amount Amount to deposit
    /// @param _for Address of the user the pool helper is depositing for, and also harvested reward will be sent to
    function depositFor(
        address _stakingToken,
        uint256 _amount,
        address _for
    ) external whenNotPaused _onlyPoolHelper(_stakingToken) nonReentrant {
        _deposit(_stakingToken, _for, _amount, false);
    }

    /// @notice Withdraw staking tokens from Mastser Magpie for a specific user. Can only be called by pool helper
    /// @param _stakingToken Staking token of the pool
    /// @param _amount amount to withdraw   
    /// @param _for address of the user to withdraw for, and also harvested reward will be sent to
    function withdrawFor(
        address _stakingToken,
        uint256 _amount,
        address _for
    ) external whenNotPaused _onlyPoolHelper(_stakingToken) nonReentrant {
        _withdraw(_stakingToken, _for, _amount, false);
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _stakingToken Staking token of the pool
    function updatePool(address _stakingToken) public whenNotPaused {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        if (block.timestamp <= pool.lastRewardTimestamp || totalAllocPoint == 0) {
            return;
        }
        uint256 lpSupply = _calLpSupply(_stakingToken);
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }        
        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
        uint256 mgpReward = (multiplier * mgpPerSec * pool.allocPoint) / totalAllocPoint;
        
        pool.accMGPPerShare = pool.accMGPPerShare + ((mgpReward * 1e12) / lpSupply);
        pool.lastRewardTimestamp = block.timestamp;

        emit UpdatePool(
            _stakingToken,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accMGPPerShare
        );
    }    

    /// @notice Update reward variables for all pools. Be mindful of gas costs!
    function massUpdatePools() public whenNotPaused {
        for (uint256 pid = 0; pid < registeredToken.length; ++pid) {
            updatePool(registeredToken[pid]);
        }
    }

    /// @notice Claims for each of the pools with specified rewards to claim for each pool
    function multiclaimSpec(address[] calldata _stakingTokens, address[][] memory _rewardTokens)
        external whenNotPaused
    {
        _multiClaim(_stakingTokens, msg.sender, msg.sender, _rewardTokens);
    }

    /// @notice Claims for each of the pools with specified rewards to claim for each pool
    function multiclaimFor(address[] calldata _stakingTokens, address[][] memory _rewardTokens, address _account)
        external whenNotPaused
    {
        _multiClaim(_stakingTokens, _account, _account, _rewardTokens);
    }

    /// @notice Claims for each of the pools with specified rewards to claim for each pool. ONLY callable by compounder!!!!!!
    function multiclaimOnBehalf(address[] calldata _stakingTokens, address[][] memory _rewardTokens, address _account)
        external whenNotPaused _onlyCompounder
    {
        _multiClaim(_stakingTokens, _account, msg.sender, _rewardTokens);
    }

    /// @notice Claim for all rewards for the pools
    function multiclaim(address[] calldata _stakingTokens)
        external whenNotPaused
    {
        address[][] memory rewardTokens = new address[][](_stakingTokens.length);
        _multiClaim(_stakingTokens, msg.sender, msg.sender, rewardTokens);
    }

    /// @notice Withdraw all available tokens without caring about rewards. EMERGENCY ONLY. 
    ///         Locked Token can not be emergent withdraw.
    /// @param _stakingToken Staking token of the pool
    /// @dev withdrawFor of the rewarder with the third param at false is an emergency withdraw
    function emergencyWithdraw(address _stakingToken) external whenPaused {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][msg.sender];
        uint256 availableaAmount = user.available;
        user.available = 0;
        IERC20(pool.stakingToken).safeTransfer(address(msg.sender), availableaAmount);
        emit EmergencyWithdraw(msg.sender, _stakingToken, availableaAmount);
        user.amount = user.amount - availableaAmount;
        user.rewardDebt = (user.amount * pool.accMGPPerShare) / 1e12;
    }

    /* ============ VLMGP interaction Functions ============ */

    function depositVlMGPFor(
        uint256 _amount,
        address _for
    ) external whenNotPaused _onlyVlMgp() {
        _deposit(address(vlmgp), _for, _amount, true);
    }
    
    function withdrawVlMGPFor(
        uint256 _amount,
        address _for
    ) external whenNotPaused _onlyVlMgp() {
        _withdraw(address(vlmgp), _for, _amount, true);
    }

    /* ============ Internal Functions ============ */

    /// @notice internal function to deal with deposit staking token
    function _deposit(address _stakingToken, address _account, uint256 _amount, bool _isVlmgp) internal {
        updatePool(_stakingToken);

        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][_account];

        if (user.amount > 0) {
            _harvestMGP(_stakingToken, _account);
        }
        _harvestBaseRewarder(_stakingToken, _account);

        user.amount = user.amount + _amount;
        if (!_isVlmgp) {
            user.available = user.available + _amount;
            IERC20(pool.stakingToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        }
        user.rewardDebt = (user.amount * pool.accMGPPerShare) / 1e12;

        if (_amount > 0)
            if (!_isVlmgp)
                emit Deposit(_account, _stakingToken, _amount);
            else
                emit DepositNotAvailable(_account, _stakingToken, _amount);
    }

    /// @notice internal function to deal with withdraw staking token
    function _withdraw(address _stakingToken, address _account, uint256 _amount, bool _isVlMgp) internal {
        _harvestAndUnstake(_stakingToken, _account, _amount, _isVlMgp);

        if (!_isVlMgp)
            IERC20(tokenToPoolInfo[_stakingToken].stakingToken).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(_account, _stakingToken, _amount);
    }

    function _harvestAndUnstake(address _stakingToken, address _account, uint256 _amount, bool _isVlMgp) internal {
        updatePool(_stakingToken);

        UserInfo storage user = userInfo[_stakingToken][_account];

        if (!_isVlMgp && user.available < _amount)
            revert WithdrawAmountExceedsStaked();
        else if(user.amount < _amount && _isVlMgp)
            revert UnlockAmountExceedsLocked();
        
        _harvestMGP(_stakingToken, _account);
        _harvestBaseRewarder(_stakingToken, _account);

        user.amount = user.amount - _amount;
        
        if(!_isVlMgp)
            user.available = user.available - _amount;
        user.rewardDebt = (user.amount * tokenToPoolInfo[_stakingToken].accMGPPerShare) / 1e12;
    }

    function _multiClaim(address[] calldata _stakingTokens, address _user, address _receiver, address[][] memory _rewardTokens) internal nonReentrant {
        uint256 length = _stakingTokens.length;
        if (length != _rewardTokens.length) revert LengthMismatch();

        uint256 vlMGPPoolAmount;
        uint256 mWOmPoolAmount;
        uint256 defaultPoolAmount;

        for (uint256 i = 0; i < length; ++i) {
            address _stakingToken = _stakingTokens[i];
            UserInfo storage user = userInfo[_stakingToken][_user];
            
            updatePool(_stakingToken);
            uint256 claimableMgp = _calNewMGP(_stakingToken, _user) + unClaimedMgp[_stakingToken][_user];

            if (_stakingToken == address(vlmgp)) {
                vlMGPPoolAmount += claimableMgp;
            } else if (MPGRewardPool[_stakingToken]) {
                mWOmPoolAmount += claimableMgp;
            } else {
                defaultPoolAmount += claimableMgp;
            }

            unClaimedMgp[_stakingToken][_user] = 0;
            user.rewardDebt = (user.amount * tokenToPoolInfo[_stakingToken].accMGPPerShare) / 1e12;
            _claimBaseRewarder(_stakingToken, _user, _receiver, _rewardTokens[i]);
        }

        if (vlMGPPoolAmount > 0) {
            _sendMGPForVlMGPPool(_user, _receiver, vlMGPPoolAmount);
        }

        if (mWOmPoolAmount > 0) {
            _sendMGP(_user, _receiver, mWOmPoolAmount);
        }

        if (defaultPoolAmount > 0) {
            _sendVlMGPFor(_user, _receiver, defaultPoolAmount);
        }
    }

    /// @notice calculate MGP reward based at current timestamp, for frontend only
    function _calMGPReward(address _stakingToken, address _user) internal view returns(uint256 pendingMGP) {
        PoolInfo storage pool = tokenToPoolInfo[_stakingToken];
        UserInfo storage user = userInfo[_stakingToken][_user];
        uint256 accMGPPerShare = pool.accMGPPerShare;
        uint256 lpSupply = _calLpSupply(_stakingToken);

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint256 mgpReward = (multiplier * mgpPerSec * pool.allocPoint) /
            totalAllocPoint;
            accMGPPerShare = accMGPPerShare + (mgpReward * 1e12) / lpSupply;
        }

        pendingMGP = (user.amount * accMGPPerShare) / 1e12 - user.rewardDebt;
        pendingMGP += unClaimedMgp[_stakingToken][_user];
    }

    /// @notice Harvest MGP for an account
    /// only update the reward counting but not sending them to user
    function _harvestMGP(address _stakingToken, address _account) internal {
        // Harvest MGP
        uint256 pending = _calNewMGP(_stakingToken, _account);
        unClaimedMgp[_stakingToken][_account] += pending;
    }

    /// @notice calculate MGP reward based on current accMGPPerShare
    function _calNewMGP(address _stakingToken, address _account) view internal returns(uint256) {
        UserInfo storage user = userInfo[_stakingToken][_account];
        uint256 pending = (user.amount * tokenToPoolInfo[_stakingToken].accMGPPerShare) /
            1e12 -
            user.rewardDebt;
        return pending;
    }

    /// @notice Harvest reward token in BaseRewarder for an account. NOTE: Baserewarder use user staking token balance as source to
    /// calculate reward token amount
    function _claimBaseRewarder(address _stakingToken, address _account, address _receiver, address[] memory _rewardTokens) internal {
        IBaseRewardPool rewarder = IBaseRewardPool(tokenToPoolInfo[_stakingToken].rewarder);
        if (address(rewarder) != address(0)) {
            if (_rewardTokens.length > 0)
                rewarder.getRewards(_account, _receiver, _rewardTokens);
            else
                // if not specifiying any reward token, just claim them all
                rewarder.getReward(_account, _receiver);
        }
    }

    /// only update the reward counting on in base rewarder but not sending them to user
    function _harvestBaseRewarder(address _stakingToken, address _account) internal {
        IBaseRewardPool rewarder = IBaseRewardPool(tokenToPoolInfo[_stakingToken].rewarder);
        if (address(rewarder) != address(0))
            rewarder.updateFor(_account);
    }

    function _sendMGPForVlMGPPool(address _account, address _receiver, uint256 _amount) internal {
        address vlMGPRewarder = tokenToPoolInfo[address(vlmgp)].rewarder;
        IERC20(mgp).safeApprove(vlMGPRewarder, _amount);
        IvlmgpPBaseRewarder(vlMGPRewarder).queueMGP(_amount, _account, _receiver);

        emit HarvestMGP(_account, _receiver, _amount, false);
    }

    function _sendMGP(address _account, address _receiver, uint256 _amount) internal {
        IERC20(mgp).safeTransfer(_receiver, _amount);

        emit HarvestMGP(_account, _receiver, _amount, false);
    }

    function _sendVlMGPFor(address _account, address _receiver, uint256 _amount) internal {
        IERC20(mgp).safeApprove(address(vlmgp), _amount);
        vlmgp.lockFor(_amount, _account);

        emit HarvestMGP(_account, _receiver, _amount, true);
    }

    function _calLpSupply(address _stakingToken) internal view returns (uint256) {
        if (_stakingToken == address(vlmgp))
            return IERC20(address(vlmgp)).totalSupply();

        return IERC20(_stakingToken).balanceOf(address(this));
    }

    /* ============ Admin Functions ============ */
    /// @notice Used to give edit rights to the pools in this contract to a Pool Manager
    /// @param _account Pool Manager Adress
    /// @param _allowedManager True gives rights, False revokes them
    function setPoolManagerStatus(address _account, bool _allowedManager)
        external
        onlyOwner
    {
        PoolManagers[_account] = _allowedManager;    

        emit PoolManagerStatus(_account, PoolManagers[_account]);
    }

    function setMgp(address _mgp) external onlyOwner {
        if(address(mgp) != address(0))
            revert MGPsetAlready();

        if (!Address.isContract(_mgp))
            revert MustBeContract();

        mgp = MGP(_mgp);
        emit MGPSet(_mgp);
    }

    function setCompounder(address _compounder)
        external
        onlyOwner
    {
        address oldCompounder = compounder;
        compounder = _compounder;
        emit CompounderUpated(compounder, oldCompounder);
    }

    function setVlmgp(address _vlmgp)
        external
        onlyOwner
    {
        address oldVlmgp = address(vlmgp);
        vlmgp = IVLMGP(_vlmgp);
        emit VLMGPUpdated(address(vlmgp), oldVlmgp);
    }

    function setMGPRewardPools(address _stakingToken, bool _isLockFree) external onlyOwner {
        MPGRewardPool[_stakingToken] = _isLockFree;

        emit LockFreePoolUpdated(_stakingToken, MPGRewardPool[_stakingToken]);
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
    /// @param _stakingToken Staking token of the pool
    /// @param mainRewardToken Token that will be rewarded for staking in the pool
    /// @return address of the rewarder created
    function createRewarder(address _stakingToken, address mainRewardToken)
        external
        _onlyPoolManager
        returns (address)
    {
        BaseRewardPoolV2 _rewarder = new BaseRewardPoolV2(
            _stakingToken,
            mainRewardToken,
            address(this),
            msg.sender
        );
        return address(_rewarder);
    }

    /// @notice Add a new pool. Can only be called by a PoolManager.
    /// @param _allocPoint Allocation points of MGP to the pool
    /// @param _stakingToken Staking token of the pool
    /// @param _rewarder Address of the rewarder for the pool
    /// @param _helper Address of the helper for the pool
    /// @param _helperNeedsHarvest Address of the helper for the pool
    function add(
        uint256 _allocPoint,
        address _stakingToken,
        address _rewarder,
        address _helper,
        bool _helperNeedsHarvest
    ) external _onlyPoolManager {
        if (!Address.isContract(address(_stakingToken)))
            revert InvalidStakingToken();

        if (!Address.isContract(address(_helper)) && address(_helper) != address(0))
            revert MustBeContractOrZero();

        if (!Address.isContract(address(_rewarder)) && address(_rewarder) != address(0))
            revert MustBeContractOrZero();

        if (openPools[_stakingToken])
            revert PoolExsisted();

        massUpdatePools();
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        registeredToken.push(_stakingToken);
        tokenToPoolInfo[_stakingToken] = PoolInfo({
            stakingToken: _stakingToken,
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accMGPPerShare: 0,
            rewarder: _rewarder,
            helper: _helper,
            helperNeedsHarvest: _helperNeedsHarvest
        });
        openPools[_stakingToken] = true;
        emit Add(_allocPoint, _stakingToken, IBaseRewardPool(_rewarder));
    }

    /// @notice Updates the given pool's MGP allocation point, rewarder address and locker address if overwritten. Can only be called by a Pool Manager.
    /// @param _stakingToken Staking token of the pool
    /// @param _allocPoint Allocation points of MGP to the pool
    /// @param _rewarder Address of the rewarder for the pool
    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _helper,
        address _rewarder,
        bool _helperNeedsHarvest
    ) external _onlyPoolManager {
        if (!Address.isContract(address(_rewarder)) 
            && address(_rewarder) != address(0))
            revert MustBeContractOrZero();

        if (!Address.isContract(address(_helper)) 
            && address(_helper) != address(0))
            revert MustBeContractOrZero();            

        if (!openPools[_stakingToken])
            revert OnlyActivePool();

        massUpdatePools();

        totalAllocPoint = 
            totalAllocPoint - 
            tokenToPoolInfo[_stakingToken].allocPoint +
            _allocPoint;

        tokenToPoolInfo[_stakingToken].allocPoint = _allocPoint;
        tokenToPoolInfo[_stakingToken].rewarder = _rewarder;
        tokenToPoolInfo[_stakingToken].helper = _helper;
        tokenToPoolInfo[_stakingToken].helperNeedsHarvest = _helperNeedsHarvest;

        emit Set(
            _stakingToken,
            _allocPoint,
            IBaseRewardPool(tokenToPoolInfo[_stakingToken].rewarder)
        );
    }

    function setLegacyRewarder(address _stakingToken, address _legacyRewarder) external onlyOwner {
        legacyRewarder[_stakingToken] = _legacyRewarder;
    }

    /// @notice Update the emission rate of MGP for MasterMagpie
    /// @param _mgpPerSec new emission per second
    function updateEmissionRate(uint256 _mgpPerSec) public onlyOwner {        
        massUpdatePools();
        uint256 oldEmissionRate = mgpPerSec;
        mgpPerSec = _mgpPerSec;

        emit UpdateEmissionRate(msg.sender, oldEmissionRate, mgpPerSec);
    }

    function updatePoolsAlloc(address[] calldata _stakingTokens, uint256[] calldata _allocPoints) external onlyOwner {
        massUpdatePools();

        if (_stakingTokens.length != _allocPoints.length)
            revert LengthMismatch();

        for (uint256 i = 0; i < _stakingTokens.length; i++) {
            uint256 oldAllocPoint = tokenToPoolInfo[_stakingTokens[i]].allocPoint;

            totalAllocPoint = totalAllocPoint - oldAllocPoint + _allocPoints[i];

            tokenToPoolInfo[_stakingTokens[i]].allocPoint = _allocPoints[i];

            emit UpdatePoolAlloc(_stakingTokens[i], oldAllocPoint, _allocPoints[i]);
        }
    }

    // BaseRewarePool manager functions

    function updateRewarderManager(address _rewarder, address _manager, bool _allowed) external onlyOwner {
        IBaseRewardPool rewarder = IBaseRewardPool(_rewarder);
        rewarder.updateManager(_manager, _allowed);
    }
}