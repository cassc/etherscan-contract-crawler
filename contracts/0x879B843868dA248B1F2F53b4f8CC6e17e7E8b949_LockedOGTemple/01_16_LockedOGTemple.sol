pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OGTemple.sol";

/**
 * Bookkeeping for OGTemple that's locked
 */
contract LockedOGTemple {
    struct LockedEntry {
        // How many tokens are locked
        uint256 BalanceOGTemple;

        // WHen can the user unlock these tokens
        uint256 LockedUntilTimestamp;
    }

    // All temple locked for any given user
    mapping(address => LockedEntry[]) public locked;

    OGTemple public OG_TEMPLE; // The token being staked, for which TEMPLE rewards are generated

    event OGTempleLocked(address _staker, uint256 _amount, uint256 _lockedUntil);
    event OGTempleWithdraw(address _staker, uint256 _amount);

    constructor(OGTemple _OG_TEMPLE) {
        OG_TEMPLE = _OG_TEMPLE;
    }

    function numLocks(address _staker) external view returns(uint256) {
        return locked[_staker].length;
    }

    /** lock up OG */
    function lockFor(address _staker, uint256 _amountOGTemple, uint256 _lockedUntilTimestamp) public {
        LockedEntry memory lockEntry = LockedEntry({BalanceOGTemple: _amountOGTemple, LockedUntilTimestamp: _lockedUntilTimestamp});
        locked[_staker].push(lockEntry);

        SafeERC20.safeTransferFrom(OG_TEMPLE, msg.sender, address(this), _amountOGTemple);
        emit OGTempleLocked(_staker, _amountOGTemple, _lockedUntilTimestamp);
    }

    function lock(uint256 _amountOGTemple, uint256 _lockedUntilTimestamp) external {
        lockFor(msg.sender, _amountOGTemple, _lockedUntilTimestamp);
    }

    /** Withdraw a specific locked entry */
    function withdrawFor(address _staker, uint256 _idx) public {
        LockedEntry[] storage lockedEntries = locked[_staker];

        require(_idx < lockedEntries.length, "No lock entry at the specified index");
        require(lockedEntries[_idx].LockedUntilTimestamp < block.timestamp, "Specified entry is still locked");

        LockedEntry memory entry = lockedEntries[_idx];

        lockedEntries[_idx] = lockedEntries[lockedEntries.length-1];
        lockedEntries.pop();

        SafeERC20.safeTransfer(OG_TEMPLE, _staker, entry.BalanceOGTemple);
        emit OGTempleWithdraw(_staker, entry.BalanceOGTemple);
    }

    function withdraw(uint256 _idx) external {
        withdrawFor(msg.sender, _idx);
    }
}