// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a supervisor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the supervisor account will be the one that deploys the contract. This
 * can later be changed with {transferSupervisorOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlySupervisor`, which can be applied to your functions to restrict their use to
 * the supervisor.
 */
abstract contract Supervisable is Initializable, ContextUpgradeable {
    address private _supervisor;

    event SupervisorOwnershipTransferred(address indexed previouSupervisor, address indexed newSupervisor);

    function __Supervisable_init() internal onlyInitializing {
        __Supervisable_init_unchained();
    }

    function __Supervisable_init_unchained() internal onlyInitializing {
        _transferSupervisorOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current supervisor.
     */
    function supervisor() public view virtual returns (address) {
        return _supervisor;
    }

    /**
     * @dev Throws if called by any account other than the supervisor.
     */
    modifier onlySupervisor() {
        require(supervisor() == _msgSender(), "Supervisable: caller is not the supervisor");
        _;
    }

    /**
     * @dev Transfers supervisor ownership of the contract to a new account (`newSupervisor`).
     * Internal function without access restriction.
     */
    function _transferSupervisorOwnership(address newSupervisor) internal virtual {
        address oldSupervisor = _supervisor;
        _supervisor = newSupervisor;
        emit SupervisorOwnershipTransferred(oldSupervisor, newSupervisor);
    }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract Burnable is ContextUpgradeable {
    mapping(address => bool) private _burners;

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    /**
     * @dev Returns whether the address is burner.
     */
    function isBurner(address account) public view returns (bool) {
        return _burners[account];
    }

    /**
     * @dev Throws if called by any account other than the burner.
     */
    modifier onlyBurner() {
        require(_burners[_msgSender()], "Burnable: caller is not a burner");
        _;
    }

    /**
     * @dev Add burner, only owner can add burner.
     */
    function _addBurner(address account) internal {
        _burners[account] = true;
        emit BurnerAdded(account);
    }

    /**
     * @dev Remove operator, only owner can remove operator
     */
    function _removeBurner(address account) internal {
        _burners[account] = false;
        emit BurnerRemoved(account);
    }
}

/**
 * @dev Contract for freezing mechanism.
 * Owner can add freezed account.
 * Supervisor can remove freezed account.
 */
contract Freezable is ContextUpgradeable {
    mapping(address => bool) private _freezes;

    event Freezed(address indexed account);
    event Unfreezed(address indexed account);

    /**
     * @dev Freeze account, only owner can freeze
     */
    function _freeze(address account) internal {
        _freezes[account] = true;
        emit Freezed(account);
    }

    /**
     * @dev Unfreeze account, only supervisor can unfreeze
     */
    function _unfreeze(address account) internal {
        _freezes[account] = false;
        emit Unfreezed(account);
    }

    /**
     * @dev Returns whether the address is freezed.
     */
    function isFreezed(address account) public view returns (bool) {
        return _freezes[account];
    }
}

/**
 * @dev Contract for locking mechanism.
 * Locker can add and remove locked account.
 */
contract Lockable is ContextUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct TimeLock {
        uint256 amount;
        uint256 lockedAt;
        uint256 expiresAt;
    }

    struct VestingLock {
        uint256 amount;
        uint256 lockedAt;
        uint256 startsAt;
        uint256 period;
        uint256 count;
    }

    mapping(address => bool) private _lockers;
    mapping(address => TimeLock[]) private _timeLocks;
    mapping(address => VestingLock[]) private _vestingLocks;

    event LockerAdded(address indexed account);
    event LockerRemoved(address indexed account);
    event TimeLocked(address indexed account);
    event TimeUnlocked(address indexed account);
    event VestingLocked(address indexed account);
    event VestingUnlocked(address indexed account);
    event VestingUpdated(address indexed account, uint256 index);

    /**
     * @dev Throws if called by any account other than the locker.
     */
    modifier onlyLocker() {
        require(_lockers[_msgSender()], "Lockable: caller is not a locker");
        _;
    }

    /**
     * @dev Returns whether the address is locker.
     */
    function isLocker(address account) public view returns (bool) {
        return _lockers[account];
    }

    /**
     * @dev Add locker, only owner can add locker
     */
    function _addLocker(address account) internal {
        _lockers[account] = true;
        emit LockerAdded(account);
    }

    /**
     * @dev Remove locker, only owner can remove locker
     */
    function _removeLocker(address account) internal {
        _lockers[account] = false;
        emit LockerRemoved(account);
    }

    /**
     * @dev Add time lock, only locker can add
     */
    function _addTimeLock(
        address account,
        uint256 amount,
        uint256 expiresAt
    ) internal {
        require(amount > 0, "TimeLock: lock amount is 0");
        require(expiresAt > block.timestamp, "TimeLock: invalid expire date");
        _timeLocks[account].push(TimeLock(amount, block.timestamp, expiresAt));
        emit TimeLocked(account);
    }

    /**
     * @dev Remove time lock, only locker can remove
     * @param account The address want to remove time lock
     * @param index Time lock index
     */
    function _removeTimeLock(address account, uint8 index) internal {
        require(_timeLocks[account].length > index && index >= 0, "TimeLock: invalid index");

        uint256 len = _timeLocks[account].length;
        if (len - 1 != index) {
            // if it is not last item, swap it
            _timeLocks[account][index] = _timeLocks[account][len - 1];
        }
        _timeLocks[account].pop();
        emit TimeUnlocked(account);
    }

    /**
     * @dev Get time lock array length
     * @param account The address want to know the time lock length.
     * @return time lock length
     */
    function getTimeLockLength(address account) public view returns (uint256) {
        return _timeLocks[account].length;
    }

    /**
     * @dev Get time lock info
     * @param account The address want to know the time lock state.
     * @param index Time lock index
     * @return time lock info
     */
    function getTimeLock(address account, uint8 index) public view returns (uint256, uint256) {
        require(_timeLocks[account].length > index && index >= 0, "TimeLock: invalid index");
        return (_timeLocks[account][index].amount, _timeLocks[account][index].expiresAt);
    }

    function getAllTimeLocks(address account) public view returns (TimeLock[] memory) {
        require(account != address(0), "TimeLock: query for the zero address");
        return _timeLocks[account];
    }

    /**
     * @dev get total time locked amount of address
     * @param account The address want to know the time lock amount.
     * @return time locked amount
     */
    function getTimeLockedAmount(address account) public view returns (uint256) {
        uint256 timeLockedAmount = 0;

        uint256 len = _timeLocks[account].length;
        for (uint256 i = 0; i < len; i++) {
            if (block.timestamp < _timeLocks[account][i].expiresAt) {
                timeLockedAmount = timeLockedAmount + _timeLocks[account][i].amount;
            }
        }
        return timeLockedAmount;
    }

    /**
     * @dev Add vesting lock, only locker can add
     * @param account vesting lock account.
     * @param amount vesting lock amount.
     * @param startsAt vesting lock release start date.
     * @param period vesting lock period. End date is startsAt + (period - 1) * count
     * @param count vesting lock count. If count is 1, it works like a time lock
     */
    function _addVestingLock(
        address account,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) internal {
        require(account != address(0), "VestingLock: lock from the zero address");
        // require(startsAt > block.timestamp, "VestingLock: must set after now");
        require(period > 0, "VestingLock: period is 0");
        require(count > 0, "VestingLock: count is 0");
        _vestingLocks[account].push(VestingLock(amount, block.timestamp, startsAt, period, count));
        emit VestingLocked(account);
    }

    /**
     * @dev Remove vesting lock, only supervisor can remove
     * @param account The address want to remove the vesting lock
     */
    function _removeVestingLock(address account, uint256 index) internal {
        require(index < _vestingLocks[account].length, "Invalid index");

        if (index != _vestingLocks[account].length - 1) {
            _vestingLocks[account][index] = _vestingLocks[account][_vestingLocks[account].length - 1];
        }
        _vestingLocks[account].pop();
    }

    function _updateVestingLock(
        address account,
        uint256 index,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) internal {
        require(account != address(0), "VestingLock: lock from the zero address");
        // require(startsAt > block.timestamp, "VestingLock: must set after now");
        require(amount > 0, "VestingLock: amount is 0");
        require(period > 0, "VestingLock: period is 0");
        require(count > 0, "VestingLock: count is 0");

        VestingLock storage lock = _vestingLocks[account][index];
        lock.amount = amount;
        lock.startsAt = startsAt;
        lock.period = period;
        lock.count = count;

        emit VestingUpdated(account, index);
    }

    /**
     * @dev Get vesting lock info
     * @param account The address want to know the vesting lock state.
     * @return vesting lock info
     */
    function getVestingLock(address account, uint256 index) public view returns (VestingLock memory) {
        return _vestingLocks[account][index];
    }

    /**
     * @dev Get total vesting locked amount of address, locked amount will be released by 100%/months
     * If months is 5, locked amount released 20% per 1 month.
     * @param account The address want to know the vesting lock amount.
     * @return vesting locked amount
     */
    function getVestingLockedAmount(address account) public view returns (uint256) {
        uint256 vestingLockedAmount = 0;
        for (uint256 i = 0; i < _vestingLocks[account].length; i++) {
          VestingLock memory lock = _vestingLocks[account][i];
          
          uint256 amount = lock.amount;
          if (amount > 0) {
              uint256 startsAt = lock.startsAt;
              uint256 period = lock.period;
              uint256 count = lock.count;
              uint256 expiresAt = startsAt + period * (count);
              uint256 timestamp = block.timestamp;
              if (timestamp < startsAt) {
                  vestingLockedAmount += amount;
              } else if (timestamp < expiresAt) {
                  vestingLockedAmount += (amount * ((expiresAt - timestamp) / period)) / count;
              }
          }
        }
        return vestingLockedAmount;
    }

    /**
     * @dev Get all locked amount
     * @param account The address want to know the all locked amount
     * @return all locked amount
     */
    function getAllLockedAmount(address account) public view returns (uint256) {
        return getTimeLockedAmount(account) + getVestingLockedAmount(account);
    }

    function getAllVestingCount(address account) public view returns (uint256) {
        require(account != address(0), "VestingLock: query for the zero address");
        return _vestingLocks[account].length;
    }

    function getAllVestings(address account) public view returns (VestingLock[] memory) {
        require(account != address(0), "VestingLock: query for the zero address");
        return _vestingLocks[account];
    }
}

/**
 * @dev Contract for vesting, timelock enabled ERC-20 token
 */
contract TokenImplementation is Initializable, PausableUpgradeable, OwnableUpgradeable, Supervisable, Burnable, Freezable, Lockable, ERC20Upgradeable {

    function initialize(address owner, string memory name, string memory symbol, uint256 initialSupply) public initializer {
        __Ownable_init();
        __Supervisable_init();
        __ERC20_init(name, symbol);
        _mint(owner, initialSupply * 10 ** decimals());

        addLocker(owner);
        transferSupervisorOwnership(owner);
        transferOwnership(owner);
    }

    /**
     * @dev Recover ERC20 token in contract address.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverToken(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20Upgradeable(tokenAddress).transfer(owner(), tokenAmount);
    }

    /**
     * @dev lock and pause before transfer token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        require(!isFreezed(from), "Freezable: token transfer from freezed account");
        require(!isFreezed(to), "Freezable: token transfer to freezed account");
        require(!isFreezed(_msgSender()), "Freezable: token transfer called from freezed account");
        require(!paused(), "Pausable: token transfer while paused");
        if (from != address(0)) require(balanceOf(from) - getAllLockedAmount(from) >= amount, "Lockable: insufficient transfer amount");

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev only supervisor can renounce supervisor ownership
     */
    function renounceSupervisorOwnership() public onlySupervisor whenNotPaused {
        _transferSupervisorOwnership(address(0));
    }

    /**
     * @dev only supervisor can transfer supervisor ownership
     */
    function transferSupervisorOwnership(address newSupervisor) public onlySupervisor whenNotPaused {
        require(newSupervisor != address(0), "Supervisable: new supervisor is the zero address");
        _transferSupervisorOwnership(newSupervisor);
    }

    /**
     * @dev pause all coin transfer
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause all coin transfer
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev only owner can lock account
     */
    function freeze(address account) public onlyOwner whenNotPaused {
        _freeze(account);
    }

    /**
     * @dev only supervisor can unfreeze account
     */
    function unfreeze(address account) public onlySupervisor whenNotPaused {
        _unfreeze(account);
    }

    /**
     * @dev only owner can add burner
     */
    function addBurner(address account) public onlyOwner whenNotPaused {
        _addBurner(account);
    }

    /**
     * @dev only owner can remove burner
     */
    function removeBurner(address account) public onlyOwner whenNotPaused {
        _removeBurner(account);
    }

    /**
     * @dev burn burner's coin
     */
    function burn(uint256 amount) public onlyBurner whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev only owner can add locker
     */
    function addLocker(address account) public onlyOwner whenNotPaused {
        _addLocker(account);
    }

    /**
     * @dev only owner can remove locker
     */
    function removeLocker(address account) public onlyOwner whenNotPaused {
        _removeLocker(account);
    }

    /**
     * @dev only locker can add time lock
     */
    function addTimeLock(
        address account,
        uint256 amount,
        uint256 expiresAt
    ) public onlyLocker whenNotPaused {
        _addTimeLock(account, amount, expiresAt);
    }

    /**
     * @dev only supervisor can remove time lock
     */
    function removeTimeLock(address account, uint8 index) public onlySupervisor whenNotPaused {
        _removeTimeLock(account, index);
    }

    /**
     * @dev only locker can add vesting lock
     */
    function addVestingLock(
        address account,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyLocker whenNotPaused {
        require(amount > 0 && balanceOf(account) >= amount, "VestingLock: amount is 0 or over balance");
        _addVestingLock(account, amount, startsAt, period, count);
    }

    function updateVestingLock(
        address account,
        uint256 index,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyLocker whenNotPaused {
        _updateVestingLock(account, index, amount, startsAt, period, count);
    }

    /**
     * @dev only supervisor can remove vesting lock
     */
    function removeVestingLock(address account, uint index) public onlySupervisor whenNotPaused {
        _removeVestingLock(account, index);
    }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "EML: recipients and amounts length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }

    function vestedTransfer(
        address recipient,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyLocker whenNotPaused {
        // Transfer tokens to the recipient
        transfer(recipient, amount);

        // Add a vesting lock for the recipient
        addVestingLock(recipient, amount, startsAt, period, count);
    }

    function lockedTransfer(
        address recipient,
        uint256 amount,
        uint256 expiresAt
    ) public onlyLocker whenNotPaused {
        // Transfer tokens to the recipient
        transfer(recipient, amount);

        // Add a timed lock for the recipient
        addTimeLock(recipient, amount, expiresAt);
    }

    function batchVestedTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory startsAt,
        uint256[] memory periods,
        uint256[] memory counts
    ) public onlyLocker whenNotPaused {
        require(
            recipients.length == amounts.length &&
            ((recipients.length == startsAt.length && recipients.length == periods.length && recipients.length == counts.length) || 
            (startsAt.length == 1 && periods.length == 1 && counts.length == 1)),
            "EML: arrays must have the same length"
        );

        if (startsAt.length == 1 && periods.length == 1 && counts.length == 1) {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addVestingLock(
                    recipients[i],
                    amounts[i],
                    startsAt[0],
                    periods[0],
                    counts[0]
                );
            }
        } else {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addVestingLock(
                    recipients[i],
                    amounts[i],
                    startsAt[i],
                    periods[i],
                    counts[i]
                );
            }
        }
    }

    function batchTimeLockedTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory expiresAt
    ) public onlyLocker whenNotPaused {
        require(
            recipients.length == amounts.length &&
            ((recipients.length == expiresAt.length) || (expiresAt.length == 1)),
            "EML: arrays must have the same length"
        );

        if (expiresAt.length == 1) {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addTimeLock(
                    recipients[i],
                    amounts[i],
                    expiresAt[0]
                );
            }
        } else {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addTimeLock(
                    recipients[i],
                    amounts[i],
                    expiresAt[i]
                );
            }
        }
    }
}