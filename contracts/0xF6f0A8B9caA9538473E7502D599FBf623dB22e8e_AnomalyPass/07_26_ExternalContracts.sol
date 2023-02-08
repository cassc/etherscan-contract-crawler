// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Admins.sol";


abstract contract ExternalContracts is Admins {

    mapping(address => bool) internal contracts;

    modifier externalContract() {
        require(isExternalContract(_msgSender()), "ExternalContracts: not external Contract");
        _;
    }

    function isExternalContract(address _contractAddress) public view returns(bool){
        return contracts[_contractAddress];
    }

    function setExternalContract(address _contract, bool _state) public onlyOwnerOrAdmins {
        contracts[_contract] = _state;
    }

}