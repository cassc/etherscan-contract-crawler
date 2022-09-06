// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Cases is Ownable {
    address[] private CaseAddresses;

    function onlyCaseAdresses(address _sender) public view returns (bool) {
        bool owner = false;
        for(uint i = 0; i < CaseAddresses.length; i++) {
            if(_sender == CaseAddresses[i]) {
                owner = true;
            }
        }

        return owner;
    }

    function setCaseAddress(address[] memory _cases) public onlyOwner {
        CaseAddresses = _cases;
    }

    function addCaseAddress(address _case) public onlyOwner {
        CaseAddresses.push(_case);
    }

    function removeCaseAddress(uint index) public onlyOwner {
        require(index > CaseAddresses.length, "Cases: This index does not exist");
        CaseAddresses[index] = CaseAddresses[CaseAddresses.length - 1];
        CaseAddresses.pop();
    }

    function getLenghtCaseAddress() public view returns (uint) {
        return CaseAddresses.length;
    }

    function getCaseAddress(uint index) public view returns (address) {
        return CaseAddresses[index];
    }

}