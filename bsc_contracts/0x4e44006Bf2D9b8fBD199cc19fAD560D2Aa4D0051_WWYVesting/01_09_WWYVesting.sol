// SPDX-License-Identifier: GPL-3.0
// Author: @dissmay
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

abstract contract ERC20 is IERC20 {
    function decimals() external virtual returns (uint8);
}

contract WWYVesting is Ownable, Pausable {
    using SafeERC20 for ERC20;
    /// *** ALL events

    ///@notice project owner event
    event Withdraw(address user, uint256 amount);

    ///@notice user event
    event Released(address user, uint256 tokens);

    ///@notice admin event
    event StartVesting(uint256 timestamp);

    // All possible errors
    // https://blog.soliditylang.org/2021/04/21/custom-errors/
    error VestingHasStarted(uint256 timestamp);
    error WrongInput(string message);
    error NotStartVesting();
    /// *** Structs

    /// Info about user
    struct Contribution {
        uint256 tokens;
        uint256 releasedTokens;
    }

    /// @notice Total Stable Coins Received during IDO
    uint256 public totalStableReceived;

    /// @notice user needs to wait till vesting period start
    uint256 public timeLockSeconds;

    /// @notice The timestamp when user could withdraw the first token according to vesting schedule
    uint256 public vestingStart;
    /*
     * Vesting period
     */
    uint256 public vestingDurationSeconds;

    /*
     * Withdraw Interval in seconds
     */
    uint256 public vestingWidthdrawInterval;

    // BUSD
    ERC20 public stableCoin;

    //IDO token
    ERC20 public token;

    mapping(address => Contribution) public contributions;

    /// @notice percent of tokens which must be released right after TGE
    uint256 tgeReleasePercent = 20;
    uint256 EIGHTEEN_DECIMALS = 18;
    uint256 public stableCoinDecimals = EIGHTEEN_DECIMALS;
    uint256 public tokenReleaseDecimals = EIGHTEEN_DECIMALS;

    constructor(
        uint256[2] memory _vestingDurationAndWithdrawal,
        uint256 _timeLockSeconds,
        uint256 _tgeReleasePercent,
        ERC20 _token
    ) {
        // do not change it everything below
        tgeReleasePercent = _tgeReleasePercent;
        vestingWidthdrawInterval = _vestingDurationAndWithdrawal[1];
        token = _token;
        tokenReleaseDecimals = token.decimals();

        timeLockSeconds = _timeLockSeconds;
        vestingDurationSeconds = _vestingDurationAndWithdrawal[0];

        if (tgeReleasePercent > 100)
            revert WrongInput("tge percent should be lower than 100");
        if (vestingWidthdrawInterval > vestingDurationSeconds)
            revert WrongInput(
                "Vesting withdrawal interval must be less than _vestingDurationSeconds"
            );
    }

    /// @notice emergency pause
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice unpause the tokensale after emergency is over
    function unpause() public onlyOwner {
        _unpause();
    }

    function startVesting(uint256 timestamp) public onlyOwner {
        _startVesting(timestamp);
    }

    /**
     * @dev Internal Function to start vesting with initial lockup and vesting duration for all participants
       Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/VestingWallet.sol for multiple wallets
     */
    function _startVesting(uint256 timestamp) internal {
        if (vestingStart > 0) revert VestingHasStarted(vestingStart);
        vestingStart = timestamp + timeLockSeconds;
        emit StartVesting(timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 tgeAllocation = (totalAllocation * tgeReleasePercent) / 100; // вся сумма умножается на процент после делиться на 100
        uint256 timedAllocation = totalAllocation - tgeAllocation;

        if (vestingStart == 0) {
            return 0;
        } else if (timestamp < vestingStart) {
            if (timestamp + timeLockSeconds < vestingStart) {
                return 0;
            }
            return tgeAllocation;
        } else if (timestamp > vestingStart + vestingDurationSeconds) {
            return totalAllocation;
        } else {
            uint256 numberOfPeriods = vestingDurationSeconds /
                vestingWidthdrawInterval;
            uint256 allocationPart = timedAllocation / numberOfPeriods;

            uint256 distributed = (timedAllocation *
                (timestamp - vestingStart)) / vestingDurationSeconds;

            return
                tgeAllocation + (distributed - (distributed % allocationPart));
        }
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address user, uint64 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        Contribution memory contrib = contributions[user];
        uint256 tokens = _vestingSchedule(contrib.tokens, timestamp);
        if (contrib.releasedTokens >= tokens) {
            return contrib.releasedTokens;
        }
        return tokens;
    }

    /**
     * @dev User should call this function from the front-end to get vested tokens
     */
    function release() public virtual whenNotPaused {
        Contribution storage contrib = contributions[msg.sender];
        if (contrib.tokens == 0) revert WrongInput("no contrib");
        uint256 releasable = vestedAmount(msg.sender, uint64(block.timestamp)) -
            contrib.releasedTokens;
        contrib.releasedTokens += releasable;
        // Если стейблкоин 6 decimals, а token проекта 18 - тогда releasable * (10 ** 12)
        uint256 priceReleasable = getPriceFromDecimals(
            releasable,
            tokenReleaseDecimals
        );
        token.safeTransfer(msg.sender, priceReleasable); // releasable * (10 ** 12)
        emit Released(msg.sender, priceReleasable);
    }

    function getPriceFromDecimals(uint256 price, uint256 dec)
        private
        view
        returns (uint256)
    {
        if (dec == EIGHTEEN_DECIMALS) {
            return price;
        } else if (dec < EIGHTEEN_DECIMALS) {
            uint256 d = EIGHTEEN_DECIMALS - dec; // 18 - 6 = 12;
            return price / (10**d); // 100 + 10**18 / 10 ** 12 = 100 + 10**6;
        } else if (dec > EIGHTEEN_DECIMALS) {
            uint256 d = dec - EIGHTEEN_DECIMALS;
            return price * (10**d);
        }
        // return price;
    }

    function emergencyWithdrawTokens(address _token, uint256 _amount)
        public
        onlyOwner
    {
        ERC20(_token).safeTransfer(msg.sender, _amount);
    }

    bool setContrib;

    function setContribute(uint256 tokenAmount, address userAddress)
        public
        onlyOwner
    {
        if (setContrib) {
            revert WrongInput("already send user");
        }
        Contribution storage contrib = contributions[userAddress];
        contrib.tokens = tokenAmount;
    }
}