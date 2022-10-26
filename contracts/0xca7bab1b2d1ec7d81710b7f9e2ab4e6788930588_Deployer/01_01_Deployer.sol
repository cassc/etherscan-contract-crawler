// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6;

contract Deployer {
    function deployCall(bytes memory contractCode, bytes memory callCode) external returns (bytes memory resultData) {
        address addr;
        assembly {
            addr := create(0, add(contractCode, 0x20), mload(contractCode))
        }
        (, resultData) = addr.call(callCode);
    }
}