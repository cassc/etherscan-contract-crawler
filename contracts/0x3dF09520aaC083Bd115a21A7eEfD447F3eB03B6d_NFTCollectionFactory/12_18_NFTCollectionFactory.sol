// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/NFTCollectionFactory.sol";

contract $NFTCollectionFactory is NFTCollectionFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _rolesManager) NFTCollectionFactory(_rolesManager) {}

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    receive() external payable {}
}