// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFSushi.sol";
import "./libraries/DateUtils.sol";

contract FSushiAirdropsVotingEscrow {
    using DateUtils for uint256;

    uint256 private constant INITIAL_SUPPLY_PER_WEEK = 5000e18;

    address public immutable votingEscrow;
    address public immutable fSushi;
    uint256 public immutable startWeek;
    uint256 public immutable votingEscrowInterval;

    uint256 public lastCheckpoint;
    mapping(address => uint256) public lastCheckpointOf;
    mapping(uint256 => uint256) public votingEscrowTotalSupply;

    error Expired();
    error Claimed();

    event Claim(
        address indexed account,
        uint256 amount,
        address indexed beneficiary,
        uint256 fromWeek,
        uint256 untilWeek
    );

    constructor(address _votingEscrow, address _fSushi) {
        votingEscrow = _votingEscrow;
        fSushi = _fSushi;
        startWeek = block.timestamp.toWeekNumber();
        votingEscrowInterval = IVotingEscrow(_votingEscrow).interval();
    }

    function claim(address beneficiary) external returns (uint256 amount) {
        IVotingEscrow(votingEscrow).checkpoint();

        uint256 from = lastCheckpointOf[msg.sender];
        if (from == 0) {
            from = startWeek;
        }
        uint256 until = block.timestamp.toWeekNumber() + 1;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (week >= until) break;

            uint256 weekStart = week.toTimestamp();
            uint256 balance = _votingEscrowBalanceOf(msg.sender, weekStart);
            uint256 totalSupply = _votingEscrowTotalSupply(weekStart);

            amount += ((INITIAL_SUPPLY_PER_WEEK >> (week - startWeek)) * balance) / totalSupply;

            unchecked {
                ++i;
            }
        }

        lastCheckpointOf[msg.sender] = until;

        if (amount > 0) {
            IFSushi(fSushi).mint(beneficiary, amount);

            emit Claim(msg.sender, amount, beneficiary, from, until);
        }
    }

    function _votingEscrowBalanceOf(address account, uint256 timestamp) internal view returns (uint256) {
        uint256 epoch = IVotingEscrow(votingEscrow).userPointEpoch(account);
        if (epoch == 0) return 0;
        else {
            (int128 bias, int128 slope, uint256 ts, ) = IVotingEscrow(votingEscrow).userPointHistory(account, epoch);
            unchecked {
                bias -= slope * int128(int256(timestamp - ts));
            }
            if (bias < 0) bias = 0;
            return uint256(uint128(bias));
        }
    }

    function _votingEscrowTotalSupply(uint256 timestamp) internal returns (uint256) {
        uint256 week = timestamp.toWeekNumber();
        if (week < lastCheckpoint) return votingEscrowTotalSupply[week];

        lastCheckpoint = timestamp.toWeekNumber() + 1;

        uint256 epoch = IVotingEscrow(votingEscrow).epoch();
        (int128 bias, int128 slope, uint256 ts, ) = IVotingEscrow(votingEscrow).pointHistory(epoch);
        uint256 t_i = (ts / votingEscrowInterval) * votingEscrowInterval;
        for (uint256 i; i < 255; i++) {
            t_i += votingEscrowInterval;
            int128 d_slope;
            if (t_i > timestamp) t_i = timestamp;
            else d_slope = IVotingEscrow(votingEscrow).slopeChanges(t_i);
            unchecked {
                bias -= slope * int128(int256(t_i - ts));
            }
            if (t_i == timestamp) break;
            slope += d_slope;
            ts = t_i;
        }

        if (bias < 0) bias = 0;
        uint256 totalSupply = uint256(uint128(bias));
        votingEscrowTotalSupply[week] = totalSupply;
        return totalSupply;
    }
}