// SPDX-License-Identifier: MIT

import '../../NiftysERC721.sol';
import '../../utils/NiftysDefaultOperators.sol';

pragma solidity ^0.8.0;

/**
  _______                _         
 |__   __|              | |        
    | |_      _____  ___| |_ _   _ 
    | \ \ /\ / / _ \/ _ \ __| | | |
    | |\ V  V /  __/  __/ |_| |_| |
    |_| \_/\_/ \___|\___|\__|\__, |
                              __/ |
                             |___/ 
*/

contract Tweety is NiftysERC721, NiftysDefaultOperators {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address recipient,
        uint24 value,
        address admin,
        address operator,
        address relay
    ) NiftysERC721(name, symbol, baseURI, baseURI, recipient, value, admin) {
        _setupDefaultOperator(operator);
        grantRole(MINTER, relay);
    }

    function globalRevokeDefaultOperator() public isAdmin {
        _globalRevokeDefaultOperator();
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {
        return (isDefaultOperatorFor(owner, operator) || super.isApprovedForAll(owner, operator));
    }
}