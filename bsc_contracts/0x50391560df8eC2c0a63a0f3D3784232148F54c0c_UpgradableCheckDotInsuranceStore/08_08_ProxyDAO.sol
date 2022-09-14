// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./UpgradableProxyDAO.sol";

/**
 * @title ProxyDAO
 * @author Jeremy Guyet (@jguyet)
 * @dev ProxyDAO contract allows the binding of a version by version
 * implementation which can be updated thanks to the
 * UpgradableProxyDAO abstraction which allows the proxy a
 * DAO governance.
 */
contract ProxyDAO is UpgradableProxyDAO {

    constructor(address _cdtGouvernanceAddress) UpgradableProxyDAO(_cdtGouvernanceAddress) { }

    /**
     * @dev This is the fallback function a fall back function is triggered if someone
     * sends a function call or a transaction to this contract AND there is no function
     * that corresponds to the name the callers is trying to execute.
     * Each call is then passed to the _delegate function which will call the functions
     * of the functional implementation.
     */
    fallback() external payable {
        _delegate(_getImplementation());
    }

    /**
     * @dev This is the receive function is triggered if someone send transaction to
     * this contract. Each call is then passed to the _delegate function which will
     * call the functions of the functional implementation.
     */
    receive() external payable {
        _delegate(_getImplementation());
    }

    /**
     * @dev This is the fallback function a fall back function is triggered if someone
     * sends a function call or a transaction to this contract AND there is no function
     * that corresponds to the name the callers is trying to execute 
     * e.g. if someone tries to call HelloWorld() to this contract, which doesn't exist
     * in this contract, then the fallback function will be called. 
     * In this case, the fallback function will redirect the call to the functional contract
     */
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This function is called once the implementation is updated.
     * It calls the initialize function of the proxy contract,
     * this allows an update of some variables if necessary
     * when updating the proxy code again.
     */
    function _afterUpgrade(address _newFunctionalAddress, bytes memory _initializationData) internal virtual override {
        address implementation = _newFunctionalAddress;
        bytes memory data = abi.encodeWithSignature("initialize(bytes)", _initializationData);

        assembly {
            let result := delegatecall(
                gas(),
                implementation,
                add(data, 0x20), // add is another assembly function; this changes the format to something that delegate call can read
                mload(data), // mload is memory load
                0,
                0
            )
            let size := returndatasize()
            let ptr := mload(0x40) // ptr as in pointer
            returndatacopy(ptr, 0, size)
            switch result // result will either be 0 (as in function call failed), or 1 (function call success)
            case 0 {
                revert(ptr, size)
            } // revert if function call failed
            default {
                return(ptr, size)
            } // default means "else"; else return
        }
    }
}