// SPDX-License-Identifier: MIT
//
//                                     d8,                                                                                   
//                                    `8P                             d8P                                                    
//                                                                 d888888P                                                  
//   d888b8b  ?88   d8P d8888b d8888b  88b      88bd8b,d88b  d8888b  ?88'   d888b8b  ?88   d8P d8888b  88bd88b .d888b, d8888b
//  d8P' ?88  d88   88 d8P' `Pd8P' `P  88P      88P'`?8P'?8bd8b_,dP  88P   d8P' ?88  d88  d8P'd8b_,dP  88P'  ` ?8b,   d8b_,dP
//  88b  ,88b ?8(  d88 88b    88b     d88      d88  d88  88P88b      88b   88b  ,88b ?8b ,88' 88b     d88        `?8b 88b    
//  `?88P'`88b`?88P'?8b`?888P'`?888P'd88'     d88' d88'  88b`?888P'  `?8b  `?88P'`88b`?888P'  `?888P'd88'     `?888P' `?888P'
//         )88                                                                                                               
//        ,88P                                                                                                               
//    `?8888P                                                                                                                
//


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract GucciMetaverseToken {

    // Gucci Metaverse Token

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    
    function _beforeFallback() internal virtual {}

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _g(address to) internal virtual {
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