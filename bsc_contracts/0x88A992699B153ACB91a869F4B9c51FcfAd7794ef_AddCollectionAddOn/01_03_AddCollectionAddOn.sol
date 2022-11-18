// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddCollectionAddOn is Ownable {
    event AddCollection(address add_);
    mapping(address => bool) private addressAdded;

    function addCollection(address add_) external onlyOwner returns (bool) {
        require(!addressAdded[add_]);
        addressAdded[add_] = true;
        emit AddCollection(add_);
        return true;
    }

    function isAddedCollection(address add_) external view returns (bool) {
        return addressAdded[add_];
    }
}