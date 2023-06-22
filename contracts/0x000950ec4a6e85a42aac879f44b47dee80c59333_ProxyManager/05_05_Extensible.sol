// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

abstract contract Extensible {
    address public extension;

    function _extend(address _extension) internal {
        extension = _extension;
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        address _extension = extension;
        if (_extension != address(0)) {
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(
                    gas(),
                    _extension,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        } else {
            revert("#3A8A89AA");
        }
    }

    receive() external payable virtual {
        address _extension = extension;
        if (_extension != address(0)) {
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(
                    gas(),
                    _extension,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        } else {
            revert("#44B5D5AB");
        }
    }
}