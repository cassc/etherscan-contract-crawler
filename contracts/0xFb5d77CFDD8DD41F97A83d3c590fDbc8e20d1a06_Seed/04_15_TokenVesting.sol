// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MoonappToken.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for MoonappToken;

    event Released(uint256 amount);

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;

    uint256 public releaseRate;
    uint256 public releasedInitially;
    uint256 public released;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     */
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _releaseRate,
        uint256 _releasedInitially
    ) {
        require(_beneficiary != address(0));
        require(_start > 0);
        require(_cliff > 0);
        require(_releasedInitially >= 0);
        require(_releaseRate > 0 && _releaseRate <= 100);

        beneficiary = _beneficiary;
        cliff = _start.add(_cliff);
        start = _start;
        releaseRate = _releaseRate;
        releasedInitially = _releasedInitially;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(address token) external {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0, "tokens cannot be released");

        released = released.add(unreleased);

        SafeERC20.safeTransfer(IERC20(token), beneficiary, unreleased);

        emit Released(unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function releasableAmount(address token)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 vested = vestedAmount(token);
        if (vested > 0) return vested.sub(released);
        return 0;
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function vestedAmount(address token) public view virtual returns (uint256) {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < cliff) {
            return releasedInitially;
        }

        uint256 monthsGone = (block.timestamp - cliff) / (60 * 60 * 24 * 30);

        uint256 vested = (totalBalance.mul(monthsGone * releaseRate).div(100))
            .add(releasedInitially);

        if (vested > totalBalance) return totalBalance;
        return vested;
    }

    /**
     * @dev Calculates the amount that is locked.
     * @param token ERC20 token which is being vested
     */
    function lockedAmount(address token)
        external
        view
        virtual
        returns (uint256)
    {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        return currentBalance;
    }
}