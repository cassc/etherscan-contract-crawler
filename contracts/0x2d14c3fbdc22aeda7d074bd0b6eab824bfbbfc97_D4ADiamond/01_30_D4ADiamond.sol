// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import "@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol";
import "@solidstate/contracts/access/ownable/SafeOwnable.sol";

import "./D4ADiamondBaseStorage.sol";
import "./D4ADiamondFallback.sol";

contract D4ADiamond is DiamondBase, D4ADiamondFallback, DiamondReadable, DiamondWritable, SafeOwnable {
    function initialize(address owner) public {
        D4ADiamondBaseStorage.Layout storage l = D4ADiamondBaseStorage.layout();
        require(!l.initialized, "Initialized!");
        // set owner
        _setOwner(owner);
        l.initialized = true;
    }

    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}