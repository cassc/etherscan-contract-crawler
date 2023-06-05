// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MultiSigProxy.sol";

// @author: miinded.com

abstract contract Collection is MultiSigProxy {

    address public collectionAddress;

    function isCollectionContract(address _collectionAddress) public view returns(bool){
        return collectionAddress == _collectionAddress;
    }

    function setCollection(address _collectionAddress) public onlyOwnerOrAdmins {
        MultiSigProxy.validate("setCollection");

        _setCollection(_collectionAddress);
    }

    function _setCollection(address _collectionAddress) internal {
        collectionAddress = _collectionAddress;
    }
}