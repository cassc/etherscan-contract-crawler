// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract FailSafeByteCodeConstants {
    function getBeaconCode() external pure returns (bytes memory) {
        return type(BeaconProxy).creationCode;
    }
}