// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IFSushiBar.sol";
import "./interfaces/IFSushi.sol";
import "./libraries/FSushiBarPriorityQueue.sol";
import "./libraries/DateUtils.sol";

/**
 * @notice FSushiBar is an extension of ERC4626 with the addition of vesting period for locks
 */
contract FSushiBar is IFSushiBar {
    using FSushiBarPriorityQueue for FSushiBarPriorityQueue.Heap;
    using SafeERC20 for IERC20;
    using Math for uint256;
    using DateUtils for uint256;

    uint8 public constant decimals = 18;
    string public constant name = "Flash SushiBar";
    string public constant symbol = "xfSUSHI";
    uint256 internal constant MINIMUM_WEEKS = 1;
    uint256 internal constant MAXIMUM_WEEKS = 104; // almost 2 years

    address public immutable override asset;
    uint256 public immutable override startWeek;

    mapping(address => uint256) public override balanceOf;
    uint256 public override totalSupply;

    mapping(address => FSushiBarPriorityQueue.Heap) internal _locks;

    uint256 public override totalAssets;
    /**
     * @dev this is guaranteed to be correct up until the last week
     * @return minimum number of staked total assets during the whole week
     */
    mapping(uint256 => uint256) public override totalAssetsDuring;
    /**
     * @notice totalAssetsDuring is guaranteed to be correct before this week
     */
    uint256 public override lastCheckpoint; // week

    uint256 internal _totalPower;
    uint256 internal _totalYield;

    modifier validWeeks(uint256 _weeks) {
        if (_weeks < MINIMUM_WEEKS || _weeks > MAXIMUM_WEEKS) revert InvalidDuration();
        _;
    }

    constructor(address fSushi) {
        asset = fSushi;

        uint256 thisWeek = block.timestamp.toWeekNumber();
        startWeek = thisWeek;
        lastCheckpoint = thisWeek;
    }

    function previewDeposit(uint256 assets, uint256 _weeks)
        public
        view
        override
        validWeeks(_weeks)
        returns (uint256 shares)
    {
        return _toShares(_toPower(assets, _weeks), _totalPower);
    }

    function previewWithdraw(address owner)
        public
        view
        override
        returns (
            uint256 shares,
            uint256 assets,
            uint256 yield
        )
    {
        (assets, , shares) = _locks[owner].enqueued(block.timestamp);
        yield = _getYield(shares);
    }

    function _toShares(uint256 power, uint256 totalPower) internal view returns (uint256 shares) {
        uint256 supply = totalSupply;
        shares = (power == 0 || supply == 0) ? power : power.mulDiv(supply, totalPower, Math.Rounding.Down);
    }

    function _toPower(uint256 assets, uint256 _weeks) internal pure returns (uint256) {
        return assets.mulDiv(_weeks, MAXIMUM_WEEKS, Math.Rounding.Up);
    }

    function _getYield(uint256 shares) internal view returns (uint256 yield) {
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) return 0;

        return _totalYield.mulDiv(shares, _totalSupply, Math.Rounding.Down);
    }

    function depositSigned(
        uint256 assets,
        uint256 _weeks,
        address beneficiary,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint256) {
        IFSushi(asset).permit(msg.sender, address(this), assets, deadline, v, r, s);

        return deposit(assets, _weeks, beneficiary);
    }

    function deposit(
        uint256 assets,
        uint256 _weeks,
        address beneficiary
    ) public override validWeeks(_weeks) returns (uint256) {
        checkpoint();

        uint256 max = (totalAssets > 0 || totalSupply == 0) ? type(uint256).max : 0;
        if (assets > max) revert Bankrupt();

        uint256 totalPower = _totalPower;
        uint256 power = _toPower(assets, _weeks);
        uint256 shares = _toShares(power, totalPower);

        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        _mint(beneficiary, shares);

        _locks[msg.sender].enqueue(block.timestamp + _weeks * (1 weeks), assets, power, shares);

        totalAssets += assets;
        totalAssetsDuring[block.timestamp.toWeekNumber()] += assets;
        _totalPower = totalPower + power;

        emit Deposit(msg.sender, beneficiary, shares, assets);

        return shares;
    }

    function withdraw(address beneficiary)
        public
        override
        returns (
            uint256 shares,
            uint256 assets,
            uint256 yield
        )
    {
        checkpoint();

        uint256 power;
        (assets, power, shares) = _locks[msg.sender].drain(block.timestamp);
        if (shares == 0) revert WithdrawalDenied();

        yield = _getYield(shares);
        totalAssets -= (assets + yield);
        totalAssetsDuring[block.timestamp.toWeekNumber()] -= (assets + yield);
        _totalPower -= power;
        _totalYield -= yield;

        _burn(msg.sender, shares);
        IERC20(asset).safeTransfer(beneficiary, assets + yield);

        emit Withdraw(msg.sender, beneficiary, shares, assets, yield);
    }

    function checkpointedTotalAssets() external override returns (uint256) {
        checkpoint();
        return totalAssets;
    }

    function checkpointedTotalAssetsDuring(uint256 week) external override returns (uint256) {
        checkpoint();
        return totalAssetsDuring[week];
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function checkpoint() public override {
        uint256 oldTotalAssets = totalAssets;
        uint256 newTotalAssets = IERC20(asset).balanceOf(address(this));
        if (newTotalAssets > oldTotalAssets) {
            totalAssets = newTotalAssets;
            totalAssetsDuring[block.timestamp.toWeekNumber()] = newTotalAssets;
            _totalPower += newTotalAssets - oldTotalAssets;
            _totalYield += newTotalAssets - oldTotalAssets;
        }

        uint256 from = lastCheckpoint;
        uint256 until = block.timestamp.toWeekNumber();
        if (until <= from) return;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (until <= week) break;

            totalAssetsDuring[week + 1] = totalAssetsDuring[week];

            unchecked {
                ++i;
            }
        }

        lastCheckpoint = until;
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidAccount();

        totalSupply += amount;
        unchecked {
            balanceOf[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidAccount();

        uint256 balance = balanceOf[account];
        if (balance < amount) revert NotEnoughBalance();
        unchecked {
            balanceOf[account] = balance - amount;
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }
}