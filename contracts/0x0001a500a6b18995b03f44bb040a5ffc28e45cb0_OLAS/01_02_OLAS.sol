// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../lib/solmate/src/tokens/ERC20.sol";

/// @dev Only `manager` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param manager Required sender address as a manager.
error ManagerOnly(address sender, address manager);

/// @dev Provided zero address.
error ZeroAddress();

/// @title OLAS - Smart contract for the OLAS token.
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract OLAS is ERC20 {
    event MinterUpdated(address indexed minter);
    event OwnerUpdated(address indexed owner);

    // One year interval
    uint256 public constant oneYear = 1 days * 365;
    // Total supply cap for the first ten years (one billion OLAS tokens)
    uint256 public constant tenYearSupplyCap = 1_000_000_000e18;
    // Maximum annual inflation after first ten years
    uint256 public constant maxMintCapFraction = 2;
    // Initial timestamp of the token deployment
    uint256 public immutable timeLaunch;

    // Owner address
    address public owner;
    // Minter address
    address public minter;

    constructor() ERC20("Autonolas", "OLAS", 18) {
        owner = msg.sender;
        minter = msg.sender;
        timeLaunch = block.timestamp;
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        if (msg.sender != owner) {
            revert ManagerOnly(msg.sender, owner);
        }

        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes the minter address.
    /// @param newMinter Address of a new minter.
    function changeMinter(address newMinter) external {
        if (msg.sender != owner) {
            revert ManagerOnly(msg.sender, owner);
        }

        if (newMinter == address(0)) {
            revert ZeroAddress();
        }

        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    /// @dev Mints OLAS tokens.
    /// @param account Account address.
    /// @param amount OLAS token amount.
    function mint(address account, uint256 amount) external {
        // Access control
        if (msg.sender != minter) {
            revert ManagerOnly(msg.sender, minter);
        }

        // Check the inflation schedule and mint
        if (inflationControl(amount)) {
            _mint(account, amount);
        }
    }

    /// @dev Provides various checks for the inflation control.
    /// @param amount Amount of OLAS to mint.
    /// @return True if the amount request is within inflation boundaries.
    function inflationControl(uint256 amount) public view returns (bool) {
        uint256 remainder = inflationRemainder();
        return (amount <= remainder);
    }

    /// @dev Gets the reminder of OLAS possible for the mint.
    /// @return remainder OLAS token remainder.
    function inflationRemainder() public view returns (uint256 remainder) {
        uint256 _totalSupply = totalSupply;
        // Current year
        uint256 numYears = (block.timestamp - timeLaunch) / oneYear;
        // Calculate maximum mint amount to date
        uint256 supplyCap = tenYearSupplyCap;
        // After 10 years, adjust supplyCap according to the yearly inflation % set in maxMintCapFraction
        if (numYears > 9) {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            for (uint256 i = 0; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }
        }
        // Check for the requested mint overflow
        remainder = supplyCap - _totalSupply;
    }

    /// @dev Burns OLAS tokens.
    /// @param amount OLAS token amount to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @dev Decreases the allowance of another account over their tokens.
    /// @param spender Account that tokens are approved for.
    /// @param amount Amount to decrease approval by.
    /// @return True if the operation succeeded.
    function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        if (spenderAllowance != type(uint256).max) {
            spenderAllowance -= amount;
            allowance[msg.sender][spender] = spenderAllowance;
            emit Approval(msg.sender, spender, spenderAllowance);
        }

        return true;
    }

    /// @dev Increases the allowance of another account over their tokens.
    /// @param spender Account that tokens are approved for.
    /// @param amount Amount to increase approval by.
    /// @return True if the operation succeeded.
    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        spenderAllowance += amount;
        allowance[msg.sender][spender] = spenderAllowance;
        emit Approval(msg.sender, spender, spenderAllowance);

        return true;
    }
}