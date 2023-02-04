// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./Clones.sol";
import "./Address.sol";

import "./IDelegate.sol";
import "./IDelegateDeployer.sol";

contract DelegateDeployer is IDelegateDeployer {
    address private immutable _delegatePrototype;

    constructor(address delegatePrototype_) {
        require(delegatePrototype_ != address(0), "DF: zero delegate proto");
        _delegatePrototype = delegatePrototype_;
    }

    function predictDelegateDeploy(address account_) public view returns (address) {
        return Clones.predictDeterministicAddress(_delegatePrototype, _calcSalt(account_));
    }

    function deployDelegate(address account_) public returns (address) {
        address delegate = Clones.cloneDeterministic(_delegatePrototype, _calcSalt(account_));
        IDelegate(delegate).initialize();
        IDelegate(delegate).transferOwnership(account_);
        return delegate;
    }

    function isDelegateDeployed(address account_) public view returns (bool) {
        address delegate = predictDelegateDeploy(account_);
        return Address.isContract(delegate);
    }

    function _calcSalt(address account_) private pure returns (bytes32) {
        return bytes20(account_);
    }
}