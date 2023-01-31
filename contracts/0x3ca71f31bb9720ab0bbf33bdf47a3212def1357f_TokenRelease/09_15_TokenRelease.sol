// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenReleaseFactory {
    event TokenReleaseCreated(
        address indexed _guy,
        address _release,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration
    );

    function createRelease(address guy)
        public {
        // One month.
        uint256 month = 31 days;

        // When the start of the release schedule begins.
        uint256 start = block.timestamp + (7 * month);

        // When tokens become transferable.
        uint256 cliff = block.timestamp + (10 * month);

        // The duration required for all tokens to become transferable.
        uint256 duration = 24 * month;

        // Create the Token Release schedule.
        TokenRelease release = new TokenRelease(
            guy,
            start,
            cliff,
            duration,
            true
        );

        // Set the release contract manager.
        release.transferOwnership(msg.sender);

        // Emit an event for TokenRelease contract creation.
        emit TokenReleaseCreated(guy, address(release), start, cliff, duration);
    }
}

contract TokenRelease is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenReleaseRevoked(address token);

    address private _beneficiary;
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    constructor (address beneficiary, uint256 start, uint256 cliff, uint256 duration, bool revocable) {
        require(beneficiary != address(0), "TokenRelease: beneficiary is the zero address");
        require(cliff <= start.add(duration), "TokenRelease: cliff is longer than duration");
        require(cliff >= start, "TokenRelease: cliff must be greater than or equal to start");
        require(duration > 0, "TokenRelease: duration is 0");
        require(start.add(duration) > block.timestamp, "TokenRelease: final time is before current time");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = cliff;
        _start = start;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function cliff() public view returns (uint256) {
        return _cliff;
    }

    function start() public view returns (uint256) {
        return _start;
    }

    function duration() public view returns (uint256) {
        return _duration;
    }

    function revocable() public view returns (bool) {
        return _revocable;
    }

    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenRelease: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenRelease: cannot revoke");
        require(!_revoked[address(token)], "TokenRelease: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenReleaseRevoked(address(token));
    }

    function _releasableAmount(IERC20 token) public view returns (uint256) {
        return _releasedAmount(token).sub(_released[address(token)]);
    }

    function _releasedAmount(IERC20 token) public view returns (uint256) {
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