// SPDX-License-Identifier: MIT

import '../../NiftysERC721A.sol';
import '../../utils/NiftysDefaultOperators.sol';

pragma solidity ^0.8.0;

/**
   _____       _                _            
  / ____|     | |              | |           
 | (___  _   _| |_   _____  ___| |_ ___ _ __ 
  \___ \| | | | \ \ / / _ \/ __| __/ _ \ '__|
  ____) | |_| | |\ V /  __/\__ \ ||  __/ |   
 |_____/ \__, |_| \_/ \___||___/\__\___|_|   
          __/ |                              
         |___/                               
        
*/

contract Sylvester is NiftysERC721A, NiftysDefaultOperators {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address recipient,
        uint24 value,
        address admin,
        address operator,
        address relay
    ) NiftysERC721A(name, symbol, baseURI, baseURI, recipient, value, admin) {
        _setupDefaultOperator(operator);
        grantRole(MINTER, relay);
    }

    function globalRevokeDefaultOperator() public isAdmin {
        _globalRevokeDefaultOperator();
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721A) returns (bool) {
        return (isDefaultOperatorFor(owner, operator) || super.isApprovedForAll(owner, operator));
    }
}