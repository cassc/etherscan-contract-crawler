// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../implementations/InitializableAuthorizedImplementation.sol';

contract InitializableAuthorizedImplementationMock is InitializableAuthorizedImplementation {
    bytes32 public constant override NAMESPACE = keccak256('INITIALIZABLE_AUTHORIZED_IMPLEMENTATION_MOCK');

    constructor(address registry) InitializableAuthorizedImplementation(registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(address admin) external initializer {
        _initialize(admin);
    }
}