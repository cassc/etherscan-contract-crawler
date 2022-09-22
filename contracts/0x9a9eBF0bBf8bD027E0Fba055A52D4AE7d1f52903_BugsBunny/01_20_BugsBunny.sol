// SPDX-License-Identifier: MIT

import '../../NiftysERC721A.sol';
import '../../utils/NiftysDefaultOperators.sol';

pragma solidity ^0.8.0;

/**
  ____                    ____                          
 |  _ \                  |  _ \                         
 | |_) |_   _  __ _ ___  | |_) |_   _ _ __  _ __  _   _ 
 |  _ <| | | |/ _` / __| |  _ <| | | | '_ \| '_ \| | | |
 | |_) | |_| | (_| \__ \ | |_) | |_| | | | | | | | |_| |
 |____/ \__,_|\__, |___/ |____/ \__,_|_| |_|_| |_|\__, |
               __/ |                               __/ |
              |___/                               |___/ 
*/

contract BugsBunny is NiftysERC721A, NiftysDefaultOperators {
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