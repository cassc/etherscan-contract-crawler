// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract CollectionFactory {
    using AddressUpgradeable for address;

    address public immutable collectionFactory;

    error AddressNotContract();
    error CallerNotCollectionFactory();

    modifier onlyCollectionFactory() {
        if (msg.sender != address(collectionFactory))
            revert CallerNotCollectionFactory();
        _;
    }

    constructor(address _collectionFactory) {
        if (!_collectionFactory.isContract()) revert AddressNotContract();
        collectionFactory = _collectionFactory;
    }
}