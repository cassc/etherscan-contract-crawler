/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract GeneralPurposeProxy {

    constructor(address source) payable {
        assembly {
            sstore(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69, source)
        }
    }

    fallback() external payable {
        assembly {
            let _singleton := sload(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
                case 0 {revert(0, returndatasize())}
                default { return(0, returndatasize())}
        }
    }
}