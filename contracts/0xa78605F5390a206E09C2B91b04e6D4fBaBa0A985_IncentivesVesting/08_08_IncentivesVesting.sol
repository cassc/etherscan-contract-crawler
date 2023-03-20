// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title IncentivesVesting
/// @author @ZackZeroLiquid
/// @dev A token holder contract that can release its token balance gradually like a
/// typical vesting scheme, with a cliff and vesting period. Optionally revocable by the owner.
contract IncentivesVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private immutable _cliff;
    uint256 private immutable _start;
    uint256 private immutable _duration;

    bool private _revocable;

    mapping(address => uint256) private _released;
    mapping(address => bool) private _revoked;

    /// @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    /// beneficiary, gradually in a linear fashion until start + duration. By then all
    /// of the balance will have vested.
    /// @param beneficiaryAddress address of the beneficiary to whom vested tokens are transferred
    /// @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
    /// @param vestingDuration duration in seconds of the period in which the tokens will vest
    constructor(address beneficiaryAddress, uint256 cliffDuration, uint256 vestingDuration) {
        uint256 startTimestamp = block.timestamp;

        require(beneficiaryAddress != address(0), "IncentivesVesting:: beneficiary can not be zero address");
        require(cliffDuration <= vestingDuration, "IncentivesVesting:: cliff is longer than duration");
        require(vestingDuration > 0, "IncentivesVesting:: duration is 0");
        require(
            startTimestamp.add(vestingDuration) > block.timestamp,
            "IncentivesVesting:: final time is before current time"
        );

        _beneficiary = beneficiaryAddress;
        _cliff = startTimestamp.add(cliffDuration);
        _start = startTimestamp;
        _duration = vestingDuration;
        _revocable = false;
    }

    /// @return _beneficiary the beneficiary of the tokens.
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /// @return _cliff the cliff time of the token vesting.
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /// @return _start the start time of the token vesting.
    function start() public view returns (uint256) {
        return _start;
    }

    /// @return _duration the duration of the token vesting.
    function duration() public view returns (uint256) {
        return _duration;
    }

    /// @return _revocable true if the vesting is revocable.
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /// @return _released the amount of the token released.
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /// @return _revoked true if the token is revoked.
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    /// @notice Transfers vested tokens to beneficiary.
    /// @param token ERC20 token which is being vested
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "IncentivesVesting:: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /// @notice Allows the owner to revoke the vesting. Tokens already vested
    /// remain in the contract, the rest are returned to the owner.
    /// @param token ERC20 token which is being vested
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "IncentivesVesting:: cannot revoke");
        require(!_revoked[address(token)], "IncentivesVesting:: vesting already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /// @dev Calculates the amount that has already vested but hasn't been released yet.
    /// @param token ERC20 token which is being vested
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    /// @dev Calculates the amount that has already vested.
    /// @param token ERC20 token which is being vested
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}