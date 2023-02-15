// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/ITokenLockup.sol";

contract TokenLockup is Ownable, ITokenLockup {
    address public token;

    uint256 public startTime;
    uint256 public claimDelay;
    Schedule[] public schedule;

    mapping(address => uint256) public initialLocked;
    mapping(address => uint256) public totalClaimed;

    uint256 public initialLockedSupply;
    uint256 public unallocatedSupply;

    uint256 private constant INVERSE_BASIS_POINTS = 10_000;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _claimDelay,
        Schedule[] memory _schedule
    ) {
        require(_startTime >= block.timestamp, 'Invalid startTime');

        token = _token;
        startTime = _startTime;
        claimDelay = _claimDelay;

        uint256 scheduleLength = _schedule.length;
        uint256 totalPortion;
        for (uint256 i; i < scheduleLength; i++) {
            totalPortion += _schedule[i].portion;
            if (i != 0) {
                require(_schedule[i-1].endTime < _schedule[i].endTime, 'Invalid schedule times');
            }
            schedule.push(_schedule[i]);
        }
        require(totalPortion == INVERSE_BASIS_POINTS, 'Invalid schedule portions');
    }

    /**
     * @notice Transfers and locks unallocated tokens in escrow from msg.sender
     * @param amount Amount of tokens to lock in escrow
     */
    function addTokens(uint256 amount) external onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));
        unallocatedSupply += amount;
    }

    /**
     * @notice Distributes unallocated tokens to recipients
     * @param recipients List of addresses to distribute tokens to
     * @param amounts List of token amounts to distribute to recipient at respective index
     */
    function fund(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(recipients.length == amounts.length);
        uint256 _totalAmount = 0;
        for (uint i; i < amounts.length; ++i) {
            uint256 amount = amounts[i];
            address recipient = recipients[i];
            if (recipient == address(0)) {
                break;
            }
            _totalAmount += amount;
            initialLocked[recipient] += amount;
            emit Fund(recipient, amount);
        }
        initialLockedSupply += _totalAmount;
        unallocatedSupply -= _totalAmount;
    }

    /**
     * @notice Retrieves unclaimed unlocked tokens for msg.sender
     */
    function claim() external {
        require(block.timestamp > startTime + claimDelay, "Claiming is not available yet");

        uint256 claimable = _totalUnlockedOf(msg.sender) - totalClaimed[msg.sender];
        totalClaimed[msg.sender] += claimable;
        require(IERC20(token).transfer(msg.sender, claimable));

        emit Claim(msg.sender, claimable);
    }

    /**
     * @notice Changes the recipient of msg.sender funds
     * @param newRecipient New address to transfer the locked funds to
     */
    function changeRecipient(address newRecipient) external {
        require(newRecipient != msg.sender, "newRecipient must not be msg.sender");
        uint256 _initialLocked = initialLocked[msg.sender];
        uint256 _totalClaimed = totalClaimed[msg.sender];
        initialLocked[msg.sender] = 0;
        totalClaimed[msg.sender] = 0;
        initialLocked[newRecipient] += _initialLocked;
        totalClaimed[newRecipient] += _totalClaimed;

        emit ChangeRecipient(msg.sender, newRecipient);
    }

    /**
     * @notice Returns unclaimed unlocked balance for account
     * @param account Address to check balance of
     * @return Unclaimed unlocked balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _totalUnlockedOf(account) - totalClaimed[account];
    }

    /**
     * @notice Returns unlocked balance for account
     * @param account Address to check unlocked balance of
     * @return Unlocked balance
     */
    function unlockedOf(address account) external view returns (uint256) {
        return _totalUnlockedOf(account);
    }

    /**
     * @notice Returns locked balance for account
     * @param account Address to check unlocked balance of
     * @return Locked balance
     */
    function lockedOf(address account) external view returns (uint256) {
        return initialLocked[account] - _totalUnlockedOf(account);
    }

    /**
     * @notice Returns total unlocked supply
     * @return Total unlocked supply
     */
    function unlockedSupply() external view returns (uint256) {
        return _totalUnlocked();
    }

    /**
     * @notice Returns total supply that has not unlocked
     * @return Total locked supply
     */
    function lockedSupply() external view returns (uint256) {
        return initialLockedSupply - _totalUnlocked();
    }

    /**
     * @notice Returns unlocked balance for account at specified time
     * @param account Address to check unlocked balance of
     * @return Unlocked balance
     */
    function _totalUnlockedOf(address account) internal view returns (uint256) {
        uint256 locked = initialLocked[account];
        return _computeUnlocked(locked, block.timestamp);
    }

    /**
     * @notice Returns total unlocked supply
     * @return Total unlocked supply
     */
    function _totalUnlocked() internal view returns (uint256) {
        uint256 locked = initialLockedSupply;
        return _computeUnlocked(locked, block.timestamp);
    }

    /**
     * @notice Compute and return amount of initial locked tokens that have unlocked based on schedule
     * @param locked Initial locked tokens
     * @param time Time to check unlocked balance at
     * @return Amount of locked tokens that have unlocked
     */
    function _computeUnlocked(uint256 locked, uint256 time) internal view returns (uint256) {
        uint256 start = startTime;
        if (time < start) {
            return 0;
        }
        uint256 unlocked;
        uint256 scheduleLength = schedule.length;
        for (uint i; i < scheduleLength; i++) {
            uint256 portion = schedule[i].portion;
            uint256 end = schedule[i].endTime;
            if (time < end) {
                unlocked += locked * (time - start) * portion / ((end - start) * INVERSE_BASIS_POINTS);
                break;
            } else {
                unlocked += locked * portion / INVERSE_BASIS_POINTS;
                start = end;
            }
        }
        return unlocked;
    }
}