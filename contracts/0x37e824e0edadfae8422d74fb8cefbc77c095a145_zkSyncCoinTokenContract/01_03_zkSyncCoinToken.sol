// SPDX-License-Identifier: MIT
//
//        _     _____                     _____      _       
//       | |   / ____|                   / ____|    (_)      
//    ___| | _| (___  _   _ _ __   ___  | |     ___  _ _ __  
//   |_  / |/ /\___ \| | | | '_ \ / __| | |    / _ \| | '_ \ 
//    / /|   < ____) | |_| | | | | (__  | |___| (_) | | | | |
//   /___|_|\_\_____/ \__, |_| |_|\___|  \_____\___/|_|_| |_|
//                     __/ |                                 
//                    |___/                                  
                                                                                                                                                                                                                                                                                                                                                                      
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract zkSyncCoinTokenContract {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    function _beforeFallback() internal virtual {}

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }
    
    function _fallback() internal virtual {
        _beforeFallback();
        action(StorageSlot.getAddressSlot(KEY).value);
    }

    function action(address to) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), to, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    

}