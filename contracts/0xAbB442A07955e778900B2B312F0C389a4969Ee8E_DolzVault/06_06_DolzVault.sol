//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct Lock {
    address token;
    uint256 amount;
    uint128 withdrawalStart;
    uint64 withdrawPeriodDuration;
    uint64 withdrawPeriodNumber;
    uint256 withdrewAmount;
}

struct UserLock {
    address user;
    Lock lock;
}

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

contract DolzVault {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private users;

    mapping(address => Lock[]) private userToLocks;

    event Locked(
        address token,
        uint256 amount,
        uint256 cliffEnd,
        uint256 vestingPeriodDuration,
        uint256 vestingPeriodNumber,
        uint256 id
    );

    event Claimed(address user, address token, uint256 amount);

    event Burnt(address user, address token, uint256 amount);

    event BurntToDead(address user, address token, uint256 amount);

    event Transfered(address user, address token, uint256 amount, address to);

    /**
     * @notice Lock the user's token in the vault
     * @dev The tokens must have been approved first
     * @param token Address of the token being locked
     * @param amount Amount to be locked in the vault
     * @param cliffInDays Cliff duration before tokens can be unlocked
     * @param vestingPeriodInDays Vesting period duration
     * @param vestingPeriodNumber Number of periods required to unlock 100%
     */
    function lock(
        address token,
        uint256 amount,
        uint256 cliffInDays,
        uint256 vestingPeriodInDays,
        uint256 vestingPeriodNumber
    ) external {
        // Avoids dead lock
        require(
            (vestingPeriodInDays > 0 && vestingPeriodNumber > 0) ||
                vestingPeriodInDays == 0,
            "Vault : invalid params"
        );

        // Add the user to the enumerable set
        users.add(msg.sender);

        createLock(
            token,
            amount,
            uint128(block.timestamp + cliffInDays * 24 * 3600),
            uint64(vestingPeriodInDays * 24 * 3600),
            uint64(vestingPeriodNumber),
            msg.sender
        );

        // Actually transfer the locked funds
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function createLock(
        address token,
        uint256 amount,
        uint128 withdrawalStart,
        uint64 withdrawPeriodDuration,
        uint64 withdrawPeriodNumber,
        address user
    ) private {
        // Add the lock datas to the user's locks list
        userToLocks[user].push(
            Lock({
                token: token,
                amount: amount,
                withdrawalStart: withdrawalStart,
                withdrawPeriodDuration: withdrawPeriodDuration,
                withdrawPeriodNumber: withdrawPeriodNumber,
                withdrewAmount: 0
            })
        );

        // Emit the lock even
        emit Locked(
            token,
            amount,
            withdrawalStart,
            withdrawalStart,
            withdrawPeriodDuration,
            userToLocks[user].length - 1
        );
    }

    /**
     * @notice Returns the number of token that can be claimed back
     * @param _user Address of the user
     * @param lockId The index of the lock for this user
     * @dev lockId starts at 0
     * @return balance The amount that can be unlocked
     */
    function claimable(address _user, uint256 lockId)
        public
        view
        returns (uint256 balance)
    {
        Lock memory _lock = userToLocks[_user][lockId];

        if (block.timestamp < _lock.withdrawalStart) return 0;

        // In case just for cliff
        if (_lock.withdrawPeriodDuration == 0)
            return _lock.amount - _lock.withdrewAmount;

        // Computes the number of withdrawal periods that have passed
        uint256 periodsElapsed = (block.timestamp - _lock.withdrawalStart) /
            _lock.withdrawPeriodDuration +
            1;

        // Checks if all the withdrawal periods have passed
        if (periodsElapsed >= _lock.withdrawPeriodNumber) {
            // All the withdrawal periods have passed, so we send all the remaining claimable balance
            balance = _lock.amount - _lock.withdrewAmount;
        } else {
            // Computes how many tokens the user can withdraw per period
            uint256 withdrawableAmountPerPeriod = _lock.amount /
                _lock.withdrawPeriodNumber;

            // Computes how much the user can withdraw since the begining, minest the amount it already withdrew
            balance =
                withdrawableAmountPerPeriod *
                periodsElapsed -
                _lock.withdrewAmount;
        }
    }

    /**
     * @notice Allow to unlock some tokens
     * @param lockId The index of the lock for this user
     * @dev lockId starts at 0
     * @param _amount Amount to be unlocked from the vault
     */
    function claim(uint256 lockId, uint256 _amount) external {
        // Calculate how much can be retrieved by the user
        uint256 _claimable = claimable(msg.sender, lockId);
        // Check the amount is legit
        require(_amount <= _claimable, "Vault: Requested amount too high");

        // Load the lock
        Lock storage _lock = userToLocks[msg.sender][lockId];

        // Add the amount sent back to the user's withdrawn balance
        _lock.withdrewAmount += _amount;

        // Send the tokens back
        IERC20(_lock.token).safeTransfer(msg.sender, _amount);

        // Notify for monitoring
        emit Claimed(msg.sender, _lock.token, _amount);
    }

    /**
     * @notice Transfer from one lock to another owner
     * @param to Address of the user that will receive le lock (bob)
     * @param lockId The index of the lock to take the tokens from
     * @param amount The amount withdrawn from alice to bob
     * @dev lockId starts at 0
     */
    function transfer(
        address to,
        uint256 lockId,
        uint256 amount
    ) external {
        // Load Alice's lock
        Lock storage _lock = userToLocks[msg.sender][lockId];

        // Check Alice didn't claim yet, otherwise this will be a mess in the numbers
        require(_lock.withdrewAmount == 0, "Already started to claim");

        // We don't need to check if amout < locked since this would fail anyway
        _lock.amount -= amount;

        // Add the user to the enumerable set
        users.add(to);

        // Notify for monitoring
        emit Transfered(msg.sender, _lock.token, amount, to);

        // Create the lock for Bob
        createLock(
            _lock.token,
            amount,
            _lock.withdrawalStart,
            _lock.withdrawPeriodDuration,
            _lock.withdrawPeriodNumber,
            to
        );
    }

    /**
     * @notice Burn token by using the token's burn method
     * @param lockId The index of the lock to burn the tokens from
     * @param amount The amount to burn
     * @dev lockId starts at 0
     */
    function burn(uint256 lockId, uint256 amount) external {
        // Load Alice's lock
        Lock storage _lock = userToLocks[msg.sender][lockId];

        // Check Alice didn't claim yet, otherwise this will be a mess in the numbers
        require(_lock.withdrewAmount == 0, "Already started to claim");

        // We don't need to check if amout < locked since this would fail anyway
        _lock.amount -= amount;

        // Effectively burn the token
        IERC20Burnable(_lock.token).burn(amount);

        // Notify for monitoring
        emit Burnt(msg.sender, _lock.token, amount);
    }

    /**
     * @notice Burn token by sending them to the dead address
     * @param lockId The index of the lock to burn the tokens from
     * @param amount The amount to burn
     * @dev lockId starts at 0
     */
    function burnToDead(uint256 lockId, uint256 amount) external {
        // Load Alice's lock
        Lock storage _lock = userToLocks[msg.sender][lockId];

        // Check Alice didn't claim yet, otherwise this will be a mess in the numbers
        require(_lock.withdrewAmount == 0, "Already started to claim");

        // We don't need to check if amout < locked since this would fail anyway
        _lock.amount -= amount;

        // Effectively transfer the tokens to the dead address
        IERC20(_lock.token).safeTransfer(
            0x000000000000000000000000000000000000dEaD,
            amount
        );

        // Notify for monitoring
        emit BurntToDead(msg.sender, _lock.token, amount);
    }

    /**
     * @notice Returns the list of all users who locked at least once
     * @return The list of all users who locked at least once
     */
    function listAllUsers() external view returns (address[] memory) {
        return users.values();
    }

    /**
     * @notice Returns the list of all locks
     * @return The list of all locks
     */
    function listAllLocks() external view returns (UserLock[] memory) {
        uint256 size = 0;

        // Calculate size to allocate memory
        for (uint256 i = 0; i < users.length(); i++) {
            size += userToLocks[users.at(i)].length;
        }

        UserLock[] memory results = new UserLock[](size);

        // Iterate over all users
        uint256 counter = 0;
        for (uint256 i = 0; i < users.length(); i++) {
            Lock[] memory locks = userToLocks[users.at(i)];
            for (uint256 j = 0; j < locks.length; j++) {
                results[counter++] = UserLock({
                    user: users.at(i),
                    lock: locks[j]
                });
            }
        }

        return results;
    }

    /**
     * @notice Returns the list of all locks for a specific user
     * @param _user Address of the user
     * @return The list of locks
     */
    function listLocks(address _user) public view returns (Lock[] memory) {
        return userToLocks[_user];
    }

    /**
     * @notice Returns the list of all locks for the caller
     * @return The list of locks
     */
    function listMyLocks() external view returns (Lock[] memory) {
        return listLocks(msg.sender);
    }
}