// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Beneficiary {

    mapping(address => bool) public beneficiaryAddresses;

    event BeneficiarySet(address beneficiaryAddress, bool isBeneficiary);
    constructor () {    
        beneficiaryAddresses[msg.sender] = true;
        emit BeneficiarySet(msg.sender, true);
    }

    modifier onlyBeneficiary() {
        require(beneficiaryAddresses[msg.sender] == true, "Caller is not the beneficiary");
        _;
    }

    function setSingleBeneficiary(address _beneficiary, bool _status) public onlyBeneficiary {
        beneficiaryAddresses[_beneficiary] = _status;
        emit BeneficiarySet(_beneficiary, _status);
    }

//    function setMultiBeneficiaryAddresses(address[] memory _beneficiary, bool _status) public onlyBeneficiary {
//        for (uint i = 0; i < _beneficiary.length; i++) {
//            beneficiaryAddresses[_beneficiary[i]] = _status;
//        }
//    }

    function getStatusBeneficiary(address _beneficiary) public view returns (bool) {
        return beneficiaryAddresses[_beneficiary];
    }

}