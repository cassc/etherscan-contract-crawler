// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

abstract contract ResolverBase {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}