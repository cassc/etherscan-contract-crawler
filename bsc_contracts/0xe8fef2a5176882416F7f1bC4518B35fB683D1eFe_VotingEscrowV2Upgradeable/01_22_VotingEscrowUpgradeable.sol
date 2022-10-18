// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWTF.sol";
import "./VeWTFUpgradeable.sol";
import "./PermissionsUpgradeable.sol";
import "./MultiplierUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IRewards {
    function stake(address account, uint256 _amount) external;

    function unstake(address account, uint256 _amount) external;

    function isPoolActive() external view returns (bool);
}

contract VotingEscrowV2Upgradeable is
    Initializable,
    PermissionsUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    VEWTFUpgradeable,
    MultiplierUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public wtf;
    IRewards public wtfRewards;
    IRewards public feeRewards;

    uint256 public MAX_LOCK_TIME;
    uint256 public MIN_LOCK_TIME;

    struct Lock {
        uint256 startTimestamp;
        uint256 expiryTimestamp;
        uint256 amount;
    }

    mapping(address => Lock) internal locks;
    mapping(address => bool) public whitelistedLockers;

    // Events

    event LockCreated(
        address indexed account,
        uint256 amount,
        uint256 startTimestamp,
        uint256 expiryTimestamp
    );
    event LockAmountIncreased(address indexed account, uint256 increasedAmount);
    event LockExtended(address indexed account, uint256 newExpiryTimestamp);
    event Unlocked(address indexed account, uint256 amount);
    event StakingSet(address wtfRewards, address feeRewards);
    event SetWhitelistedLocker(
        address indexed caller,
        address indexed addr,
        bool ok
    );
    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);

    modifier onlyWhitelistedLockers(address caller) {
        require(
            whitelistedLockers[caller],
            "WTF Voting Escrow:: Caller is not whitelisted"
        );
        _;
    }

    function init(
        address _wtf,
        address _governor,
        uint256 minLock,
        uint256 maxLock
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        Multiplier_init();
        Permissions_init(_governor);
        VeWTF_init("WTF Voting Escrow V2", "VeWTF V2");
        wtf = IERC20Upgradeable(_wtf);
        require(minLock > 0 && maxLock > 0, "Min or max lock data incorrect");
        MIN_LOCK_TIME = minLock;
        MAX_LOCK_TIME = maxLock;
    }

    function setStaking(address _wtfRewards, address _feeRewards)
        external
        onlyGovernor
    {
        require(
            _wtfRewards != address(0) && _feeRewards != address(0),
            "WTF Voting Escrow: staking zero address"
        );

        wtfRewards = IRewards(_wtfRewards);
        feeRewards = IRewards(_feeRewards);

        emit StakingSet(_wtfRewards, _feeRewards);
    }

    function createLock(uint256 _amount, uint256 _duration)
        external
        nonReentrant
    {
        _assertNotContract();
        _createLock(msg.sender, _amount, _duration);
    }

    function createLockFor(
        address _account,
        uint256 _amount,
        uint256 _duration
    ) external nonReentrant onlyWhitelistedLockers(msg.sender) {
        _createLock(_account, _amount, _duration);
    }

    /*
     * @notice: Creates a lock for WTF tokens if it does not exist yet
     * @param: _amount: amount of token to lock
     * @param: _duration: lock duration
     */

    function _createLock(
        address _account,
        uint256 _amount,
        uint256 _duration
    ) internal {
        Lock storage lock = locks[_account];

        require(_amount > 0, "WTF Voting Escrow: Lock amount is zero");
        require(lock.amount == 0, "WTF Voting Escrow: Lock already exists");
        require(
            _duration >= MIN_LOCK_TIME,
            "WTF Voting Escrow: Less than MIN_LOCK_TIME"
        );
        require(
            _duration <= MAX_LOCK_TIME,
            "WTF Voting Escrow: Greater than MAX_LOCK_TIME"
        );

        uint256 multiplier = getMultiplier(_duration);

        uint256 mint = _amount
            .mul(_duration)
            .mul(multiplier)
            .div(MAX_LOCK_TIME)
            .div(100);

        lock.startTimestamp = block.timestamp;
        lock.expiryTimestamp = lock.startTimestamp.add(_duration);
        lock.amount = _amount;

        wtf.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(_account, mint);
        _stake(_account, mint);

        emit LockCreated(
            _account,
            lock.amount,
            lock.startTimestamp,
            lock.expiryTimestamp
        );
    }

    function increaseLockDuration(uint256 _duration) external nonReentrant {
        _assertNotContract();
        _increaseLockDuration(msg.sender, _duration);
    }

    function increaseLockDurationFor(address account, uint256 _duration)
        external
        nonReentrant
        onlyWhitelistedLockers(msg.sender)
    {
        _increaseLockDuration(account, _duration);
    }

    function _increaseLockDuration(address account, uint256 _duration)
        internal
    {
        Lock storage lock = locks[account];
        require(lock.amount > 0, "WTF Voting Escrow: Lock does not exist");
        bool expired = _isLockExpired(account);

        uint256 mint;
        uint256 newExpiryTs;
        require(
            _duration >= MIN_LOCK_TIME,
            "WTF Voting Escrow: Less than minimum MIN_LOCK_TIME"
        );
        require(
            _duration <= MAX_LOCK_TIME,
            "WTF Voting Escrow: Greater than MAX_LOCK_TIME"
        );
        uint256 multiplier;
        if (expired) {
            multiplier = getMultiplier(_duration);
            newExpiryTs = block.timestamp.add(_duration);
            lock.startTimestamp = block.timestamp;
            mint = lock
                .amount
                .mul(_duration)
                .mul(multiplier)
                .div(MAX_LOCK_TIME)
                .div(100);
        } else {
            uint256 totalLockDuration = lock
                .expiryTimestamp
                .sub(lock.startTimestamp)
                .add(_duration);

            require(
                totalLockDuration <= MAX_LOCK_TIME,
                "WTF Voting Escrow: Greater than MAX_LOCK_TIME"
            );
            multiplier = getMultiplier(totalLockDuration);
            newExpiryTs = lock.expiryTimestamp.add(_duration);
            uint256 vewtfBal = balanceOf(account);
            uint256 total = lock
                .amount
                .mul(totalLockDuration)
                .mul(multiplier)
                .div(MAX_LOCK_TIME)
                .div(100);
            mint = total.sub(vewtfBal);
        }

        lock.expiryTimestamp = newExpiryTs;
        _mint(account, mint);
        _stake(account, mint);
    }

    function increaseAmountFor(address _account, uint256 _amount)
        external
        nonReentrant
        onlyWhitelistedLockers(msg.sender)
    {
        _increaseAmount(_account, _amount);
    }

    function increaseAmount(uint256 _amount) external nonReentrant {
        _assertNotContract();
        _increaseAmount(msg.sender, _amount);
    }

    /*
     * @notice: Add tokens to existing lock
     */

    function _increaseAmount(address account, uint256 _amount) internal {
        Lock storage lock = locks[account];

        require(_amount > 0, "WTF Voting Escrow: Amount should be positive");
        require(lock.amount > 0, "WTF Voting Escrow: Lock does not exist");

        // Lock should not be expired

        require(!_isLockExpired(account), "WTF Voting Escrow: Lock is expired");

        uint256 timeToExpiry = lock.expiryTimestamp.sub(block.timestamp);
        uint256 multiplier = getMultiplier(timeToExpiry);
        uint256 mint = _amount
            .mul(timeToExpiry)
            .mul(multiplier)
            .div(MAX_LOCK_TIME)
            .div(100);
        lock.amount = lock.amount.add(_amount);
        wtf.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(account, mint);
        _stake(account, mint);
        emit LockAmountIncreased(account, _amount);
    }

    function increaseTimeAndAmountFor(
        address _account,
        uint256 _amount,
        uint256 _newDuration
    ) external nonReentrant onlyWhitelistedLockers(msg.sender) {
        _increaseTimeAndAmount(_account, _amount, _newDuration);
    }

    function increaseTimeAndAmount(uint256 _amount, uint256 _newDuration)
        external
        nonReentrant
    {
        _assertNotContract();
        _increaseTimeAndAmount(msg.sender, _amount, _newDuration);
    }

    /*
     * @notice: Allows extending duration of existing locks and increasing amount of tokens locked
     * @param _amount: amount of tokens
     * @param _newExpiryTimestamp: when lock expires
     */

    function _increaseTimeAndAmount(
        address _account,
        uint256 _amount,
        uint256 _newDuration
    ) internal {
        Lock storage lock = locks[_account];
        require(lock.amount > 0, "WTF Voting Escrow: Lock does not exist");
        if (_newDuration > 0) {
            _increaseLockDuration(_account, _newDuration);
            emit LockExtended(_account, _newDuration);
        }
        if (_amount > 0) {
            _increaseAmount(_account, _amount);
            emit LockAmountIncreased(_account, _amount);
        }
    }

    /*
     * @notice Unlocks all tokens after lock expiry
     */

    function unlock() external nonReentrant {
        Lock storage lock = locks[msg.sender];
        uint256 wtfAmount = lock.amount;

        require(
            _isLockExpired(msg.sender),
            "WTF Voting Escrow: Cannot unlock tokens before expiry"
        );

        uint256 vewtfBal = balanceOf(msg.sender);
        require(vewtfBal > 0, "WTF Voting Escrow: VeWTF balance is zero");

        _burn(msg.sender, vewtfBal);
        _unstake(msg.sender, vewtfBal);
        wtf.safeTransfer(msg.sender, lock.amount);

        // Set lock to default values

        lock.amount = 0;
        lock.startTimestamp = 0;
        lock.expiryTimestamp = 0;

        emit Unlocked(msg.sender, wtfAmount);
    }

    function _stake(address account, uint256 amount) internal {
        if (address(wtfRewards) != address(0)) {
            if (wtfRewards.isPoolActive()) {
                wtfRewards.stake(account, amount);
            }
        }
        if (address(feeRewards) != address(0)) {
            if (feeRewards.isPoolActive()) {
                feeRewards.stake(account, amount);
            }
        }
    }

    function _unstake(address account, uint256 amount) internal {
        require(
            address(wtfRewards) != address(0),
            "WTF Voting Escrow: Zero address"
        );
        require(
            address(feeRewards) != address(0),
            "WTF Voting Escrow: Zero address"
        );
        wtfRewards.unstake(account, amount);
        feeRewards.unstake(account, amount);
    }

    function isLockExpired(address account) external view returns (bool) {
        return _isLockExpired(account);
    }

    function _isLockExpired(address account) internal view returns (bool) {
        Lock storage lock = locks[account];
        return (block.timestamp > lock.expiryTimestamp);
    }

    function _assertNotContract() private view {
        if (msg.sender != tx.origin) {
            revert("Smart contract depositors not allowed");
        } else {
            return;
        }
    }

    function getLockedAmount(address account) external view returns (uint256) {
        return locks[account].amount;
    }

    function totalLocked() external view returns (uint256) {
        return wtf.balanceOf(address(this));
    }

    function getLockData(address account)
        external
        view
        returns (Lock memory lock)
    {
        return locks[account];
    }

    function setWhitelistedLockers(address[] memory lockers, bool ok)
        external
        onlyGovernor
    {
        _setWhitelistedLockers(lockers, ok);
    }

    function _setWhitelistedLockers(address[] memory lockers, bool ok)
        internal
    {
        for (uint256 idx = 0; idx < lockers.length; idx++) {
            whitelistedLockers[lockers[idx]] = ok;
            emit SetWhitelistedLocker(msg.sender, lockers[idx], ok);
        }
    }

    function setMinMaxLockTime(uint256 min, uint256 max) external onlyGovernor {
        MIN_LOCK_TIME = min;
        MAX_LOCK_TIME = max;
    }

    function recoverWrongTokens(
        address to,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            _tokenAddress != address(wtf),
            "WTF Voting Escrow: Cannot be WTF token"
        );

        IERC20Upgradeable(_tokenAddress).safeTransfer(to, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}