// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IAddressRegistry} from "../../interfaces/IAddressRegistry.sol";
import {ILenderVaultImpl} from "../../interfaces/ILenderVaultImpl.sol";
import {DataTypesPeerToPeer} from "../../DataTypesPeerToPeer.sol";
import {BaseCompartment} from "../BaseCompartment.sol";
import {Errors} from "../../../Errors.sol";

contract VoteCompartment is BaseCompartment {
    using SafeERC20 for IERC20;

    mapping(address => bool) public approvedDelegator;

    function delegate(address _delegatee) external {
        DataTypesPeerToPeer.Loan memory loan = ILenderVaultImpl(vaultAddr).loan(
            loanIdx
        );
        if (msg.sender != loan.borrower && !approvedDelegator[msg.sender]) {
            revert Errors.InvalidSender();
        }
        if (block.timestamp >= loan.expiry) {
            revert Errors.LoanExpired();
        }
        if (_delegatee == address(0)) {
            revert Errors.InvalidDelegatee();
        }
        uint256 preDelegateCompartmentBal = IERC20(loan.collToken).balanceOf(
            address(this)
        );
        IVotes(loan.collToken).delegate(_delegatee);
        if (
            preDelegateCompartmentBal >
            IERC20(loan.collToken).balanceOf(address(this))
        ) {
            revert Errors.DelegateReducedBalance();
        }
        emit Delegated(msg.sender, _delegatee);
    }

    function toggleApprovedDelegator(address _delegate) external {
        DataTypesPeerToPeer.Loan memory loan = ILenderVaultImpl(vaultAddr).loan(
            loanIdx
        );
        if (msg.sender != loan.borrower) {
            revert Errors.InvalidSender();
        }
        bool currDelegateState = approvedDelegator[_delegate];
        approvedDelegator[_delegate] = !currDelegateState;
        emit UpdatedApprovedDelegator(_delegate, !currDelegateState);
    }

    // transfer coll on repays
    function transferCollFromCompartment(
        uint256 /*repayAmount*/,
        uint256 /*repayAmountLeft*/,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr
    ) external {
        _transferCollFromCompartment(
            reclaimCollAmount,
            borrowerAddr,
            collTokenAddr,
            callbackAddr
        );
    }

    // unlockColl this would be called on defaults
    function unlockCollToVault(address collTokenAddr) external {
        _unlockCollToVault(collTokenAddr);
    }

    function getReclaimableBalance(
        address collToken
    ) external view override returns (uint256) {
        return IERC20(collToken).balanceOf(address(this));
    }
}