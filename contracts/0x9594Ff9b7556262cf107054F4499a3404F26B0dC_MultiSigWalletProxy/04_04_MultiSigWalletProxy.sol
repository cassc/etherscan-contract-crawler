// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiSigWalletProxy {
    address public implementation;

    constructor(address _implementation, bytes memory _data) {
        implementation = _implementation;
        if(_data.length > 0) {
            (bool success,) = _implementation.delegatecall(_data);
            require(success, "MultiSigWalletProxy: Initialization failed");
        }
    }

    fallback() external payable {
        _delegate(implementation);
    }

    receive() external payable {
        _delegate(implementation);
    }

    function _delegate(address _implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { 
                revert(0, returndatasize()) 
            } default { 
                return(0, returndatasize())
            }
        }
    }
}