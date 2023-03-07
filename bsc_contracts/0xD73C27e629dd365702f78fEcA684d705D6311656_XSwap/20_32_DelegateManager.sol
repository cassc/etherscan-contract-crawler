// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";
import {Withdraw} from "../withdraw/Withdrawable.sol";
import {Delegate} from "./Delegate.sol";

contract DelegateManager {
    address private immutable _delegatePrototype;
    address private immutable _withdrawWhitelist;

    constructor(address delegatePrototype_, address withdrawWhitelist_) {
        _delegatePrototype = delegatePrototype_;
        _withdrawWhitelist = withdrawWhitelist_;
    }

    modifier onlyWhitelistedWithdrawer() {
        require(AccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender), "DM: withdrawer not whitelisted");
        _;
    }

    function predictDelegateDeploy(address account_) public view returns (address) {
        return Clones.predictDeterministicAddress(_delegatePrototype, _calcSalt(account_));
    }

    function deployDelegate(address account_) public returns (address) {
        Delegate delegate = Delegate(payable(Clones.cloneDeterministic(_delegatePrototype, _calcSalt(account_))));
        delegate.initialize();
        delegate.transferOwnership(account_);
        return address(delegate);
    }

    function isDelegateDeployed(address account_) public view returns (bool) {
        return Address.isContract(predictDelegateDeploy(account_));
    }

    function withdraw(address account_, Withdraw[] calldata withdraws_) external onlyWhitelistedWithdrawer {
        Delegate delegate = Delegate(payable(predictDelegateDeploy(account_)));
        address savedOwner = delegate.owner();
        delegate.setOwner(address(this));
        delegate.withdraw(withdraws_);
        delegate.setOwner(savedOwner);
    }

    function _calcSalt(address account_) private pure returns (bytes32) {
        return bytes20(account_);
    }
}