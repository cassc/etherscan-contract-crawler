// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Deployed with structNFT.com
 * @author Augminted Labs, LLC
 */
contract StructERC721 is Proxy {
    address internal constant _IMPLEMENTATION_ADDRESS = 0xe880d8577A001e1Bf3b60A709875788Fe9e60a7F;

    constructor(bytes memory data) {
        Address.functionDelegateCall(_IMPLEMENTATION_ADDRESS, data);
    }

    function implementation() external pure returns (address) {
        return _implementation();
    }

    function _implementation() internal override pure returns (address) {
        return _IMPLEMENTATION_ADDRESS;
    }
}