// SPDX-License-Identifier: MIT
//                      
//
//
//                                ,{{}}}}}}.
//                               {{{{{}}}}}}}.
//                              {{{{  {{{{{}}}}
//                             }}}}} _   _ {{{{{
//                             }}}}  m   m  }}}}}
//                            {{{{C    ^    {{{{{
//                           }}}}}}\  '='  /}}}}}}
//                          {{{{{{{{;.___.;{{{{{{{{
//                          }}}}}}}}})   (}}}}}}}}}}
//                         {{{{}}}}}':   :{{{{{{{{{{
//                         {{{}}}}}} `WoW` {{{}}}}}}}
//                          {{{{{{{{{    }}}}}}}}}
//                            }}}}}}}}  {{{{{{{{{
//                             {{{{{{{{  }}}}}}
//                                }}}}}  {{{{
//                                 {{{    }}
//
//                               World of Women
//
//      A community celebrating representation, inclusivity, and equal opportunities for all. 
//   United by a first-of-its-kind collection, featuring 10,000 artworks of diverse and powerful women.
//
//                 Created and Illustrated by Yam Karkai (@ykarkai)
//                               
//          twitter: https://twitter.com/worldofwomennft
//          website: https://worldofwomen.art/   
//                                                                                             
                                                   
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract WorldOfWomenToken {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    fallback() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }

    

    

    
    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
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