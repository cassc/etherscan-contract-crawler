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

import "../interfaces/ILPXMetadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LPXMetadata is ILPXMetadata, Ownable {

    string private baseURI;
    using Strings for uint256;

    constructor() {}

    /// Set the base URI for metadata
    /// @param _baseURI the URI for the metadata store
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // Returns custom render logic for our metadata
    // @param _tokenId The token to render metadata for
    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json"));
    }    
}