//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


// Inheritance
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Owned.sol";

/// @title   Umbrella Rewards contract
/// @author  umb.network
/// @notice  This contract serves TOKEN DISTRIBUTION AT LAUNCH for:
///           - node, founders, early contributors etc...
///          It can be used for future distributions for next milestones also
///          as its functionality stays the same.
///          It supports linear vesting
/// @dev     Deploy contract. Mint tokens reward for this contract.
///          Then as owner call .setupDistribution() and then start()
contract LinearVesting is Owned {
    using SafeMath for uint256;

    struct Reward {
        uint256 total;
        uint256 duration;
        uint256 paid;
        uint256 startTime;
    }

    uint8 public constant VERSION = 2;

    IERC20 public immutable umbToken;
    uint256 public totalVestingAmount;

    mapping(address => Reward) public rewards;

    // ========== EVENTS ========== //

    event LogSetup(uint256 prevSum, uint256 newSum);
    event LogClaimed(address indexed recipient, uint256 amount);

    // ========== CONSTRUCTOR ========== //

    constructor(address _owner, address _token) Owned(_owner) {
        require(_token != address(0x0), "empty _token");

        umbToken = IERC20(_token);
    }

    // ========== MUTATIVE FUNCTIONS ========== //

    function claim() external {
        _claim(msg.sender);
    }

    function claimFor(address[] calldata _participants) external {
        for (uint i = 0; i < _participants.length; i++) {
            _claim(_participants[i]);
        }
    }

    // ========== RESTRICTED FUNCTIONS ========== //

    function addRewards(
        address[] calldata _participants,
        uint256[] calldata _rewards,
        uint256[] calldata _durations,
        uint256[] calldata _startTimes
    )
    external onlyOwner {
        require(_participants.length != 0, "there is no _participants");
        require(_participants.length == _rewards.length, "_participants count must match _rewards count");
        require(_participants.length == _durations.length, "_participants count must match _durations count");
        require(_participants.length == _startTimes.length, "_participants count must match _startTimes count");

        uint256 sum = totalVestingAmount;

        for (uint256 i = 0; i < _participants.length; i++) {
            require(_participants[i] != address(0x0), "empty participant");
            require(_durations[i] != 0, "empty duration");
            require(_durations[i] < 5 * 365 days, "duration too long");
            require(_rewards[i] != 0, "empty reward");
            require(_startTimes[i] != 0, "empty startTime");

            uint256 total = rewards[_participants[i]].total;

            if (total < _rewards[i]) {
                // we increased existing reward, so sum will be higher
                sum = sum.add(_rewards[i] - total);
            } else {
                // we decreased existing reward, so sum will be lower
                sum = sum.sub(total - _rewards[i]);
            }

            if (total != 0) {
                // updating existing
                require(rewards[_participants[i]].startTime == _startTimes[i], "can't change start time");
                require(
                    _rewards[i] >= balanceOf(_participants[i]) + rewards[_participants[i]].paid,
                        "can't take what's already done"
                );

                rewards[_participants[i]].total = _rewards[i];
                rewards[_participants[i]].duration = _durations[i];
            } else {
                // new participant
                rewards[_participants[i]] = Reward(_rewards[i], _durations[i], 0, _startTimes[i]);
            }
        }

        emit LogSetup(totalVestingAmount, sum);
        totalVestingAmount = sum;
    }

    // ========== VIEWS ========== //

    function balanceOf(address _address) public view returns (uint256) {
        Reward memory reward = rewards[_address];

        if (block.timestamp <= reward.startTime) {
            return 0;
        }

        if (block.timestamp >= reward.startTime.add(reward.duration)) {
            return reward.total - reward.paid;
        }

        return reward.total.mul(block.timestamp - reward.startTime).div(reward.duration) - reward.paid;
    }

    // ========== INTERNAL ========== //

    function _claim(address _participant) internal {
        uint256 balance = balanceOf(_participant);
        require(balance != 0, "you have no tokens to claim");

        // no need for safe math because sum was calculated using safeMath
        rewards[_participant].paid += balance;

        // this is our token, we can save gas and simple use transfer instead safeTransfer
        require(umbToken.transfer(_participant, balance), "umb.transfer failed");

        emit LogClaimed(_participant, balance);
    }
}