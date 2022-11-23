// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegate} from "./IDelegate.sol";
import {IDelegateManager} from "./IDelegateManager.sol";
import {DelegateDeployer} from "./DelegateDeployer.sol";

struct DelegateManagerConstructorParams {
    /**
     * @dev {IDelegate}-compatible contract address
     */
    address delegatePrototype;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Inherits {DelegateDeployer} to have access to delegates as their initializer
 */
contract DelegateManager is IDelegateManager, DelegateDeployer {
    address private immutable _withdrawWhitelist;

    // prettier-ignore
    constructor(DelegateManagerConstructorParams memory params_)
        DelegateDeployer(params_.delegatePrototype)
    {
        require(params_.withdrawWhitelist != address(0), "DF: zero withdraw whitelist");
        _withdrawWhitelist = params_.withdrawWhitelist;
    }

    modifier onlyWhitelistedWithdrawer() {
        require(
            IAccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender),
            "DF: withdrawer not whitelisted"
        );
        _;
    }

    modifier asDelegateOwner(address delegate_) {
        address savedOwner = IDelegate(delegate_).owner();
        IDelegate(delegate_).setOwner(address(this));
        _;
        IDelegate(delegate_).setOwner(savedOwner);
    }

    function withdraw(address account_, Withdraw[] calldata withdraws_) external onlyWhitelistedWithdrawer {
        address delegate = predictDelegateDeploy(account_);
        _withdraw(delegate, withdraws_);
    }

    function _withdraw(address delegate_, Withdraw[] calldata withdraws_) private asDelegateOwner(delegate_) {
        IDelegate(delegate_).withdraw(withdraws_);
    }
}