// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IErrors.sol";

/// @title Burnable Locked OLAS Token - OLAS burnable contract
/// @author Aleksandr Kuperman - <[email protected]>

// Interface for IOLAS burn functionality
interface IOLAS {
    /// @dev Burns OLAS tokens.
    /// @param amount OLAS token amount to burn.
    function burn(uint256 amount) external;
}

// Struct for storing balance, lock and unlock time
// The struct size is one storage slot of uint256 (96 + 96 + 32 + 32)
struct LockedBalance {
    // Token amount locked. Initial OLAS cap is 1 bn tokens, or 1e27.
    // After 10 years, the inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 totalAmount;
    // Token amount transferred to its owner. It is of the value of at most the total amount locked
    uint96 transferredAmount;
    // Lock time start
    uint32 startTime;
    // Lock end time
    // 2^32 - 1 is enough to count 136 years starting from the year of 1970. This counter is safe until the year of 2106
    uint32 endTime;
}

/// @notice This token supports the ERC20 interface specifications except for transfers.
contract buOLAS is IErrors, IERC20, IERC165 {
    event Lock(address indexed account, uint256 amount, uint256 startTime, uint256 endTime);
    event Withdraw(address indexed account, uint256 amount, uint256 ts);
    event Revoke(address indexed account, uint256 amount, uint256 ts);
    event Burn(address indexed account, uint256 amount, uint256 ts);
    event Supply(uint256 previousSupply, uint256 currentSupply);
    event OwnerUpdated(address indexed owner);

    // Locking step time
    uint32 internal constant STEP_TIME = 365 * 86400;
    // Maximum number of steps
    uint32 internal constant MAX_NUM_STEPS = 10;
    // Total token supply
    uint256 public supply;
    // Number of decimals
    uint8 public constant decimals = 18;

    // Token address
    address public immutable token;
    // Owner address
    address public owner;
    // Mapping of account address => LockedBalance
    mapping(address => LockedBalance) public mapLockedBalances;

    // Token name
    string public name;
    // Token symbol
    string public symbol;

    /// @dev Contract constructor
    /// @param _token Token address.
    /// @param _name Token name.
    /// @param _symbol Token symbol.
    constructor(address _token, string memory _name, string memory _symbol)
    {
        token = _token;
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Deposits `amount` tokens for the `account` and locks for the `numSteps` time periods.
    /// @notice Tokens are taken from `msg.sender`'s balance.
    /// @param account Target account address.
    /// @param amount Amount to deposit.
    /// @param numSteps Number of locking steps.
    function createLockFor(address account, uint256 amount, uint256 numSteps) external {
        // Check if the account is zero
        if (account == address(0)) {
            revert ZeroAddress();
        }
        // Check if the amount is zero
        if (amount == 0) {
            revert ZeroValue();
        }
        // The locking makes sense for one step or more only
        if (numSteps == 0) {
            revert ZeroValue();
        }
        // Check the maximum number of steps
        if (numSteps > MAX_NUM_STEPS) {
            revert Overflow(numSteps, MAX_NUM_STEPS);
        }
        // Lock time is equal to the number of fixed steps multiply on a step time
        uint256 unlockTime = block.timestamp + uint256(STEP_TIME) * numSteps;
        // Max of 2^32 - 1 value, the counter is safe until the year of 2106
        if (unlockTime > type(uint32).max) {
            revert Overflow(unlockTime, type(uint32).max);
        }
        // After 10 years, the inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1 total supply
        if (amount > type(uint96).max) {
            revert Overflow(amount, type(uint96).max);
        }

        LockedBalance memory lockedBalance = mapLockedBalances[account];
        // The locked balance must be zero in order to start the lock
        if (lockedBalance.totalAmount > 0) {
            revert LockedValueNotZero(account, lockedBalance.totalAmount);
        }

        // Store the locked information for the account
        lockedBalance.startTime = uint32(block.timestamp);
        lockedBalance.endTime = uint32(unlockTime);
        lockedBalance.totalAmount = uint96(amount);
        mapLockedBalances[account] = lockedBalance;

        // Calculate total supply
        uint256 supplyBefore = supply;
        uint256 supplyAfter;
        // Cannot overflow because we do not add more tokens than the OLAS supply
        unchecked {
            supplyAfter = supplyBefore + amount;
            supply = supplyAfter;
        }

        // OLAS is a solmate-based ERC20 token with optimized transferFrom() that either returns true or reverts
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Lock(account, amount, block.timestamp, unlockTime);
        emit Supply(supplyBefore, supplyAfter);
    }

    /// @dev Releases all matured tokens for `msg.sender`.
    function withdraw() external {
        LockedBalance memory lockedBalance = mapLockedBalances[msg.sender];
        // If the balances are still active and not fully withdrawn, start time must be greater than zero
        if (lockedBalance.startTime > 0) {
            // Calculate the amount to release
            uint256 amount = _releasableAmount(lockedBalance);
            // Check if at least one locking step has passed
            if (amount == 0) {
                revert LockNotExpired(msg.sender, lockedBalance.endTime, block.timestamp);
            }

            uint256 supplyBefore = supply;
            uint256 supplyAfter = supplyBefore;
            // End time is greater than zero if withdraw was not fully completed and `revoke` was not called on the account
            if (lockedBalance.endTime > 0) {
                unchecked {
                    // Update the account locked amount.
                    // Cannot practically overflow since the amount to release is smaller than the locked amount
                    lockedBalance.transferredAmount += uint96(amount);
                }
                // The balance is fully unlocked. Released amount must be equal to the locked one
                if ((lockedBalance.transferredAmount + 1) > lockedBalance.totalAmount) {
                    mapLockedBalances[msg.sender] = LockedBalance(0, 0, 0, 0);
                } else {
                    mapLockedBalances[msg.sender] = lockedBalance;
                }
            } else {
                // This means revoke has been called on this account and some tokens must be burned
                uint256 amountBurn = uint256(lockedBalance.totalAmount);
                // Burn revoked tokens
                if (amountBurn > 0) {
                    IOLAS(token).burn(amountBurn);
                    // Update total supply
                    unchecked {
                        // Amount to burn cannot be bigger than the supply before the burn
                        supplyAfter = supplyBefore - amountBurn;
                    }
                    emit Burn(msg.sender, amountBurn, block.timestamp);
                }
                // Set all the data to zero
                mapLockedBalances[msg.sender] = LockedBalance(0, 0, 0, 0);
            }

            // The amount cannot be bigger than the total supply
            unchecked {
                supplyAfter -= amount;
                supply = supplyAfter;
            }

            emit Withdraw(msg.sender, amount, block.timestamp);
            emit Supply(supplyBefore, supplyAfter);

            // OLAS is a solmate-based ERC20 token with optimized transfer() that either returns true or reverts
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    /// @dev Revoke and burn all non-matured tokens from the `account`.
    /// @param accounts Account addresses.
    function revoke(address[] memory accounts) external {
        // Check for the ownership
        if (owner != msg.sender) {
            revert OwnerOnly(msg.sender, owner);
        }

        for (uint256 i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            LockedBalance memory lockedBalance = mapLockedBalances[account];

            // Get the amount to release
            uint256 amountRelease = _releasableAmount(lockedBalance);
            // Amount locked now represents the burn amount, which can not become less than zero
            unchecked {
                lockedBalance.totalAmount -= (uint96(amountRelease) + lockedBalance.transferredAmount);
            }
            // This is the release amount that will be transferred to the account when they withdraw
            lockedBalance.transferredAmount = uint96(amountRelease);
            // Termination state of the revoke procedure
            lockedBalance.endTime = 0;
            // Update the account data
            mapLockedBalances[account] = lockedBalance;

            emit Revoke(account, uint256(lockedBalance.totalAmount), block.timestamp);
        }
    }

    /// @dev Gets the account locking balance.
    /// @param account Account address.
    /// @return balance Account balance.
    function balanceOf(address account) public view override returns (uint256 balance) {
        LockedBalance memory lockedBalance = mapLockedBalances[account];
        // If the end is equal 0, this balance is either left after revoke or expired
        if (lockedBalance.endTime == 0) {
            // The maximum balance in this case is the released amount value
            balance = uint256(lockedBalance.transferredAmount);
        } else {
            // Otherwise the balance is the difference between locked and released amounts
            balance = uint256(lockedBalance.totalAmount - lockedBalance.transferredAmount);
        }
    }

    /// @dev Gets total token supply.
    /// @return Total token supply.
    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    /// @dev Gets the account releasable amount.
    /// @param account Account address.
    /// @return amount Amount to release.
    function releasableAmount(address account) external view returns (uint256 amount) {
        LockedBalance memory lockedBalance = mapLockedBalances[account];
        amount = _releasableAmount(lockedBalance);
    }

    /// @dev Gets the account releasable amount.
    /// @param lockedBalance Account locked balance struct.
    /// @return amount Amount to release.
    function _releasableAmount(LockedBalance memory lockedBalance) private view returns (uint256 amount) {
        // If the end is equal 0, this balance is either left after revoke or expired
        if (lockedBalance.endTime == 0) {
            return lockedBalance.transferredAmount;
        }
        // Number of steps
        uint32 numSteps;
        // Current locked time
        uint32 releasedSteps;
        // Time in the future will be greater than the start time
        unchecked {
            numSteps = (lockedBalance.endTime - lockedBalance.startTime) / STEP_TIME;
            releasedSteps = (uint32(block.timestamp) - lockedBalance.startTime) / STEP_TIME;
        }

        // If the number of release steps is greater or equal to the number of steps, all the available tokens are unlocked
        if ((releasedSteps + 1) > numSteps) {
            // Return the remainder from the last release since it's the last one
            unchecked {
                amount = uint256(lockedBalance.totalAmount - lockedBalance.transferredAmount);
            }
        } else {
            // Calculate the amount to release
            unchecked {
                amount = uint256(lockedBalance.totalAmount * releasedSteps / numSteps);
                amount -= uint256(lockedBalance.transferredAmount);
            }
        }
    }

    /// @dev Gets the `account`'s locking end time.
    /// @param account Account address.
    /// @return unlockTime Maturity time.
    function lockedEnd(address account) external view returns (uint256 unlockTime) {
        unlockTime = uint256(mapLockedBalances[account].endTime);
    }

    /// @dev Gets information about the interface support.
    /// @param interfaceId A specified interface Id.
    /// @return True if this contract implements the interface defined by interfaceId.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @dev Reverts the transfer of this token.
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the approval of this token.
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the transferFrom of this token.
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the allowance of this token.
    function allowance(address owner, address spender) external view virtual override returns (uint256)
    {
        revert NonTransferable(address(this));
    }
}