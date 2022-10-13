// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TrustedForwarder is Initializable {

    address private _trustedForwarder;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __TrustedForwarder_init() internal onlyInitializing {
        _trustedForwarder = address(0);
    }


    /**
    * @dev setup trusted forwarder address
    * @param forwarder trustedforwarder's address to set
    * @custom:shortd setup trusted forwarder
    * @custom:calledby owner
    */
    function _setTrustedForwarder(
        address forwarder
    ) 
        internal 
      //  onlyOwner 
        //excludeTrustedForwarder 
    {
        //require(owner() != forwarder, "FORWARDER_CAN_NOT_BE_OWNER");
        _trustedForwarder = forwarder;
    }
    function setTrustedForwarder(address forwarder) public virtual;
    /**
    * @dev checking if forwarder is trusted
    * @param forwarder trustedforwarder's address to check
    * @custom:shortd checking if forwarder is trusted
    */
    function isTrustedForwarder(
        address forwarder
    ) 
        external
        view 
        returns(bool) 
    {
        return _isTrustedForwarder(forwarder);
    }

    /**
    * @dev implemented EIP-2771
    */
    function _msgSender(
    ) 
        internal 
        view 
        virtual
        returns (address signer) 
    {
        signer = msg.sender;
        if (msg.data.length>=20 && _isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96,calldataload(sub(calldatasize(),20)))
            }
        }    
    }

    // function transferOwnership(
    //     address newOwner
    // ) public 
    //     virtual 
    //     override 
    //     onlyOwner 
    // {
    //     require(msg.sender != _trustedForwarder, "DENIED_FOR_FORWARDER");
    //     if (newOwner == _trustedForwarder) {
    //         _trustedForwarder = address(0);
    //     }
    //     super.transferOwnership(newOwner);
        
    // }

    function _isTrustedForwarder(
        address forwarder
    ) 
        internal
        view 
        returns(bool) 
    {
        return forwarder == _trustedForwarder;
    }


  

}