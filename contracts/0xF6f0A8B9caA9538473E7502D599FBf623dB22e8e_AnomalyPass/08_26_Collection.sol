// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Admins.sol";


abstract contract Collection is Admins {

    address public contractAddress;

    function isCollectionContract(address _contractAddress) public view returns(bool){
        return contractAddress == _contractAddress;
    }

    function setCollection(address _contractAddress) public onlyOwnerOrAdmins {
        contractAddress = _contractAddress;
    }
}