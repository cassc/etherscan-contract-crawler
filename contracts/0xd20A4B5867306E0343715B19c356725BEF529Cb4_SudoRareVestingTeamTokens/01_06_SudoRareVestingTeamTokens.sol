// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokensVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme.
 */
contract SudoRareVestingTeamTokens {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 public start;
    uint256 public finish;
    uint256 public duration;
    uint256 public releasesCount;
    uint256 public released;

    IERC20 public token;

    constructor() {}

    /**
     * @dev Vest any ERC20 token to the beneficiary,
     * gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _token address of the token which should be vested
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of each release
     */
    function vestToken(
        address _token,
        address _beneficiary,
        uint256 _start,
        uint256 _duration,
        uint256 _releasesCount
    ) public {
        require(
            _beneficiary != address(0),
            "TokensVesting: beneficiary is the zero address!"
        );
        require(
            _token != address(0),
            "TokensVesting: token is the zero address!"
        );
        require(_duration > 0, "TokensVesting: duration is 0!");
        require(_releasesCount > 0, "TokensVesting: releases count is 0!");
        require(
            _start.add(_duration) > block.timestamp,
            "TokensVesting: final time is before current time!"
        );

        token = IERC20(_token);
        beneficiary = _beneficiary;
        duration = _duration;
        releasesCount = _releasesCount;
        start = _start;
        finish = start.add(releasesCount.mul(duration));
    }

    // -----------------------------------------------------------------------
    // GETTERS
    // -----------------------------------------------------------------------

    function getAvailableTokens() public view returns (uint256) {
        return _releasableAmount();
    }

    // -----------------------------------------------------------------------
    // SETTERS
    // -----------------------------------------------------------------------

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();
        require(unreleased > 0, "release: No tokens are due!");

        released = released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
    }

    // -----------------------------------------------------------------------
    // INTERNAL
    // -----------------------------------------------------------------------

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= finish) {
            return totalBalance;
        } else {
            uint256 timeLeftAfterStart = block.timestamp.sub(start);
            uint256 availableReleases = timeLeftAfterStart.div(duration);
            uint256 tokensPerRelease = totalBalance.div(releasesCount);
            return availableReleases.mul(tokensPerRelease);
        }
    }
}