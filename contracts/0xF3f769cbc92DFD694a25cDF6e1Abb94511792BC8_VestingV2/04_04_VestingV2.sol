// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VestingV2
 * @dev Token vesting contract for members
 */
contract VestingV2 is Ownable {
    struct Membership {
        uint256 allocation;
        uint256 startsAt;
        uint256 duration;
    }

    IERC20 public immutable token;

    mapping(address => Membership) public members;
    mapping(address => uint256) public releases;

    event Claimed(address account, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function addMember(
        address account,
        uint256 allocation,
        uint256 duration,
        uint256 initialRelease
    ) external onlyOwner {
        members[account] = Membership(allocation, block.timestamp, duration);
        if (initialRelease > 0) {
            releases[account] = initialRelease;
        }
    }

    function blockMember(address account, bool isPenaltied) external onlyOwner {
        if (isPenaltied) {
            releases[account] = 0;
        } else {
            (uint256 claimable, ) = getClaimable(account);
            releases[account] += claimable;
        }
        members[account].allocation = 0;
    }

    function getClaimable(address account)
        public
        view
        returns (uint256 claimable, uint256 passed)
    {
        uint256 timestamp = block.timestamp;
        Membership memory member = members[account];
        if (member.duration > 0) {
            if (timestamp >= (member.startsAt + member.duration)) {
                claimable = member.allocation;
            } else {
                passed = timestamp - member.startsAt;
                claimable = (member.allocation * passed) / member.duration;
            }
        }
    }

    function claim() public {
        address account = msg.sender;
        (uint256 claimable, uint256 passed) = getClaimable(account);
        if (claimable > 0) {
            members[account].allocation -= claimable;
            members[account].startsAt = block.timestamp;
            members[account].duration -= passed;
        }
        if (releases[account] > 0) {
            claimable += releases[account];
            releases[account] = 0;
        }
        token.transfer(account, claimable);
    }

    function sweepToken(address _token) external onlyOwner {
        require(_token != address(token));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function emergencyWithdraw() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}