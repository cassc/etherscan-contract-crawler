// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// Import External Dependencies
import {ERC20} from "solmate/tokens/ERC20.sol";

/// Import Local Dependencies
import "src/Kernel.sol";
import {TRSRYv1} from "modules/TRSRY/TRSRY.v1.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";

/// Import interfaces
import "src/interfaces/Uniswap/IUniswapV2Pair.sol";

/// Define Inline Interfaces
interface IStaking {
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);
}

contract Distributor is Policy, RolesConsumer {
    // ========= ERRORS ========= //
    error Distributor_InvalidConstruction();
    error Distributor_NoRebaseOccurred();
    error Distributor_OnlyStaking();
    error Distributor_NotUnlocked();
    error Distributor_SanityCheck();
    error Distributor_AdjustmentLimit();
    error Distributor_AdjustmentUnderflow();
    error Distributor_NotPermissioned();

    // ========= STATE ========= //

    /// Modules
    TRSRYv1 public TRSRY;
    MINTRv1 public MINTR;

    /// Olympus contract dependencies
    ERC20 private immutable ohm; // OHM Token
    address private immutable staking; // OHM Staking Contract

    /// Policy state
    address[] public pools; // Liquidity pools to receive rewards
    uint256 public rewardRate; // % to increase balances per epoch (9 decimals, i.e. 10_000_000 / 1_000_000_000 = 1%)
    uint256 public bounty; // A bounty for keepers to call the triggerRebase() function
    bool private unlockRebase; // Restricts distribute() to only triggerRebase()

    /// Constants
    uint256 private constant DENOMINATOR = 1e9;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        address ohm_,
        address staking_,
        uint256 initialRate_
    ) Policy(kernel_) {
        if (
            address(kernel_) == address(0) ||
            ohm_ == address(0) ||
            staking_ == address(0) ||
            initialRate_ == 0
        ) revert Distributor_InvalidConstruction();

        ohm = ERC20(ohm_);
        staking = staking_;
        rewardRate = initialRate_;
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](3);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("TRSRY");
        dependencies[2] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        TRSRY = TRSRYv1(getModuleAddress(dependencies[1]));
        ROLES = ROLESv1(getModuleAddress(dependencies[2]));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        permissions = new Permissions[](3);
        permissions[0] = Permissions(MINTR.KEYCODE(), MINTR.mintOhm.selector);
        permissions[1] = Permissions(MINTR.KEYCODE(), MINTR.increaseMintApproval.selector);
        permissions[2] = Permissions(MINTR.KEYCODE(), MINTR.decreaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Trigger rebases via distributor. There is an error in Staking's `stake` function
    ///         which pulls forward part of the rebase for the next epoch. This path triggers a
    ///         rebase by calling `unstake` (which does not have the issue). The patch also
    ///         restricts `distribute` to only be able to be called from a tx originating in this
    ///         function.
    function triggerRebase() external {
        unlockRebase = true;
        IStaking(staking).unstake(msg.sender, 0, true, true); // Give the caller the bounty OHM
        if (unlockRebase) revert Distributor_NoRebaseOccurred();
    }

    /// @notice Send the epoch's reward to the staking contract, and mint rewards to Uniswap V2 pools.
    ///         This removes opportunity cost for liquidity providers by sending rebase rewards
    ///         directly into the liquidity pool.
    ///
    ///         NOTE: This does not add additional emissions (user could be staked instead and get the
    ///         same tokens).
    function distribute() external {
        if (msg.sender != staking) revert Distributor_OnlyStaking();
        if (!unlockRebase) revert Distributor_NotUnlocked();

        // Open minter approval by requesting max approval
        MINTR.increaseMintApproval(address(this), type(uint256).max);

        // Mint enough for rebase
        MINTR.mintOhm(staking, nextRewardFor(staking));

        // Mint OHM for mint&sync pools
        uint256 poolLength = pools.length;
        for (uint256 i; i < poolLength; ) {
            address pool = pools[i];
            uint256 reward = nextRewardFor(pool);

            if (pool != address(0) && reward > 0) {
                MINTR.mintOhm(pool, reward);
                IUniswapV2Pair(pool).sync();
            }

            unchecked {
                i++;
            }
        }

        // Close the minter approval by removing all approval
        MINTR.decreaseMintApproval(address(this), type(uint256).max);

        unlockRebase = false;
    }

    /// @notice Mints the bounty (if > 0) to the staking contract for distribution.
    /// @return uint256 The amount of OHM minted as a bounty.
    function retrieveBounty() external returns (uint256) {
        if (msg.sender != staking) revert Distributor_OnlyStaking();

        if (bounty > 0) MINTR.mintOhm(staking, bounty);

        return bounty;
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Returns the next reward for the given address based on their OHM balance.
    /// @param  who_ The address to get the next reward for.
    /// @return uint256 The next reward for the given address.
    function nextRewardFor(address who_) public view returns (uint256) {
        return (ohm.balanceOf(who_) * rewardRate) / DENOMINATOR;
    }

    //============================================================================================//
    //                                     POLICY FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Adjusts the bounty
    /// @param  bounty_ The new bounty amount in OHM (9 decimals).
    /// @dev    This function is only available to an authorized user.
    function setBounty(uint256 bounty_) external onlyRole("distributor_admin") {
        bounty = bounty_;
    }

    /// @notice Sets the Uniswap V2 pools to be minted into
    /// @param  pools_ The array of Uniswap V2 pools.
    /// @dev    This function is only available to an authorized user.
    function setPools(address[] calldata pools_) external onlyRole("distributor_admin") {
        pools = pools_;
    }

    /// @notice Removes a liquidity pool from the list of pools to be minted into
    /// @param  index_ The index in the pools array of the liquidity pool to remove.
    /// @param  pool_ The address of the liquidity pool to remove.
    /// @dev    This function is only available to an authorized user.
    function removePool(uint256 index_, address pool_) external onlyRole("distributor_admin") {
        if (pools[index_] != pool_) revert Distributor_SanityCheck();
        pools[index_] = address(0);
    }

    /// @notice Adds a liquidity pool to the list of pools to be minted into
    /// @param  index_ The index in the pools array to add the liquidity pool to.
    /// @param  pool_ The address of the liquidity pool to add.
    function addPool(uint256 index_, address pool_) external onlyRole("distributor_admin") {
        // We want to overwrite slots where possible
        if (pools[index_] == address(0)) {
            pools[index_] = pool_;
        } else {
            // If the passed in slot is not empty, push to the end
            pools.push(pool_);
        }
    }

    /// @notice Sets the new OHM reward rate to mint and distribute per epoch
    /// @param newRewardRate_ The new rate to set (9 decimals, i.e. 10_000_000 / 1_000_000_000 = 1%)
    function setRewardRate(uint256 newRewardRate_) external onlyRole("distributor_admin") {
        rewardRate = newRewardRate_;
    }
}