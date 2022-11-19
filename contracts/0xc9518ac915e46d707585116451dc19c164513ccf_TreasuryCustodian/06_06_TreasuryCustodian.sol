// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {TRSRYv1} from "modules/TRSRY/TRSRY.v1.sol";

import "src/Kernel.sol";

// Generic contract to allow authorized contracts to interact with treasury
// Use cases include setting and removing approvals, as well as allocating assets for yield
contract TreasuryCustodian is Policy, RolesConsumer {
    // =========  EVENTS ========= //

    event ApprovalRevoked(address indexed policy_, ERC20[] tokens_);

    // =========  ERRORS ========= //

    error PolicyStillActive();

    // =========  STATE ========= //

    TRSRYv1 public TRSRY;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_) Policy(kernel_) {}

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("TRSRY");
        dependencies[1] = toKeycode("ROLES");

        TRSRY = TRSRYv1(getModuleAddress(dependencies[0]));
        ROLES = ROLESv1(getModuleAddress(dependencies[1]));
    }

    /// @inheritdoc Policy
    function requestPermissions() external view override returns (Permissions[] memory requests) {
        Keycode TRSRY_KEYCODE = TRSRY.KEYCODE();

        requests = new Permissions[](6);
        requests[0] = Permissions(TRSRY_KEYCODE, TRSRY.withdrawReserves.selector);
        requests[1] = Permissions(TRSRY_KEYCODE, TRSRY.increaseWithdrawApproval.selector);
        requests[2] = Permissions(TRSRY_KEYCODE, TRSRY.decreaseWithdrawApproval.selector);
        requests[3] = Permissions(TRSRY_KEYCODE, TRSRY.increaseDebtorApproval.selector);
        requests[4] = Permissions(TRSRY_KEYCODE, TRSRY.decreaseDebtorApproval.selector);
        requests[5] = Permissions(TRSRY_KEYCODE, TRSRY.setDebt.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Allow an address to withdraw `amount_` from the treasury
    function grantWithdrawerApproval(
        address for_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole("custodian") {
        TRSRY.increaseWithdrawApproval(for_, token_, amount_);
    }

    /// @notice Lower an address's withdrawer approval
    function reduceWithdrawerApproval(
        address for_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole("custodian") {
        TRSRY.decreaseWithdrawApproval(for_, token_, amount_);
    }

    /// @notice Custodian can withdraw reserves to an address.
    /// @dev    Used for withdrawing assets to a MS or other address in special cases.
    function withdrawReservesTo(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole("custodian") {
        TRSRY.withdrawReserves(to_, token_, amount_);
    }

    /// @notice Allow an address to incur `amount_` of debt from the treasury
    function grantDebtorApproval(
        address for_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole("custodian") {
        TRSRY.increaseDebtorApproval(for_, token_, amount_);
    }

    /// @notice Lower an address's debtor approval
    function reduceDebtorApproval(
        address for_,
        ERC20 token_,
        uint256 amount_
    ) external onlyRole("custodian") {
        TRSRY.decreaseDebtorApproval(for_, token_, amount_);
    }

    /// @notice Allow authorized addresses to increase debt in special cases
    function increaseDebt(
        ERC20 token_,
        address debtor_,
        uint256 amount_
    ) external onlyRole("custodian") {
        uint256 debt = TRSRY.reserveDebt(token_, debtor_);
        TRSRY.setDebt(debtor_, token_, debt + amount_);
    }

    /// @notice Allow authorized addresses to decrease debt in special cases
    function decreaseDebt(
        ERC20 token_,
        address debtor_,
        uint256 amount_
    ) external onlyRole("custodian") {
        uint256 debt = TRSRY.reserveDebt(token_, debtor_);
        TRSRY.setDebt(debtor_, token_, debt - amount_);
    }

    /// @notice Anyone can call to revoke a deactivated policy's approvals.
    function revokePolicyApprovals(address policy_, ERC20[] memory tokens_)
        external
        onlyRole("custodian")
    {
        if (Policy(policy_).isActive()) revert PolicyStillActive();

        uint256 len = tokens_.length;
        for (uint256 j; j < len; ) {
            uint256 wApproval = TRSRY.withdrawApproval(policy_, tokens_[j]);
            if (wApproval > 0) TRSRY.decreaseWithdrawApproval(policy_, tokens_[j], wApproval);

            uint256 dApproval = TRSRY.debtApproval(policy_, tokens_[j]);
            if (dApproval > 0) TRSRY.decreaseDebtorApproval(policy_, tokens_[j], dApproval);

            unchecked {
                ++j;
            }
        }

        emit ApprovalRevoked(policy_, tokens_);
    }
}