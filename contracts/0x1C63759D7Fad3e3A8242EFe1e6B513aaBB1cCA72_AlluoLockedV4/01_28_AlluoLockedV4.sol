// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./../interfaces/IExchange.sol";
import "./../interfaces/IBalancer.sol";
import "./CvxDistributor.sol";
import "./../interfaces/IAlluoLockedV3.sol";

contract AlluoLockedV4 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IBalancerStructs
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Locking's reward amount produced per distribution time.
    uint256 public rewardPerDistribution;
    // Locking's reward distribution time.
    uint256 public constant distributionTime = 86400; 
    // Amount of currently locked tokens from all users (in lp).
    uint256 public totalLocked;

    // Auxiliary parameter (tpl) for locking's math
    uint256 private tokensPerLock;
    // Аuxiliary parameter for locking's math
    uint256 private rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 private allProduced;
    // Аuxiliary parameter for locking's math
    uint256 private producedTime;

    //period of locking after lock function call
    uint256 public depositLockDuration;
    //period of locking after unlock function call
    uint256 public withdrawLockDuration;

    // Amount of locked tokens waiting for withdraw (in Alluo).
    uint256 public waitingForWithdrawal;
    // Amount of currently claimed rewards by the users.
    uint256  public totalDistributed;
    // flag for allowing upgrade
    bool public upgradeStatus;

    //erc20-like interface
    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
    }

    TokenInfo private token;

    // Locker contains info related to each locker.
    struct Locker {
        uint256 amount; // Tokens currently locked to the contract and vote power (in lp)
        uint256 rewardAllowed; // Rewards allowed to be paid out
        uint256 rewardDebt; // Param is needed for correct calculation locker's share
        uint256 distributed; // Amount of distributed tokens
        uint256 unlockAmount; // Amount of tokens which is available to withdraw (in alluo)
        uint256 depositUnlockTime; // The time when tokens are available to unlock
        uint256 withdrawUnlockTime; // The time when tokens are available to withdraw
    }

    // Lockers info by token holders.
    mapping(address => Locker) public _lockers;

    // Contract that manages extra rewards in CVX tokens
    CvxDistributor public cvxDistributor;

    // old values available for claim from old vlAlluo contract
    mapping(address => uint256) public oldClaim;
    mapping(address => uint256) public oldWithdraw;

    // ERC20 token locked on the contract and earned by locker as reward.
    IERC20Upgradeable public constant alluoToken =
        IERC20Upgradeable(0x1E5193ccC53f25638Aa22a940af899B692e10B09);

    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20Upgradeable public constant alluoBalancerLp =
        IERC20Upgradeable(0x85Be1e46283f5f438D1f864c2d925506571d544f);
    IERC20Upgradeable public constant weth = 
        IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 public constant poolId =
        0x85be1e46283f5f438d1f864c2d925506571d544f0002000000000000000001aa;

    /**
     * @dev Emitted in `updateWithdrawLockDuration` when the lock time after unlock() was changed
     */
    event WithdrawLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `updateDepositLockDuration` when the lock time after lock() was changed
     */
    event DepositLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Emitted in `lock` when the user locked the tokens
     */
    event TokensLocked(
        address indexed sender,
        address tokenAddress, 
        uint256 tokenAmount, 
        uint256 time
    );

    /**
     * @dev Emitted in `unlock` when the user unbinded his locked tokens
     */
    event TokensUnlocked(
        address indexed sender,
        uint256 alluoAmount,
        uint256 time
    );
    
    /**
     * @dev Emitted in `withdraw` when the user withdrew his locked tokens from the contract
     */
    event TokensWithdrawed(
        address indexed sender,
        uint256 alluoAmount,
        uint256 time
    );

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event TokensClaimed(
        address indexed sender,
        uint256 alluoAmount, 
        uint256 time
    );

    // allows to see balances on etherscan  
    event Transfer(address indexed from, address indexed to, uint256 value);

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
        uint256 _rewardPerDistribution
    ) public initializer{
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Locking: not contract");

        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, _multiSigWallet);

        token = TokenInfo({
            name: "Vote Locked Alluo Token",
            symbol: "vlAlluo",
            decimals: 18
        });

        rewardPerDistribution = _rewardPerDistribution; 
        producedTime = block.timestamp;

        depositLockDuration = 86400 * 7; 
        withdrawLockDuration = 86400 * 5;
    }

    function decimals() public view returns (uint8) {
        return token.decimals;
    }

    function name() public view returns (string memory) {
        return token.name;
    }

    function symbol() public view returns (string memory) {
        return token.symbol;
    }

    /**
     * @dev Calculates the necessary parameters for locking
     * @return Totally produced rewards
     */
    function produced() private view returns (uint256) {
        return
            allProduced +
            (rewardPerDistribution * (block.timestamp - producedTime)) /
            distributionTime;
    }

    /**
     * @dev Updates the produced rewards parameter for locking
     */
    function update() public whenNotPaused {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalLocked > 0) {
                tokensPerLock =
                    tokensPerLock +
                    (producedNew * 1e20) /
                    totalLocked;
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    /**
     * @dev Locks specified amount Alluo tokens in the contract
     * @param _amount An amount of Alluo tokens to lock
     */
    function lock(uint256 _amount) public {

        Locker storage locker = _lockers[msg.sender];

        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (totalLocked > 0) {
            update();
        }

        locker.rewardDebt =
            locker.rewardDebt +
            ((_amount * tokensPerLock) / 1e20);
        totalLocked = totalLocked + _amount;
        locker.amount = locker.amount + _amount;
        locker.depositUnlockTime = block.timestamp + depositLockDuration;

        emit TokensLocked(msg.sender, address(alluoToken), _amount, block.timestamp);
        emit Transfer(address(0), msg.sender, _amount);

        cvxDistributor.receiveStakeInfo(msg.sender, _amount);
    }

    /**
     * @dev Migrates all balances from old contract
     * @param _users list of lockers from old contract
     * @param _amounts list of amounts each equal to the share of locker on old contract
     */
    function migrationLock(address[] memory _users, uint256[] memory _amounts) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint i = 0; i < _users.length; i++){
            Locker storage locker = _lockers[_users[i]];

            if (totalLocked > 0) {
                update();
            }

            locker.rewardDebt =
                locker.rewardDebt +
                ((_amounts[i] * tokensPerLock) / 1e20);
            totalLocked = totalLocked + _amounts[i];
            locker.amount = _amounts[i];
            locker.depositUnlockTime = block.timestamp + depositLockDuration;

            cvxDistributor.receiveStakeInfo(_users[i], _amounts[i]);

            emit TokensLocked(_users[i], address(0), _amounts[i], block.timestamp);
            emit Transfer(address(0), _users[i], _amounts[i]);
        }
    }

    /// @notice Migrate withdraw or claim debt for users who did not have vlAlluo from previous version
    /// @param _users user addresses to migrate
    /// @param _withdraw true if migrating withdrawals, false for claim
    function migrateWithdrawOrClaimValues(address[] memory _users, bool _withdraw) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IAlluoLockedV3 oldLocker = IAlluoLockedV3(0xF295EE9F1FA3Df84493Ae21e08eC2e1Ca9DebbAf);

        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];

            (
                uint256 locked_,
                uint256 unlockAmount_,
                uint256 claim_,
                ,
                uint256 withdrawUnlockTime_
            ) = oldLocker.getInfoByAddress(user);

            if (_withdraw && withdrawUnlockTime_ < block.timestamp) {
                oldWithdraw[user] = unlockAmount_;
            } 
            else if (!_withdraw) {
                require(locked_ == 0, "AlluoLockedV4: use migrationLock");
                oldClaim[user] = claim_;
            } 
        }
    }

    /**
     * @dev Unbinds specified amount of tokens
     * @param _amount An amount to unbid
     */
    function unlock(uint256 _amount) public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        require(
            locker.amount >= _amount,
            "Locking: not enough lp tokens" 
        );

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((_amount * tokensPerLock) / 1e20);
        locker.amount -= _amount;
        totalLocked -= _amount;

        waitingForWithdrawal += _amount;

        locker.unlockAmount += _amount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, _amount, block.timestamp);
        emit Transfer(msg.sender, address(0), _amount);

        cvxDistributor.receiveUnstakeInfo(msg.sender, _amount);
    }

    /**
     * @dev Unbinds all amount
     */
    function unlockAll() public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        uint256 amount = locker.amount;

        require(amount > 0, "Locking: not enough lp tokens");

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((amount * tokensPerLock) / 1e20);
        locker.amount = 0;
        totalLocked -= amount;

        waitingForWithdrawal += amount;

        locker.unlockAmount += amount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, amount, block.timestamp);
        emit Transfer(msg.sender, address(0), amount);

        cvxDistributor.receiveUnstakeInfo(msg.sender, amount);
    }

    /**
     * @dev Unlocks unbinded tokens and transfers them to locker's address
     */
    function withdraw() public whenNotPaused {
        Locker storage locker = _lockers[msg.sender];
        uint256 _oldWithdraw = oldWithdraw[msg.sender];

        if(_oldWithdraw != 0) {
            alluoToken.safeTransfer(msg.sender, _oldWithdraw);
            emit TokensWithdrawed(msg.sender, _oldWithdraw, block.timestamp);
            oldWithdraw[msg.sender] = 0;

            // to avoid tx revert, if there is no current unlocked amount
            if (locker.unlockAmount == 0 || block.timestamp >= locker.withdrawUnlockTime) {
                return;
            }
        }

        require(
            locker.unlockAmount > 0,
            "Locking: not enough tokens"
        );

        require(
            block.timestamp >= locker.withdrawUnlockTime,
            "Locking: tokens not available"
        );

        uint256 amount = locker.unlockAmount;
        locker.unlockAmount = 0;
        waitingForWithdrawal -= amount;

        alluoToken.safeTransfer(msg.sender, amount);
        emit TokensWithdrawed(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Сlaims available rewards
     */
    function claim() public {
        if (totalLocked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, tokensPerLock);
        uint256 oldReward = oldClaim[msg.sender];

        if (oldReward > 0) {
            alluoToken.safeTransfer(msg.sender, oldReward);
            emit TokensClaimed(msg.sender, oldReward, block.timestamp);
            oldClaim[msg.sender] = 0;

            // to avoid tx revert, if there is no current claim amount
            if (reward == 0) {
                return;
            }
        }

        // require(reward > 0, "Locking: Nothing to claim");
        if (reward > 0) {
            Locker storage locker = _lockers[msg.sender];

            locker.distributed = locker.distributed + reward;
            totalDistributed += reward;

            alluoToken.safeTransfer(msg.sender, reward);
            emit TokensClaimed(msg.sender, reward, block.timestamp);
        }

        cvxDistributor.claim(msg.sender);
    }

    /**
     * @dev Сalculates available reward
     * @param _locker Address of the locker
     * @param _tpl Tokens per lock parameter
     */
    function calcReward(address _locker, uint256 _tpl)
        private
        view
        returns (uint256 reward)
    {
        Locker storage locker = _lockers[_locker];

        reward =
            ((locker.amount * _tpl) / 1e20) +
            locker.rewardAllowed -
            locker.distributed -
            locker.rewardDebt;

        return reward;
    }

    /**
     * @dev Returns locker's available rewards
     * @param _locker Address of the locker
     * @return reward Available reward to claim
     */
    function getClaim(address _locker) public view returns (uint256 reward) {
        uint256 _tpl = tokensPerLock;
        if (totalLocked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tpl = _tpl + ((producedNew * 1e20) / totalLocked);
            }
        }
        reward = calcReward(_locker, _tpl);

        return reward;
    }

    /**
     * @dev Returns locker's available CVX rewards
     * @param locker Address of the locker
     * @return reward Available CVX reward to claim
     */
    function getClaimCvx(address locker) public view returns (uint256 reward) {
        return cvxDistributor.getClaim(locker);
    }

    /**
     * @dev Returns balance of the specified locker
     * @param _address Locker's address
     * @return amount of vote/locked tokens
     */
    function balanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].amount;
    }

    /**
     * @dev Returns unlocked balance of the specified locker
     * @param _address Locker's address
     * @return amount of unlocked tokens
     */
    function unlockedBalanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].unlockAmount;
    }

    /**
     * @dev Returns total amount of locked tokens (in lp)
     * @return amount of locked 
     */
    function totalSupply() external view returns (uint256 amount) {
        return totalLocked;
    }

    /**
     * @dev Returns information about the specified locker
     * @param _address Locker's address
     * @return locked_ Locked amount of tokens (in lp)
     * @return unlockAmount_ Unlocked amount of tokens (in Alluo)
     * @return claim_  Reward amount available to be claimed
     * @return claimCvx_  Reward amount of CVX LP available to be claimed
     * @return depositUnlockTime_ Timestamp when tokens will be available to unlock
     * @return withdrawUnlockTime_ Timestamp when tokens will be available to withdraw
     */
    function getInfoByAddress(address _address)
        external
        view
        returns (
            uint256 locked_,
            uint256 unlockAmount_,
            uint256 claim_,
            uint256 claimCvx_,
            uint256 depositUnlockTime_,
            uint256 withdrawUnlockTime_
        )
    {
        Locker memory locker = _lockers[_address];
        locked_ = locker.amount;
        unlockAmount_ = locker.unlockAmount;
        depositUnlockTime_ = locker.depositUnlockTime;
        withdrawUnlockTime_ = locker.withdrawUnlockTime;
        claim_ = getClaim(_address);
        claimCvx_ = cvxDistributor.getClaim(_address);

        return (
            locked_,
            unlockAmount_,
            claim_,
            claimCvx_,
            depositUnlockTime_,
            withdrawUnlockTime_
        );
    }

    /* ========== ADMIN CONFIGURATION ========== */

    ///@dev Pauses the locking
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    ///@dev Unpauses the locking
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Adds reward tokens to the contract
     * @param _amount Specifies the amount of tokens to be transferred to the contract
     */
    function addReward(uint256 _amount) external {
        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Sets amount of reward during `distributionTime`
     * @param _amount Sets total reward amount per `distributionTime`
     */
    function setReward(uint256 _amount) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        allProduced = produced();
        producedTime = block.timestamp;
        rewardPerDistribution = _amount;
        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Allows to update the time when the rewards are available to unlock
     * @param _depositLockDuration Date in unix timestamp format
     */
    function updateDepositLockDuration(uint256 _depositLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        depositLockDuration = _depositLockDuration;
        emit DepositLockDurationUpdated(_depositLockDuration, block.timestamp);
    }
    
    /**
     * @dev Allows to update the time when the rewards are available to withdraw
     * @param _withdrawLockDuration Date in unix timestamp format
     */
    function updateWithdrawLockDuration(uint256 _withdrawLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        withdrawLockDuration = _withdrawLockDuration;
        emit WithdrawLockDurationUpdated(_withdrawLockDuration, block.timestamp);
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {

        IERC20Upgradeable(withdrawToken).safeTransfer(to, amount);
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
     * @dev Set CVX rewards manager contract address
     * @param cvxDistributorAddress contract address
     */
    function setCvxDistributor(address cvxDistributorAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cvxDistributor = CvxDistributor(cvxDistributorAddress);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    { 
        require(upgradeStatus, "Locking: upgrade not allowed");
        upgradeStatus = false;
    } 
}