//SPDX-License-Identifier: MIT
/**

███████╗██████╗ ███████╗    ███╗   ███╗ █████╗ ██████╗ 
██╔════╝██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██╔══██╗
█████╗  ██████╔╝█████╗█████╗██╔████╔██║███████║██████╔╝
██╔══╝  ██╔═══╝ ██╔══╝╚════╝██║╚██╔╝██║██╔══██║██╔═══╝ 
██║     ██║     ███████╗    ██║ ╚═╝ ██║██║  ██║██║     
╚═╝     ╚═╝     ╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     
                                                       
github: https://github.com/estarriolvetch/fpe-mapping

 */
pragma solidity ^0.8.0;

library Feistel {
    /// Balanced Feistel network
    function feistel(uint256 input, uint256 key, uint256 round, uint256 size) internal pure returns (uint256) {
        unchecked {
            uint256 halfSize = size / 2;
            uint256 halfMap = (2 ** halfSize) - 1;
                
            uint256 left = (input >> halfSize) & halfMap;
            uint256 right = (input & halfMap);
            
            for(uint256 i=0; i < round; i++) {
                uint256 roundKey = uint256(keccak256(abi.encode(key, i)));
                uint256 left_new = right;
                uint256 right_new = left ^ (halfMap & uint256(keccak256(abi.encode(right, roundKey))));

                left = left_new;
                right = right_new;
            }
            return (left << halfSize) | right;
        }
    }

    /// Unbalanced Feistel network
    function feistelUnbalanced(uint256 input, uint256 key, uint256 round, uint256 size) internal pure returns (uint256) {
        unchecked {
            uint256 shortSize = size / 2;
            uint256 longSize = size - shortSize;
            
            uint256 longMap = (1 << longSize) - 1;
            uint256 shortMap = (1 << shortSize) - 1;
            
            uint256 left = (input >> shortSize) & longMap;
            uint256 right = (input & shortMap);
            
            for(uint256 i=0; i < round; i++) {
                uint256 roundKey = uint256(keccak256(abi.encode(key, i)));
                uint256 left_new = right;
                uint256 right_new;
                if(i % 2 == 0){
                    right_new = left ^ (longMap & uint256(keccak256(abi.encode(right, roundKey))));
                } else {
                    right_new = left ^ (shortMap & uint256(keccak256(abi.encode(right, roundKey))));
                }
                
                left = left_new;
                right = right_new;
            }

            if (round % 2 == 0) {
                return (left << shortSize) | right;
            } else {
                return (left << longSize) | right;
            }
        }
    }
}