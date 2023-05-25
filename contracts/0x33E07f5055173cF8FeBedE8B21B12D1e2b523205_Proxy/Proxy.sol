/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

pragma solidity ^0.7.0;

/**
* @title Proxy 
* @dev Etherland - ERC1822 Proxy contract implementation for ELAND ERC20
* @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1822.md
*/
contract Proxy {
    constructor(bytes memory constructData, address contractLogic) {
        assembly { 
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
        (bool success, bytes memory _ ) = contractLogic.delegatecall(constructData); 
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { 
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}