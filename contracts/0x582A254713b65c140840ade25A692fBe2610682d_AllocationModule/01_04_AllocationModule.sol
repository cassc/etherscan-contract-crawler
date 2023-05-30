// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "./interface/CowProtocolTokens.sol";
import "./vendored/Enum.sol";
import "./vendored/ModuleController.sol";

/// @dev Gnosis Safe module used to distribute the Safe's vCOW allocation to other addresses. The module can add new
/// target addresses that will be assigned a linear token allocation. Claims can be reedemed at any time by the target
/// addresses and can be stopped at any time by the team controller.
/// @title COW Allocation Module
/// @author CoW Protocol Developers
contract AllocationModule {
    /// @dev Parameters that describe a linear vesting position for a claimant.
    struct VestingPosition {
        /// @dev Full amount of COW that is to be vested linearly in the designated time.
        uint96 totalAmount;
        /// @dev Amount of COW that the claimant has already redeemed so far.
        uint96 claimedAmount;
        /// @dev Timestamp when this vesting position started.
        uint32 start;
        /// @dev Timespan between vesting start and end.
        uint32 duration;
    }

    /// @dev Gnosis Safe that will enable this module. Its vCOW claims will be used to pay out each target address.
    ModuleController public immutable controller;
    /// @dev The COW token.
    CowProtocolToken public immutable cow;
    /// @dev The virtual COW token.
    CowProtocolVirtualToken public immutable vcow;
    /// @dev Maps each address to its vesting position. An address can have at most a single vesting position.
    mapping(address => VestingPosition) public allocation;

    /// @dev Maximum value that can be stored in the type uint32.00
    uint256 private constant MAX_UINT_32 = (1 << (32)) - 1;

    /// @dev Thrown when creating a vesting position of zero duration.
    error DurationMustNotBeZero();
    /// @dev Thrown when creating a vesting position for an address that already has a vesting position.
    error HasClaimAlready();
    /// @dev Thrown when computing the amount of vested COW of an address that has no allocation.
    error NoClaimAssigned();
    /// @dev Thrown when executing a function that is reserved to the Gnosis Safe that controls this module.
    error NotAController();
    /// @dev Thrown when a claimant tries to claim more COW tokens that the linear vesting allows at this point in time.
    error NotEnoughVestedTokens();
    /// @dev Thrown when the transfer of COW tokens did not succeed.
    error RevertedCowTransfer();

    /// @dev A new linear vesting position is added to the module.
    event ClaimAdded(
        address indexed beneficiary,
        uint32 start,
        uint32 duration,
        uint96 amount
    );
    /// @dev A vesting position is removed from the module.
    event ClaimStopped(address indexed beneficiary);
    /// @dev A claimant redeems an amount of COW tokens from its vesting position.
    event ClaimRedeemed(address indexed beneficiary, uint96 amount);

    /// @dev Restrict the message caller to be the controller of this module.
    modifier onlyController() {
        if (msg.sender != address(controller)) {
            revert NotAController();
        }
        _;
    }

    constructor(address _controller, address _vcow) {
        controller = ModuleController(_controller);
        vcow = CowProtocolVirtualToken(_vcow);
        cow = CowProtocolToken(address(vcow.cowToken()));
    }

    /// @dev Allocates a vesting claim for COW tokens to an address.
    /// @param beneficiary The address to which the new vesting claim will be assigned.
    /// @param duration How long it will take to the beneficiary to vest the entire amount of the claim.
    /// @param amount Amount of COW tokens that will be linearly vested to the beneficiary.
    function addClaim(
        address beneficiary,
        uint32 start,
        uint32 duration,
        uint96 amount
    ) external onlyController {
        if (duration == 0) {
            revert DurationMustNotBeZero();
        }
        if (allocation[beneficiary].totalAmount != 0) {
            revert HasClaimAlready();
        }
        allocation[beneficiary] = VestingPosition({
            totalAmount: amount,
            claimedAmount: 0,
            start: start,
            duration: duration
        });

        emit ClaimAdded(beneficiary, start, duration, amount);
    }

    /// @dev Stops the claim of an address. It first claims the entire amount of COW allocated so far on behalf of the
    /// former beneficiary.
    /// @param beneficiary The address that will see its vesting position stopped.
    function stopClaim(address beneficiary) external onlyController {
        // Note: claiming COW might fail, therefore making it impossible to stop the claim. This is not considered an
        // issue as a claiming failure can only occur in the following cases:
        // 1. No claim is available: then nothing needs to be stopped.
        // 2. This module is no longer enabled in the controller.
        // 3. The COW transfer reverts. This means that there weren't enough vCOW tokens to swap for COW and that there
        // aren't enough COW tokens available in the controller. Sending COW tokens to pay out the remaining claim would
        // allow to stop the claim.
        // 4. Math failures (overflow/underflows). No untrusted value is provided to this function, so this is not
        // expected to happen.
        // solhint-disable-next-line not-rely-on-time
        _claimAllCow(beneficiary, block.timestamp);

        delete allocation[beneficiary];

        emit ClaimStopped(beneficiary);
    }

    /// @dev Computes and sends the entire amount of COW that have been vested so far to the caller.
    /// @return The amount of COW that has been claimed.
    function claimAllCow() external returns (uint96) {
        // solhint-disable-next-line not-rely-on-time
        return _claimAllCow(msg.sender, block.timestamp);
    }

    /// @dev Sends the specified amount of COW to the caller, assuming enough COW has been vested so far.
    function claimCow(uint96 claimedAmount) external {
        address beneficiary = msg.sender;

        (uint96 alreadyClaimedAmount, uint96 fullVestedAmount) = retrieveClaimedAmounts(
            beneficiary,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        claimCowFromAmounts(
            beneficiary,
            claimedAmount,
            alreadyClaimedAmount,
            fullVestedAmount
        );
    }

    /// @dev Returns how many COW tokens are claimable at the current point in time by the given address. Tokens that
    /// were already claimed by the user are not included in the output amount.
    /// @param beneficiary The address that owns the claim.
    /// @return The amount of COW that could be claimed by the beneficiary at this point in time.
    function claimableCow(address beneficiary) external view returns (uint256) {
        if (allocation[beneficiary].totalAmount == 0) {
            return 0;
        }
        (uint96 alreadyClaimedAmount, uint96 fullVestedAmount) = retrieveClaimedAmounts(
            beneficiary,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        return fullVestedAmount - alreadyClaimedAmount;
    }

    /// @dev Computes and sends the entire amount of COW that have been vested so far to the beneficiary.
    /// @param beneficiary The address that redeems its claim.
    /// @param timestampAtClaimingTime The timestamp at claiming time.
    /// @return claimedAmount The amount of COW that has been claimed.
    function _claimAllCow(address beneficiary, uint256 timestampAtClaimingTime)
        internal
        returns (uint96 claimedAmount)
    {
        (
            uint96 alreadyClaimedAmount,
            uint96 fullVestedAmount
        ) = retrieveClaimedAmounts(beneficiary, timestampAtClaimingTime);

        claimedAmount = fullVestedAmount - alreadyClaimedAmount;
        claimCowFromAmounts(
            beneficiary,
            claimedAmount,
            alreadyClaimedAmount,
            fullVestedAmount
        );
    }

    /// @dev Computes some values related to a vesting position: how much can be claimed at the specified point in time
    /// and how much has already been claimed.
    /// @param beneficiary The address that is assigned the vesting position to consider.
    /// @param timestampAtClaimingTime The timestamp at claiming time.
    /// @return alreadyClaimedAmount How much of the vesting position has already been claimed.
    /// @return fullVestedAmount How much of the vesting position has been vested at the specified point in time. This
    /// amount does not exclude the amount that has already been claimed.
    function retrieveClaimedAmounts(
        address beneficiary,
        uint256 timestampAtClaimingTime
    )
        internal
        view
        returns (uint96 alreadyClaimedAmount, uint96 fullVestedAmount)
    {
        // Destructure caller position as gas efficiently as possible without assembly.
        VestingPosition memory position = allocation[beneficiary];
        uint96 totalAmount = position.totalAmount;
        alreadyClaimedAmount = position.claimedAmount;
        uint32 start = position.start;
        uint32 duration = position.duration;

        if (totalAmount == 0) {
            revert NoClaimAssigned();
        }

        fullVestedAmount = computeClaimableAmount(
            start,
            timestampAtClaimingTime,
            duration,
            totalAmount
        );
    }

    /// Given the parameters of a vesting position, computes how much of the total amount has been vested so far.
    /// @param start Timestamp when the vesting position was started.
    /// @param current Timestamp of the point in time when the vested amount should be computed.
    /// @param duration How long it takes for this vesting position to be fully vested.
    /// @param totalAmount The total amount that is being vested.
    /// @return The amount that has been vested at the specified point in time.
    function computeClaimableAmount(
        uint32 start,
        uint256 current,
        uint32 duration,
        uint96 totalAmount
    ) internal pure returns (uint96) {
        if (current <= start) {
            return 0;
        }
        uint256 elapsedTime = current - start;
        if (elapsedTime >= duration) {
            return totalAmount;
        }
        return uint96((uint256(totalAmount) * elapsedTime) / duration);
    }

    /// @dev Takes the parameters of a vesting position from its input values and sends out the claimed COW to the
    /// beneficiary, taking care of updating the claimed amount.
    /// @param beneficiary The address that should receive the COW tokens.
    /// @param amount The amount of COW that is claimed by the beneficiary.
    /// @param alreadyClaimedAmount The amount that has already been claimed by the beneficiary.
    /// @param fullVestedAmount The total amount of COW that has been vested so far, which includes the amount that
    /// was already claimed.
    function claimCowFromAmounts(
        address beneficiary,
        uint96 amount,
        uint96 alreadyClaimedAmount,
        uint96 fullVestedAmount
    ) internal {
        uint96 claimedAfterPayout = alreadyClaimedAmount + amount;
        if (claimedAfterPayout > fullVestedAmount) {
            revert NotEnoughVestedTokens();
        }

        allocation[beneficiary].claimedAmount = claimedAfterPayout;
        swapVcowIfAvailable(amount);
        transferCow(beneficiary, amount);

        emit ClaimRedeemed(beneficiary, amount);
    }

    /// @dev Swaps an exact amount of vCOW tokens that are held in the module controller in exchange for COW tokens. The
    /// COW tokens are left in the module controller. If swapping reverts (which means that not enough vCOW are
    /// available) then the failure is ignored.
    /// @param amount The amount of vCOW to swap.
    function swapVcowIfAvailable(uint256 amount) internal {
        // The success status is explicitely ignored. This means that the call to `swap` could revert without reverting
        // the execution of this function. Note that this function can still revert if the call to
        // `execTransactionFromModule` reverts, which could happen for example if this module is no longer enabled in
        // the controller.
        //bool success =
        controller.execTransactionFromModule(
            address(vcow),
            0,
            abi.encodeWithSelector(vcow.swap.selector, amount),
            Enum.Operation.Call
        );
    }

    /// @dev Transfer the specified exact amount of COW tokens that are held in the module controller to the target.
    /// @param to The address that will receive transfer.
    /// @param amount The amount of COW to transfer.
    function transferCow(address to, uint256 amount) internal {
        // Note: the COW token reverts on failed transfer, there is no need to check the return value.
        bool success = controller.execTransactionFromModule(
            address(cow),
            0,
            abi.encodeWithSelector(cow.transfer.selector, to, amount),
            Enum.Operation.Call
        );
        if (!success) {
            revert RevertedCowTransfer();
        }
    }
}