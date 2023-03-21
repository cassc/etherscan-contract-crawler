// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

abstract contract ResolverBase is ERC165Upgradeable {
    function isAuthorized(bytes32 node) internal view virtual returns (bool);

    modifier authorized(bytes32 node) {
        require(isAuthorized(node), "not authorized");
        _;
    }
}