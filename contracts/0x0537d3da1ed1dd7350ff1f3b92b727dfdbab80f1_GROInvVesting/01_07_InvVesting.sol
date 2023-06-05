// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "./GROBaseVester.sol";

/// @notice Vesting contract for investors in gro protocol - Can create vesting positiong that
///     cannot be stopped or removed. All investors vesting position has a fixed start time at
///     1632844845, when the first LBP transaction occured. The number of investors is already fixed
///     and no additional investors can be added to this contract. It is not possible for any investors
///     to claim their tokens before the one year cliff has expired, after which they will have access
///     to 1/3 of their tokens, the remaining will vest over the remaining vesting period.
contract GROInvVesting is GROBaseVesting {

    struct InvestorPosition {
        uint256 total;
        uint256 withdrawn;
        uint256 startTime;
    }

    mapping(address => InvestorPosition) public investorPositions;
    // Start time for the main vesting pool
    uint256 public constant START_TIME = 1632844845;

    event LogNewVest(address indexed investor, uint256 amount);
    event LogClaimed(address indexed investor, uint256 amount, uint256 withdrawn, uint256 available);

    constructor(uint256 quota) GROBaseVesting(START_TIME, quota) {}

    /// @notice Create or modify a vesting position
    /// @param account Account which to add vesting position for
    /// @param startTime irrelevant for investor vesting, they all start at the same timestamp
    /// @param amount Amount to add to vesting position
    function vest(address account, uint256 startTime, uint256 amount) external override onlyOwner {
        require(account != address(0), "vest: !account");
        require(amount > 0, "vest: !amount");

        InvestorPosition storage ep = investorPositions[account];

        require(ep.startTime == 0, 'vest: position already exists');
        ep.startTime = START_TIME;
        require((QUOTA - vestingAssets) >= amount, 'vest: not enough assets available');
        ep.total = amount;
        vestingAssets += amount;

        emit LogNewVest(account, amount);
    }

    /// @notice Claim an amount of tokens
    /// @param amount amount to be claimed
    function claim(uint256 amount) external override {
        require(amount > 0, "claim: No amount specified");
        (uint256 unlocked, uint256 available, , ) = unlockedBalance(msg.sender);
        require(available >= amount, "claim: Not enough user assets available");

        uint256 _withdrawn = unlocked - available + amount;

        InvestorPosition storage ep = investorPositions[msg.sender];
        ep.withdrawn = _withdrawn;
        distributer.mint(msg.sender, amount);
        emit LogClaimed(msg.sender, amount, _withdrawn, available - amount);
    }

    /// @notice See the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    function unlockedBalance(address account)
        internal
        view
        override
        returns ( uint256, uint256, uint256, uint256 )
    {
        InvestorPosition storage ep = investorPositions[account];
        uint256 startTime = ep.startTime;
        if (block.timestamp < startTime + VESTING_CLIFF) {
            return (0, 0, startTime, startTime + VESTING_TIME);
        }
        uint256 unlocked;
        uint256 available;
        uint256 _endTime = startTime + VESTING_TIME;
        if (block.timestamp < _endTime) {
            unlocked = ep.total * (block.timestamp - startTime) / VESTING_TIME;
        } else {
            unlocked = ep.total;
        }
        available = unlocked - ep.withdrawn;
        return (unlocked, available, startTime, _endTime);
    }

    /// @notice Get total size of position, vested + vesting
    /// @param account Target account
    function totalBalance(address account) external view override returns (uint256 balance) {
        InvestorPosition storage ep = investorPositions[account];
        balance = ep.total;
    }
}