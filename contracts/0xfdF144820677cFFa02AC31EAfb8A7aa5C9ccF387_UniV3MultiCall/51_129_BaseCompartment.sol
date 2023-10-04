// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBaseCompartment} from "../interfaces/compartments/IBaseCompartment.sol";
import {ILenderVaultImpl} from "../interfaces/ILenderVaultImpl.sol";
import {Errors} from "../../Errors.sol";

abstract contract BaseCompartment is Initializable, IBaseCompartment {
    using SafeERC20 for IERC20;

    address public vaultAddr;
    uint256 public loanIdx;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _vaultAddr,
        uint256 _loanIdx
    ) external initializer {
        if (_vaultAddr == address(0)) {
            revert Errors.InvalidAddress();
        }
        vaultAddr = _vaultAddr;
        loanIdx = _loanIdx;
    }

    // transfer coll on repays
    function _transferCollFromCompartment(
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr
    ) internal {
        _withdrawCheck();
        if (msg.sender != vaultAddr) revert Errors.InvalidSender();
        address collReceiver = callbackAddr == address(0)
            ? borrowerAddr
            : callbackAddr;
        IERC20(collTokenAddr).safeTransfer(collReceiver, reclaimCollAmount);
    }

    function _unlockCollToVault(address collTokenAddr) internal {
        _withdrawCheck();
        if (msg.sender != vaultAddr) revert Errors.InvalidSender();
        uint256 currentCollBalance = IERC20(collTokenAddr).balanceOf(
            address(this)
        );
        IERC20(collTokenAddr).safeTransfer(msg.sender, currentCollBalance);
    }

    function _withdrawCheck() internal view {
        bool withdrawEntered = ILenderVaultImpl(vaultAddr).withdrawEntered();
        if (withdrawEntered) {
            revert Errors.WithdrawEntered();
        }
    }
}