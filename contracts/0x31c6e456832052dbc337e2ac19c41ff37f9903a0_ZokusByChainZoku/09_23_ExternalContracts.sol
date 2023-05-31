// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MultiSigProxy.sol";

// @author: miinded.com

abstract contract ExternalContracts is MultiSigProxy {

    mapping(address => bool) internal contracts;
    bool private init = false;

    modifier externalContract() {
        require(isExternalContract(_msgSender()), "ExternalContracts: not external Contract");
        _;
    }

    function isExternalContract(address _contractAddress) public view returns(bool){
        return contracts[_contractAddress];
    }

    function setExternalContract(address _contract, bool _state) public onlyOwnerOrAdmins {
        MultiSigProxy.validate("setExternalContract");

        _setExternalContract(_contract, _state);
    }
    function _setExternalContract(address _contract, bool _state) internal {
        contracts[_contract] = _state;
    }

}