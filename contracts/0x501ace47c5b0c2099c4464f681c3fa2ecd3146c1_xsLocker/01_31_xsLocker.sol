// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./../utils/ERC721Enhanced.sol";
import "./../utils/Governable.sol";
import "./../interfaces/staking/IxsListener.sol";
import "./../interfaces/staking/IxsLocker.sol";


/**
 * @title xsLocker
 * @author solace.fi
 * @notice Stake your [**SOLACE**](./../SOLACE) to receive voting rights, [**SOLACE**](./../SOLACE) rewards, and more.
 *
 * Locks are ERC721s and can be viewed with [`locks()`](#locks). Each lock has an `amount` of [**SOLACE**](./../SOLACE) and an `end` timestamp and cannot be transferred or withdrawn from before it unlocks. Locks have a maximum duration of four years.
 *
 * Users can create locks via [`createLock()`](#createlock) or [`createLockSigned()`](#createlocksigned), deposit more [**SOLACE**](./../SOLACE) into a lock via [`increaseAmount()`](#increaseamount) or [`increaseAmountSigned()`](#increaseamountsigned), extend a lock via [`extendLock()`](#extendlock), and withdraw via [`withdraw()`](#withdraw), [`withdrawInPart()`](#withdrawinpart), or [`withdrawMany()`](#withdrawmany).
 *
 * Users and contracts (eg BondTellers) may deposit on behalf of another user or contract.
 *
 * Any time a lock is updated it will notify the listener contracts (eg StakingRewards).
 *
 * Note that transferring [**SOLACE**](./../SOLACE) to this contract will not give you any rewards. You should deposit your [**SOLACE**](./../SOLACE) via [`createLock()`](#createlock) or [`createLockSigned()`](#createlocksigned).
 */
