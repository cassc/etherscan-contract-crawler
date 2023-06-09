/**
 * Submitted for re-verification at Etherscan.io on 2022-03-19;
 *
 * Copyright 2021-2022 ToonCoin.COM
 * https://tooncoin.com/license
 * Full source code: https://tooncoin.com/sourcecode
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./EIP1967/EIP1967Reader.sol";

contract ToonTokenProxy is EIP1967Reader, Proxy {
    constructor(address implementationAddress) {
        require(
            Address.isContract(implementationAddress),
            "implementation is not a contract"
        );

        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = implementationAddress;

        bytes memory data = abi.encodePacked(_INITIALIZE_CALL);
        Address.functionDelegateCall(implementationAddress, data);
    }

    function implementation() external view returns (address) {
        return _implementationAddress();
    }

    function _implementation() internal view override returns (address) {
        return _implementationAddress();
    }
}

// Copyright 2021-2022 ToonCoin.COM
// https://tooncoin.com/license
// Full source code: https://tooncoin.com/sourcecode