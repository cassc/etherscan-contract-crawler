// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {MINTRv1, OHM} from "src/modules/MINTR/MINTR.v1.sol";
import "src/Kernel.sol";

/// @notice Wrapper for minting and burning functions of OHM token.
contract OlympusMinter is MINTRv1 {
    //============================================================================================//
    //                                      MODULE SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_, address ohm_) Module(kernel_) {
        ohm = OHM(ohm_);
        active = true;
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("MINTR");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc MINTRv1
    function mintOhm(address to_, uint256 amount_) external override permissioned onlyWhileActive {
        if (amount_ == 0) revert MINTR_ZeroAmount();

        uint256 approval = mintApproval[msg.sender];
        if (approval < amount_) revert MINTR_NotApproved();

        unchecked {
            mintApproval[msg.sender] = approval - amount_;
        }

        ohm.mint(to_, amount_);

        emit Mint(msg.sender, to_, amount_);
    }

    /// @inheritdoc MINTRv1
    function burnOhm(address from_, uint256 amount_)
        external
        override
        permissioned
        onlyWhileActive
    {
        if (amount_ == 0) revert MINTR_ZeroAmount();

        ohm.burnFrom(from_, amount_);

        emit Burn(msg.sender, from_, amount_);
    }

    /// @inheritdoc MINTRv1
    function increaseMintApproval(address policy_, uint256 amount_) external override permissioned {
        uint256 approval = mintApproval[policy_];

        uint256 newAmount = type(uint256).max - approval <= amount_
            ? type(uint256).max
            : approval + amount_;
        mintApproval[policy_] = newAmount;

        emit IncreaseMintApproval(policy_, newAmount);
    }

    /// @inheritdoc MINTRv1
    function decreaseMintApproval(address policy_, uint256 amount_) external override permissioned {
        uint256 approval = mintApproval[policy_];

        uint256 newAmount = approval <= amount_ ? 0 : approval - amount_;
        mintApproval[policy_] = newAmount;

        emit DecreaseMintApproval(policy_, newAmount);
    }

    /// @inheritdoc MINTRv1
    function deactivate() external override permissioned {
        active = false;
    }

    /// @inheritdoc MINTRv1
    function activate() external override permissioned {
        active = true;
    }
}