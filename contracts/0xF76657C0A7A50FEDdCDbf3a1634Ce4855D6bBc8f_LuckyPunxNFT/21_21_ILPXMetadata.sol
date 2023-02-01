// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/*

77                           77                                                                             
77                           77                                                                             
77                           77                                                                             
77  77       77   ,adPPYba,  77   ,d7  7b       d7      7b,dPPYba,   77       77  7b,dPPYba,   7b,     ,d7  
77  77       77  a7"     ""  77 ,a7"   `7b     d7'      77P'    "7a  77       77  77P'   `"7a   `Y7, ,7P'   
77  77       77  7b          7777[      `7b   d7'       77       d7  77       77  77       77     )777(     
77  "7a,   ,a77  "7a,   ,aa  77`"Yba,    `7b,d7'        77b,   ,a7"  "7a,   ,a77  77       77   ,d7" "7b,   
77   `"YbbdP'Y7   `"Ybbd7"'  77   `Y7a     Y77'         77`YbbdP"'    `"YbbdP'Y7  77       77  7P'     `Y7  
                                           d7'          77                                                  
                                          d7'           77     
*/

interface ILPXMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}