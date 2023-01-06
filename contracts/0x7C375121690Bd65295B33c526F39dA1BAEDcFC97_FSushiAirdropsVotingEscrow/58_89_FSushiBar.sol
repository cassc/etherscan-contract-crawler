// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./interfaces/IFSushiBar.sol";
import "./interfaces/IFSushi.sol";
import "./libraries/DateUtils.sol";

contract FSushiBar is ERC4626, IFSushiBar {
    using DateUtils for uint256;

    uint256 internal constant MINIMUM_PERIOD = 1 weeks;

    uint256 public immutable override startWeek;

    /**
     * @notice timestamp when users lastly deposited
     */
    mapping(address => uint256) public override lastDeposit; // timestamp

    /**
     * @dev this is guaranteed to be correct up until the last week
     * @return minimum number of staked total assets during the whole week
     */
    mapping(uint256 => uint256) public override lockedTotalBalanceDuring;
    /**
     * @notice lockedTotalBalanceDuring is guaranteed to be correct before this week
     */
    uint256 public override lastCheckpoint; // week
    /**
     * @dev this is guaranteed to be correct up until the last week
     * @return minimum number of staked assets of account during the whole week
     */
    mapping(address => mapping(uint256 => uint256)) public override lockedUserBalanceDuring;
    /**
     * @notice lockedUserBalanceDuring is guaranteed to be correct before this week (exclusive)
     */
    mapping(address => uint256) public override lastUserCheckpoint; // week

    constructor(address fSushi) ERC4626(IERC20(fSushi)) ERC20("Flash SushiBar", "xfSUSHI") {
        uint256 nextWeek = block.timestamp.toWeekNumber() + 1;
        startWeek = nextWeek;
        lastCheckpoint = nextWeek;
    }

    function checkpointedLockedTotalBalanceDuring(uint256 week) external override returns (uint256) {
        checkpoint();
        return lockedTotalBalanceDuring[week];
    }

    function checkpointedLockedUserBalanceDuring(address account, uint256 week) external override returns (uint256) {
        checkpoint();
        return lockedUserBalanceDuring[account][week];
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function checkpoint() public override {
        uint256 from = lastCheckpoint;
        uint256 until = block.timestamp.toWeekNumber();
        if (until <= from) return;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (until <= week) break;

            lockedTotalBalanceDuring[week + 1] = lockedTotalBalanceDuring[week];

            unchecked {
                ++i;
            }
        }

        lastCheckpoint = until;
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function userCheckpoint(address account) public override {
        checkpoint();

        uint256 from = lastUserCheckpoint[account];
        if (from == 0) {
            from = startWeek;
        }
        uint256 until = block.timestamp.toWeekNumber();
        if (until <= from) return;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (until <= week) break;

            lockedUserBalanceDuring[account][week + 1] = lockedUserBalanceDuring[account][week];

            unchecked {
                ++i;
            }
        }

        lastUserCheckpoint[account] = until;
    }

    function depositSigned(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256) {
        IFSushi(asset()).permit(msg.sender, address(this), assets, deadline, v, r, s);

        return deposit(assets, receiver);
    }

    function mintSigned(
        uint256 shares,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256) {
        IFSushi(asset()).permit(msg.sender, address(this), previewMint(shares), deadline, v, r, s);

        return mint(shares, receiver);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (block.timestamp < startWeek.toTimestamp()) revert TooEarly();

        super._deposit(caller, receiver, assets, shares);

        userCheckpoint(msg.sender);

        uint256 week = block.timestamp.toWeekNumber();
        lockedTotalBalanceDuring[week] += assets;
        lockedUserBalanceDuring[msg.sender][week] += assets;
        lastDeposit[caller] = block.timestamp;
    }

    /**
     * @dev Users can withdraw only when 1 week have passed after `lastDeposit` of their account
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (block.timestamp < lastDeposit[owner] + MINIMUM_PERIOD) revert TooEarly();

        super._withdraw(caller, receiver, owner, assets, shares);

        userCheckpoint(msg.sender);

        uint256 week = block.timestamp.toWeekNumber();
        lockedTotalBalanceDuring[week] -= assets;
        lockedUserBalanceDuring[msg.sender][week] -= assets;
    }
}