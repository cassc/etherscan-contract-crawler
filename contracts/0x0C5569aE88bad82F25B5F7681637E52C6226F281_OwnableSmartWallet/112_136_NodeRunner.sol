// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { LiquidStakingManager } from "../../liquid-staking/LiquidStakingManager.sol";
import { TestUtils } from "../../../test/utils/TestUtils.sol";
contract NodeRunner {
    bytes blsPublicKey1;
    LiquidStakingManager manager;
    TestUtils testUtils;
    constructor(LiquidStakingManager _manager, bytes memory _blsPublicKey1, bytes memory _blsPublicKey2, address _testUtils) payable public {
        manager = _manager;
        blsPublicKey1 = _blsPublicKey1;
        testUtils = TestUtils(_testUtils);
        //register BLS Key #1
        manager.registerBLSPublicKeys{ value: 4 ether }(
            testUtils.getBytesArrayFromBytes(blsPublicKey1),
            testUtils.getBytesArrayFromBytes(blsPublicKey1),
            address(0xdeadbeef)
        );
        // Register BLS Key #2
        manager.registerBLSPublicKeys{ value: 4 ether }(
            testUtils.getBytesArrayFromBytes(_blsPublicKey2),
            testUtils.getBytesArrayFromBytes(_blsPublicKey2),
            address(0xdeadbeef)
        );
    }
    receive() external payable {
        testUtils.stakeSingleBlsPubKey(blsPublicKey1);
    }
}