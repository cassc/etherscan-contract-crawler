// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "Owned.sol";

contract PartiallyUpgradable is Owned {

    address public partialUpgrade;

    function partialUpgradable(address _partialUpgrade) public onlyOwner {
        partialUpgrade = _partialUpgrade;
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        address _partialUpgrade = partialUpgrade;
        if (_partialUpgrade != address(0)) {
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), _partialUpgrade, 0, calldatasize(), 0, 0)
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
            revert('No such function');
        }
    }


}