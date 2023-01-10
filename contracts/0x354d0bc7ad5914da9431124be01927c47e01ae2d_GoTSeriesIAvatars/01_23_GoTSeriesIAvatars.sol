// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../NiftysERC721A.sol';
import '../../utils/NiftysDefaultOperators.sol';

/**
   _____    _______                     _                 
  / ____|  |__   __|     /\            | |                
 | |  __  ___ | |       /  \__   ____ _| |_ __ _ _ __ ___ 
 | | |_ |/ _ \| |      / /\ \ \ / / _` | __/ _` | '__/ __|
 | |__| | (_) | |     / ____ \ V / (_| | || (_| | |  \__ \
  \_____|\___/|_|    /_/    \_\_/ \__,_|\__\__,_|_|  |___/
                                                                                     
*/

contract GoTSeriesIAvatars is NiftysERC721A, NiftysDefaultOperators {
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

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool)
    {
        return (isDefaultOperatorFor(owner, operator) || super.isApprovedForAll(owner, operator));
    }
}