// solhint-disable-next-line contract-name-camelcase
contract xsLocker is IxsLocker, ERC721Enhanced, ReentrancyGuard, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice [**SOLACE**](./../SOLACE) token.
    address public override solace;

    /// @notice The maximum time into the future that a lock can expire.
    uint256 public constant override MAX_LOCK_DURATION = 4 * (365 days);

    /// @notice The total number of locks that have been created.
    uint256 public override totalNumLocks;

    // Info on locks
    mapping(uint256 => Lock) private _locks;

    // Contracts that listen for lock changes
    EnumerableSet.AddressSet private _xsLockListeners;

    /**
     * @notice Construct the xsLocker contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param solace_ Address of [**SOLACE**](./../SOLACE).
     */
    constructor(address governance_, address solace_)
        ERC721Enhanced("xsolace lock", "xsLOCK")
        Governable(governance_)
    {
        require(solace_ != address(0x0), "zero address solace");
        solace = solace_;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Information about a lock.
     * @param xsLockID The ID of the lock to query.
     * @return lock_ Information about the lock.
     */
    function locks(uint256 xsLockID) external view override tokenMustExist(xsLockID) returns (Lock memory lock_) {
        return _locks[xsLockID];
    }

    /**
     * @notice Determines if the lock is locked.
     * @param xsLockID The ID of the lock to query.
     * @return locked True if the lock is locked, false if unlocked.
     */
    function isLocked(uint256 xsLockID) external view override tokenMustExist(xsLockID) returns (bool locked) {
        // solhint-disable-next-line not-rely-on-time
        return _locks[xsLockID].end > block.timestamp;
    }

    /**
     * @notice Determines the time left until the lock unlocks.
     * @param xsLockID The ID of the lock to query.
     * @return time The time left in seconds, 0 if unlocked.
     */
    function timeLeft(uint256 xsLockID) external view override tokenMustExist(xsLockID) returns (uint256 time) {
        // solhint-disable-next-line not-rely-on-time
        return (_locks[xsLockID].end > block.timestamp)
            // solhint-disable-next-line not-rely-on-time
            ? _locks[xsLockID].end - block.timestamp // locked
            : 0; // unlocked
    }

    /**
     * @notice Returns the amount of [**SOLACE**](./../SOLACE) the user has staked.
     * @param account The account to query.
     * @return balance The user's balance.
     */
    function stakedBalance(address account) external view override returns (uint256 balance) {
        uint256 numOfLocks = balanceOf(account);
        balance = 0;
        for (uint256 i = 0; i < numOfLocks; i++) {
            uint256 xsLockID = tokenOfOwnerByIndex(account, i);
            balance += _locks[xsLockID].amount;
        }
        return balance;
    }

    /**
     * @notice The list of contracts that are listening to lock updates.
     * @return listeners_ The list as an array.
     */
    function getXsLockListeners() external view override returns (address[] memory listeners_) {
        uint256 len = _xsLockListeners.length();
        listeners_ = new address[](len);
        for(uint256 index = 0; index < len; index++) {
            listeners_[index] = _xsLockListeners.at(index);
        }
        return listeners_;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit [**SOLACE**](./../SOLACE) to create a new lock.
     * @dev [**SOLACE**](./../SOLACE) is transferred from msg.sender, assumes its already approved.
     * @dev use end=0 to initialize as unlocked.
     * @param recipient The account that will receive the lock.
     * @param amount The amount of [**SOLACE**](./../SOLACE) to deposit.
     * @param end The timestamp the lock will unlock.
     * @return xsLockID The ID of the newly created lock.
     */
    function createLock(address recipient, uint256 amount, uint256 end) external override nonReentrant returns (uint256 xsLockID) {
        // pull solace
        SafeERC20.safeTransferFrom(IERC20(solace), msg.sender, address(this), amount);
        // accounting
        return _createLock(recipient, amount, end);
    }

    /**
     * @notice Deposit [**SOLACE**](./../SOLACE) to create a new lock.
     * @dev [**SOLACE**](./../SOLACE) is transferred from msg.sender using ERC20Permit.
     * @dev use end=0 to initialize as unlocked.
     * @dev recipient = msg.sender
     * @param amount The amount of [**SOLACE**](./../SOLACE) to deposit.
     * @param end The timestamp the lock will unlock.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return xsLockID The ID of the newly created lock.
     */
    function createLockSigned(uint256 amount, uint256 end, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override nonReentrant returns (uint256 xsLockID) {
        // permit
        IERC20Permit(solace).permit(msg.sender, address(this), amount, deadline, v, r, s);
        // pull solace
        SafeERC20.safeTransferFrom(IERC20(solace), msg.sender, address(this), amount);
        // accounting
        return _createLock(msg.sender, amount, end);
    }

    /**
     * @notice Deposit [**SOLACE**](./../SOLACE) to increase the value of an existing lock.
     * @dev [**SOLACE**](./../SOLACE) is transferred from msg.sender, assumes its already approved.
     * @param xsLockID The ID of the lock to update.
     * @param amount The amount of [**SOLACE**](./../SOLACE) to deposit.
     */
    function increaseAmount(uint256 xsLockID, uint256 amount) external override nonReentrant tokenMustExist(xsLockID) {
        // pull solace
        SafeERC20.safeTransferFrom(IERC20(solace), msg.sender, address(this), amount);
        // accounting
        uint256 newAmount = _locks[xsLockID].amount + amount;
        _updateLock(xsLockID, newAmount, _locks[xsLockID].end);
    }

    /**
     * @notice Deposit [**SOLACE**](./../SOLACE) to increase the value of an existing lock.
     * @dev [**SOLACE**](./../SOLACE) is transferred from msg.sender using ERC20Permit.
     * @param xsLockID The ID of the lock to update.
     * @param amount The amount of [**SOLACE**](./../SOLACE) to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function increaseAmountSigned(uint256 xsLockID, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override nonReentrant tokenMustExist(xsLockID) {
        // permit
        IERC20Permit(solace).permit(msg.sender, address(this), amount, deadline, v, r, s);
        // pull solace
        SafeERC20.safeTransferFrom(IERC20(solace), msg.sender, address(this), amount);
        // accounting
        uint256 newAmount = _locks[xsLockID].amount + amount;
        _updateLock(xsLockID, newAmount, _locks[xsLockID].end);
    }

    /**
     * @notice Extend a lock's duration.
     * @dev Can only be called by the lock owner or approved.
     * @param xsLockID The ID of the lock to update.
     * @param end The new time for the lock to unlock.
     */
    function extendLock(uint256 xsLockID, uint256 end) external override nonReentrant onlyOwnerOrApproved(xsLockID) {
        // solhint-disable-next-line not-rely-on-time
        require(end <= block.timestamp + MAX_LOCK_DURATION, "Max lock is 4 years");
        require(_locks[xsLockID].end <= end, "not extended");
        _updateLock(xsLockID, _locks[xsLockID].amount, end);
    }

    /**
     * @notice Withdraw from a lock in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev Can only be called if unlocked.
     * @param xsLockID The ID of the lock to withdraw from.
     * @param recipient The user to receive the lock's [**SOLACE**](./../SOLACE).
     */
    function withdraw(uint256 xsLockID, address recipient) external override nonReentrant onlyOwnerOrApproved(xsLockID) {
        uint256 amount = _locks[xsLockID].amount;
        _withdraw(xsLockID, amount);
        // transfer solace
        SafeERC20.safeTransfer(IERC20(solace), recipient, amount);
    }

    /**
     * @notice Withdraw from a lock in part.
     * @dev Can only be called by the lock owner or approved.
     * @dev Can only be called if unlocked.
     * @param xsLockID The ID of the lock to withdraw from.
     * @param recipient The user to receive the lock's [**SOLACE**](./../SOLACE).
     * @param amount The amount of [**SOLACE**](./../SOLACE) to withdraw.
     */
    function withdrawInPart(uint256 xsLockID, address recipient, uint256 amount) external override nonReentrant onlyOwnerOrApproved(xsLockID) {
        require(amount <= _locks[xsLockID].amount, "excess withdraw");
        _withdraw(xsLockID, amount);
        // transfer solace
        SafeERC20.safeTransfer(IERC20(solace), recipient, amount);
    }

    /**
     * @notice Withdraw from multiple locks in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev Can only be called if unlocked.
     * @param xsLockIDs The ID of the locks to withdraw from.
     * @param recipient The user to receive the lock's [**SOLACE**](./../SOLACE).
     */
    function withdrawMany(uint256[] calldata xsLockIDs, address recipient) external override nonReentrant {
        uint256 len = xsLockIDs.length;
        uint256 amount = 0;
        for(uint256 i = 0; i < len; i++) {
            uint256 xsLockID = xsLockIDs[i];
            require(_isApprovedOrOwner(msg.sender, xsLockID), "only owner or approved");
            uint256 amount_ = _locks[xsLockID].amount;
            amount += amount_;
            _withdraw(xsLockID, amount_);
        }
        // transfer solace
        SafeERC20.safeTransfer(IERC20(solace), recipient, amount);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new lock.
     * @param recipient The user that the lock will be minted to.
     * @param amount The amount of [**SOLACE**](./../SOLACE) in the lock.
     * @param end The end of the lock.
     * @param xsLockID The ID of the new lock.
     */
    function _createLock(address recipient, uint256 amount, uint256 end) internal returns (uint256 xsLockID) {
        xsLockID = ++totalNumLocks;
        Lock memory newLock = Lock(amount, end);
        // solhint-disable-next-line not-rely-on-time
        require(newLock.end <= block.timestamp + MAX_LOCK_DURATION, "Max lock is 4 years");
        // accounting
        _locks[xsLockID] = newLock;
        _safeMint(recipient, xsLockID);
        emit LockCreated(xsLockID);
    }

    /**
     * @notice Updates an existing lock.
     * @param xsLockID The ID of the lock to update.
     * @param amount The amount of [**SOLACE**](./../SOLACE) now in the lock.
     * @param end The end of the lock.
     */
    function _updateLock(uint256 xsLockID, uint256 amount, uint256 end) internal {
        // checks
        Lock memory prevLock = _locks[xsLockID];
        Lock memory newLock = Lock(amount, end); // end was sanitized before passed in
        // accounting
        _locks[xsLockID] = newLock;
        address owner = ownerOf(xsLockID);
        _notify(xsLockID, owner, owner, prevLock, newLock);
        emit LockUpdated(xsLockID, amount, newLock.end);
    }

    /**
     * @notice Withdraws from a lock.
     * @param xsLockID The ID of the lock to withdraw from.
     * @param amount The amount of [**SOLACE**](./../SOLACE) to withdraw.
     */
    function _withdraw(uint256 xsLockID, uint256 amount) internal {
        // solhint-disable-next-line not-rely-on-time
        require(_locks[xsLockID].end <= block.timestamp, "locked"); // cannot withdraw while locked
        // accounting
        if(amount == _locks[xsLockID].amount) {
            _burn(xsLockID);
            delete _locks[xsLockID];
        }
        else {
            Lock memory oldLock = _locks[xsLockID];
            Lock memory newLock = Lock(oldLock.amount-amount, oldLock.end);
            _locks[xsLockID].amount -= amount;
            address owner = ownerOf(xsLockID);
            _notify(xsLockID, owner, owner, oldLock, newLock);
        }
        emit Withdrawl(xsLockID, amount);
    }

    /**
     * @notice Hook that is called after any token transfer. This includes minting and burning.
     * @param from The user that sends the token, or zero if minting.
     * @param to The zero that receives the token, or zero if burning.
     * @param xsLockID The ID of the token being transferred.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 xsLockID
    ) internal override {
        super._afterTokenTransfer(from, to, xsLockID);
        Lock memory lock = _locks[xsLockID];
        // notify listeners
        if(from == address(0x0)) _notify(xsLockID, from, to, Lock(0, 0), lock); // mint
        else if(to == address(0x0)) _notify(xsLockID, from, to, lock, Lock(0, 0)); // burn
        else { // transfer
            // solhint-disable-next-line not-rely-on-time
            require(lock.end <= block.timestamp, "locked"); // cannot transfer while locked
            _notify(xsLockID, from, to, lock, lock);
        }
    }

    /**
     * @notice Notify the listeners of any updates.
     * @dev Called on transfer, mint, burn, and update.
     * Either the owner will change or the lock will change, not both.
     * @param xsLockID The ID of the lock that was altered.
     * @param oldOwner The old owner of the lock.
     * @param newOwner The new owner of the lock.
     * @param oldLock The old lock data.
     * @param newLock The new lock data.
     */
    function _notify(uint256 xsLockID, address oldOwner, address newOwner, Lock memory oldLock, Lock memory newLock) internal {
        // register action with listener
        uint256 len = _xsLockListeners.length();
        for(uint256 i = 0; i < len; i++) {
            IxsListener(_xsLockListeners.at(i)).registerLockEvent(xsLockID, oldOwner, newOwner, oldLock, newLock);
        }
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener The listener to add.
     */
    function addXsLockListener(address listener) external override onlyGovernance {
        _xsLockListeners.add(listener);
        emit xsLockListenerAdded(listener);
    }

    /**
     * @notice Removes a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener The listener to remove.
     */
    function removeXsLockListener(address listener) external override onlyGovernance {
        _xsLockListeners.remove(listener);
        emit xsLockListenerRemoved(listener);
    }

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external override onlyGovernance {
        _setBaseURI(baseURI_);
    }
}