pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IVesting} from "./interfaces/IVesting.sol";
import {ISale} from "./interfaces/ISale.sol";
import {ISaleListener} from "./interfaces/ISaleListener.sol";

contract Vesting is IVesting, ISaleListener, AccessControl {
    using SafeERC20 for IERC20;

    //
    // Constants
    //

    bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");

    //
    // Errors
    //

    error InvalidArguments();
    error NotEnoughAvailable(uint256 available, uint256 requested);
    error NotAuthorized();
    error RulesAlreadySet(Group group);

    //
    // State
    //

    /// The token being vested
    IERC20 public immutable token;

    /// sale contract
    address public immutable sale;

    /// start of cliff/vesting period
    uint256 public immutable start;

    /// rules for each vesting group
    mapping(Group => Rules) public rules;

    /// group => holder => totalAllocation
    mapping(Group => mapping(address => Allocation)) public allocations;

    /**
     * @param _token The Token to vest
     * @param _sale The corresponding ISale contract
     * @param _start The intended start for cliff/vesting period
     */
    constructor(
        address _token,
        address _sale,
        uint256 _start
    ) {
        if (
            _token == address(0) ||
            _sale == address(0) ||
            _start < block.timestamp
        ) {
            revert InvalidArguments();
        }

        token = IERC20(_token);
        sale = _sale;
        start = _start;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ALLOCATOR_ROLE, msg.sender);
    }

    //
    // Modifiers
    //

    modifier onlyBeforeSale() {
        if (block.timestamp < ISale(sale).start()) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlySale() {
        if (msg.sender != sale) {
            revert NotAuthorized();
        }
        _;
    }

    //
    // IVesting
    //

    /// @inheritdoc IVesting
    function claim(Group[] calldata _groups)
        external
        returns (uint256 amountOut)
    {
        for (uint256 i = 0; i < _groups.length; ) {
            amountOut += _claimSingle(_groups[i], msg.sender);
            unchecked {
                ++i;
            }
        }

        IERC20(token).safeTransfer(msg.sender, amountOut);

        emit Claim(msg.sender, amountOut);
    }

    /// @inheritdoc IVesting
    function claimable(Group[] calldata _groups, address _holder)
        public
        view
        returns (uint256 amountOut)
    {
        for (uint256 i = 0; i < _groups.length; ) {
            amountOut += _claimableSingle(_groups[i], _holder);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IVesting
    function claimed(Group[] calldata _groups, address _holder)
        external
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < _groups.length; ) {
            amount += allocations[_groups[i]][_holder].claimed;
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IVesting
    function leftToClaim(Group[] calldata _groups, address _holder)
        external
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < _groups.length; ) {
            amount += _leftToClaimSingle(_groups[i], _holder);
            unchecked {
                ++i;
            }
        }
    }

    //
    // ISaleListener
    //

    /// @inheritdoc ISaleListener
    function onSale(address _beneficiary, uint256 _amount)
        external
        onlySale
        returns (bytes4 selector)
    {
        Rules storage rule = rules[Group.PrivateSale];
        Allocation storage alloc = allocations[Group.PrivateSale][_beneficiary];

        if (rule.remaining < _amount) {
            revert NotEnoughAvailable(rule.remaining, _amount);
        }

        alloc.total += _amount;
        rule.remaining -= _amount;

        return ISaleListener.onSale.selector;
    }

    /// @inheritdoc ISaleListener
    function getSaleAllocation(address _holder)
        external
        view
        returns (uint256 amount)
    {
        return allocations[Group.PrivateSale][_holder].total;
    }

    /// @inheritdoc ISaleListener
    function getSaleAmounts()
        external
        view
        returns (uint256 total, uint256 remaining)
    {
        Rules storage rule = rules[Group.PrivateSale];

        return (rule.total, rule.remaining);
    }

    //
    // Allocator API
    //

    /**
     * Allows admins to add new allocations to private groups
     *
     * @param _group Group to add allocations to
     * @param _holders List of addresses to allocate tokens to
     * @param _amounts Amount to allocate for each holder
     */
    function addAllocations(
        Group _group,
        address[] calldata _holders,
        uint256[] calldata _amounts
    ) external onlyRole(ALLOCATOR_ROLE) {
        if (_group == Group.Invalid || _holders.length != _amounts.length) {
            revert InvalidArguments();
        }

        uint256 newAmount;

        for (uint256 i = 0; i < _holders.length; ) {
            newAmount += _amounts[i];
            allocations[_group][_holders[i]].total += _amounts[i];
            unchecked {
                ++i;
            }
        }

        Rules storage rule = rules[_group];
        if (rule.remaining < newAmount) {
            revert NotEnoughAvailable(rule.remaining, newAmount);
        }

        rule.remaining -= newAmount;
    }

    /**
     * Allows admins to configure rules for each group
     *
     * @param _groups Groups to configure
     * @param _amounts Amount to allocate for each group
     * @param _cliffs Cliff period for each group, in days
     * @param _vestings Vesting period for each group, in days
     */
    function addRules(
        Group[] calldata _groups,
        uint256[] calldata _amounts,
        uint256[] calldata _cliffs,
        uint256[] calldata _vestings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            _groups.length != _amounts.length ||
            _groups.length != _cliffs.length ||
            _groups.length != _vestings.length
        ) {
            revert InvalidArguments();
        }

        uint256 amount;
        for (uint256 i = 0; i < _groups.length; ) {
            if (rules[_groups[i]].total > 0) {
                revert RulesAlreadySet(_groups[i]);
            }

            amount += _amounts[i];

            rules[_groups[i]] = Rules({
                total: _amounts[i],
                remaining: _amounts[i],
                cliff: _cliffs[i],
                vesting: _vestings[i]
            });

            unchecked {
                ++i;
            }
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * Allows admin to cancel the process, and recover all $UCOIL. Only works before until the sale's starting point
     *
     * @dev This is a fallback mechanism if by any chance we need to postpone the sale
     */
    function cancel() external onlyRole(DEFAULT_ADMIN_ROLE) onlyBeforeSale {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);
    }

    //
    // Public API
    //

    function allGroups() public pure returns (Group[] memory groups) {
        groups = new Group[](3);
        groups[0] = Group.Seed;
        groups[1] = Group.PrivateSale;
        groups[2] = Group.Public;
        groups[3] = Group.MarketMaker;
        groups[4] = Group.Ecosystem;
        groups[5] = Group.Team;
        groups[6] = Group.Marketing;
    }

    //
    // Internal API
    //

    /**
     * Returns total claimable amount for a single holder and group
     *
     * @param _group The group to check
     * @param _holder The holder to check
     * @return amountOut The total claimable amount for the group and holder
     */
    function _claimableSingle(Group _group, address _holder)
        internal
        view
        returns (uint256 amountOut)
    {
        if (block.timestamp < start) {
            return 0;
        }

        Rules storage group = rules[_group];
        Allocation storage alloc = allocations[_group][_holder];

        uint256 vestingStart = start + group.cliff;
        uint256 vestingEnd = vestingStart + group.vesting;

        uint256 pct;
        uint256 mul = 100;

        uint256 vestedAmount = alloc.total;
        uint256 immediate;

        if (_group == Group.PrivateSale || _group == Group.Seed) {
            immediate = (vestedAmount * 20) / 100;
            vestedAmount -= immediate;
        }

        if (vestingStart > block.timestamp) {
            pct = 0;
        } else if (block.timestamp >= vestingEnd) {
            pct = mul;
        } else {
            pct = ((block.timestamp - vestingStart) * mul) / group.vesting;
        }

        amountOut = immediate + (vestedAmount * pct) / mul - alloc.claimed;
    }

    /**
     * Updates an allocation to perform a claim
     *
     * @param _group The group to claim from
     * @param _holder The claimer
     * @return amountOut The total amount to be claimed for the group and holder
     */
    function _claimSingle(Group _group, address _holder)
        internal
        returns (uint256 amountOut)
    {
        amountOut = _claimableSingle(_group, _holder);

        Allocation storage alloc = allocations[_group][_holder];
        alloc.claimed += amountOut;

        return amountOut;
    }

    /**
     * Returns total unclaimed amount (both locked & unlocked) for a single holder and group
     *
     * @param _group The group to check
     * @param _holder The holder to check
     * @return The total unclaimed amount for the group and holder
     */
    function _leftToClaimSingle(Group _group, address _holder)
        internal
        view
        returns (uint256)
    {
        Allocation storage alloc = allocations[_group][_holder];

        return alloc.total - alloc.claimed;
    }
}