// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./common/DelegatorInterface.sol";
import "./common/Adminable.sol";
import "./OPBuyBack.sol";

contract OPBuyBackDelegator is DelegatorInterface, Adminable {
    constructor(address _ole, address _wrappedNativeToken, address _router1inch, address payable _admin, address implementation_) {
        admin = payable(msg.sender);
        // Creator of the contract is admin during initialization
        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSelector(OPBuyBack(implementation_).initialize.selector, _ole, _wrappedNativeToken, _router1inch));
        implementation = implementation_;
        // Set the proper admin now that initialization is done
        admin = _admin;
    }

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public override onlyAdmin {
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }
}