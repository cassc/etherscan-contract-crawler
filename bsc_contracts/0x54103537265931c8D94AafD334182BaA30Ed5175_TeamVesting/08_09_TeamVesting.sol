// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

/// @title Vesting Contract for moonscape (MSCP) token.
/// @author Nejc Schneider
/// @notice Unlock tokens for pre-approved addresses gradualy over time.
contract TeamVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev session data
    IERC20 private immutable token;

    struct Balance {
        uint256 remainingCoins;
        uint256 supply;
        uint256 duration;
        uint256 startTime;
    }

    mapping(address => Balance) public balances;

    event InvestorModified(address indexed investor, uint256 remainingCoins);
    event Withdraw(
        address indexed receiver,
        uint256 withdrawnAmount,
        uint256 remainingCoins
    );

    constructor(IERC20 _token) {
        require(address(_token) != address(0), "invalid currency address");

        token = _token;
    }

    //--------------------------------------------------------------------
    //  external functions
    //--------------------------------------------------------------------

    /// @notice add strategic investor address
    /// @param _investor address to be added
    /// @param _dailyAllowance is daily allowance
    function addInvestor(
        address _investor,
        uint256 _dailyAllowance,
        uint256 _daysDuration,
        uint256 _startTime
    ) external onlyOwner {
        require(
            balances[_investor].duration == 0,
            "investor already has allocation"
        );

        // make sure the parameters are valid
        require(_dailyAllowance > 0, "daily allowance must be > 0");
        require(_daysDuration > 0, "duration must be > 0");
        require(_investor != address(0), "invalid address");
        require(_startTime > block.timestamp, "vesting should start in future");

        balances[_investor].duration = _daysDuration * 24 * 60 * 60;
        balances[_investor].remainingCoins = _daysDuration * _dailyAllowance;
        balances[_investor].supply = balances[_investor].remainingCoins;
        balances[_investor].startTime = _startTime;

        emit InvestorModified(_investor, balances[_investor].remainingCoins);
    }

    /// @notice set investor remaining coins to 0
    /// @param _investor address to disable
    function disableInvestor(address _investor) external onlyOwner {
        require(
            balances[_investor].remainingCoins > 0,
            "investor already disabled"
        );
        uint256 _remainingCoins = balances[_investor].remainingCoins;
        delete balances[_investor];
        emit InvestorModified(_investor, _remainingCoins);
    }

    /// @notice clam the unlocked tokens
    function withdraw() external {
        Balance storage balance = balances[msg.sender];
        require(balance.duration > 0, "user has no allocation");
        require(
            block.timestamp >= balance.startTime,
            "vesting for you hasnt started yet"
        );
        require(balance.remainingCoins > 0, "user has no allocation");

        uint256 timePassed = getDuration(balance.startTime, balance.duration);
        uint256 availableAmount = getAvailableTokens(
            timePassed,
            balance.remainingCoins,
            balance.supply,
            balance.duration
        );

        balance.remainingCoins = balance.remainingCoins.sub(availableAmount);
        token.safeTransfer(msg.sender, availableAmount);

        emit Withdraw(msg.sender, availableAmount, balance.remainingCoins);
    }

    //--------------------------------------------------------------------
    //  external getter functions
    //--------------------------------------------------------------------

    // write a function that returns the duration of the vesting period
    function getDuration(address _investor) external view returns (uint256) {
        return balances[_investor].duration;
    }

    /// @notice get amount of tokens user has yet to withdraw
    /// @return amount of remaining coins
    function getTotalReleased(address _investor)
        external
        view
        returns (uint256)
    {
        console.log("getTotalReleased");
        uint256 totalReleased = balances[_investor].supply -
            balances[_investor].remainingCoins;
        console.log("totalReleased %s", totalReleased);
        return totalReleased;
    }

    function getAvailableAmount(address _investor)
        external
        view
        returns (uint256)
    {
        console.log("getAvailableAmount");
        Balance storage balance = balances[_investor];
        uint256 timePassed = getDuration(balance.startTime, balance.duration);
        console.log("timePassed %s", timePassed);
        uint256 availableAmount = getAvailableTokens(
            timePassed,
            balance.remainingCoins,
            balance.supply,
            balance.duration
        );
        return availableAmount;
    }

    //--------------------------------------------------------------------
    //  internal functions
    //--------------------------------------------------------------------

    /// @dev calculate how much time has passed since start.
    /// If vesting is finished, return length of the session
    /// @return duration of time in seconds
    function getDuration(uint256 _startTime, uint256 _duration)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < _startTime + _duration)
            return block.timestamp - _startTime;
        return _duration;
    }

    /// @dev calculate how many tokens are available for withdrawal
    /// @param _timePassed amount of time since vesting started
    /// @param _remainingCoins amount of unspent tokens
    /// @return tokens amount
    function getAvailableTokens(
        uint256 _timePassed,
        uint256 _remainingCoins,
        uint256 _supply,
        uint256 _duration
    ) public view returns (uint256) {
        console.log("getAvailableTokens");
        console.log("_timePassed %s", _timePassed);
        console.log("_remainingCoins %s", _remainingCoins);
        console.log("_supply %s", _supply);
        uint256 unclaimedPotential = ((_timePassed * _supply) / _duration);
        return unclaimedPotential - (_supply - _remainingCoins);
    }
}