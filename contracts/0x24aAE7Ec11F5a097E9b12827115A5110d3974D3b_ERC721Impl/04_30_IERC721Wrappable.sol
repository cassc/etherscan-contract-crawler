// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Wrappable {

    event CollectionOwnershipTransferred(address indexed collection, address indexed previousOwner,
        address indexed newOwner);

    function transferCollectionOwnership(address _collection, address _Wrappable) external;
}