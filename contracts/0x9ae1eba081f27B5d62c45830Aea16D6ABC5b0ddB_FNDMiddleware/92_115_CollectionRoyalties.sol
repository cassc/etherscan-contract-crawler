// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/collections/CollectionRoyalties.sol";

abstract contract $CollectionRoyalties is CollectionRoyalties {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}