// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* A custom implementation of EIP-2535
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {ParaProxyLib} from "./lib/ParaProxyLib.sol";
import {IParaProxy} from "../../../interfaces/IParaProxy.sol";

contract ParaProxy is IParaProxy {
    constructor(address _contractOwner) payable {
        ParaProxyLib.setContractOwner(_contractOwner);
    }

    function updateImplementation(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external override {
        ParaProxyLib.enforceIsContractOwner();
        ParaProxyLib.updateImplementation(
            _implementationParams,
            _init,
            _calldata
        );
    }

    // Find implementation for function that is called and execute the
    // function if a implementation is found and return any value.
    fallback() external payable {
        ParaProxyLib.ProxyStorage storage ds;
        bytes32 position = ParaProxyLib.PROXY_STORAGE_POSITION;
        // get proxy storage
        assembly {
            ds.slot := position
        }
        // get implementation from function selector
        address implementation = ds
            .selectorToImplAndPosition[msg.sig]
            .implAddress;
        require(
            implementation != address(0),
            "ParaProxy: Function does not exist"
        );
        // Execute external function from implementation using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the implementation
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}