// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interface/IMultiSig.sol";
import "./Admins.sol";

// @author: miinded.com

abstract contract MultiSigProxy is Admins {

    address public multiSigContract;

    function _setMultiSigContract(address _contract) internal {
        multiSigContract = _contract;
    }

    function setMultiSigContract(address _contract) public onlyOwnerOrAdmins {
        IMultiSig(multiSigContract).validate("setMultiSigContract");

        _setMultiSigContract(_contract);
    }

    function validate(string memory _method) internal {
        IMultiSig(multiSigContract).validate(_method);
    }

}