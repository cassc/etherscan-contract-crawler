// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/ISousChef.sol";
import "./interfaces/IFSushi.sol";
import "./interfaces/IFSushiRestaurant.sol";
import "./interfaces/IFlashStrategySushiSwapFactory.sol";
import "./interfaces/IFlashStrategySushiSwap.sol";
import "./FSushiBill.sol";

contract SousChef is Ownable, ISousChef {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    using DateUtils for uint256;

    uint256 internal constant BONUS_MULTIPLIER = 10;
    uint256 internal constant REWARDS_PER_WEEK = 30000e18;
    uint256 internal constant REWARDS_FOR_INITIAL_WEEKS = BONUS_MULTIPLIER * REWARDS_PER_WEEK;

    address public immutable override fSushi;
    address public immutable override flashStrategyFactory;
    uint256 public immutable override startWeek;

    address internal immutable _implementation;

    /**
     * @notice address of IFSushiRestaurant
     */
    address public override restaurant;

    /**
     * @notice address of IFSushiKitchen
     */
    address public override kitchen;

    mapping(uint256 => address) public override getBill;
    /**
     * @notice how much rewards to be minted at the week
     */
    mapping(uint256 => uint256) public override weeklyRewards; // week => amount
    /**
     * @notice weeklyRewards is guaranteed to be correct before this week (exclusive)
     */
    uint256 public override lastCheckpoint; // week

    constructor(
        address _fSushi,
        address _restaurant,
        address _kitchen,
        address _flashStrategyFactory
    ) {
        fSushi = _fSushi;
        restaurant = _restaurant;
        kitchen = _kitchen;
        flashStrategyFactory = _flashStrategyFactory;
        uint256 thisWeek = block.timestamp.toWeekNumber();
        startWeek = thisWeek;
        lastCheckpoint = thisWeek + 1;
        weeklyRewards[thisWeek] = REWARDS_FOR_INITIAL_WEEKS;

        FSushiBill bill = new FSushiBill();
        bill.initialize(0, address(0));
        _implementation = address(bill);
    }

    function predictBillAddress(uint256 pid) external view override returns (address bill) {
        bill = Clones.predictDeterministicAddress(_implementation, bytes32(pid));
    }

    function updateRestaurant(address _restaurant) external override onlyOwner {
        if (_restaurant == address(0)) revert InvalidRestaurant();

        restaurant = _restaurant;

        emit UpdateRestaurant(_restaurant);
    }

    function updateKitchen(address _kitchen) external override onlyOwner {
        if (_kitchen == address(0)) revert InvalidKitchen();

        kitchen = _kitchen;

        emit UpdateKitchen(_kitchen);
    }

    function createBill(uint256 pid) external override returns (address bill) {
        if (getBill[pid] != address(0)) revert BillCreated();

        address strategy = IFlashStrategySushiSwapFactory(flashStrategyFactory).getFlashStrategySushiSwap(pid);
        if (strategy == address(0))
            strategy = IFlashStrategySushiSwapFactory(flashStrategyFactory).createFlashStrategySushiSwap(pid);

        bill = Clones.cloneDeterministic(_implementation, bytes32(pid));
        FSushiBill(bill).initialize(pid, IFlashStrategySushiSwap(strategy).fToken());

        getBill[pid] = bill;

        emit CreateBill(pid, bill);
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function checkpoint() external override {
        uint256 from = lastCheckpoint;
        uint256 until = block.timestamp.toWeekNumber() + 1;
        if (until <= from) return;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (until <= week) break;
            weeklyRewards[week] = _rewards(week);

            unchecked {
                ++i;
            }
        }
        lastCheckpoint = until;
    }

    function _rewards(uint256 week) internal returns (uint256) {
        if (week < startWeek + 2) return REWARDS_FOR_INITIAL_WEEKS;
        if (week == startWeek + 2) return REWARDS_PER_WEEK;

        uint256 totalSupply = IFSushi(fSushi).checkpointedTotalSupplyDuring(week - 1);
        uint256 lockedAssets = IFSushiRestaurant(restaurant).checkpointedTotalAssetsDuring(week - 1);

        uint256 rewards = (totalSupply == 0 || totalSupply < lockedAssets)
            ? 0
            : (REWARDS_PER_WEEK * (totalSupply - lockedAssets)) / totalSupply;

        // emission rate decreases 1% every week from week 3
        if (week - startWeek > 2) {
            rewards = (rewards * 99) / 100;
        }
        return rewards;
    }

    function mintFSushi(
        uint256 pid,
        address to,
        uint256 amount
    ) external override {
        if (getBill[pid] != msg.sender) revert Forbidden();

        IFSushi(fSushi).mint(to, amount);
    }
}