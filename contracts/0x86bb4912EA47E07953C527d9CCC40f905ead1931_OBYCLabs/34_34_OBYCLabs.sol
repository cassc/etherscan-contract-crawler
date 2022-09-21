// SPDX-License-Identifier: Apache-2.0

/******************************************
 *  Amendeded by OBYC Labs Development    *
 *         Author: devAlex.eth            *
 ******************************************/

//     _     _      _     _      _     _      _     _   
//    (c).-.(c)    (c).-.(c)    (c).-.(c)    (c).-.(c)  
//     / ._. \      / ._. \      / ._. \      / ._. \   
//   __\( Y )/__  __\( Y )/__  __\( Y )/__  __\( Y )/__ 
//  (_.-/'-'\-._)(_.-/'-'\-._)(_.-/'-'\-._)(_.-/'-'\-._)
//     || O ||      || B ||      || Y ||      || C ||   
//   _.' `-' '._  _.' `-' '._  _.' `-' '._  _.' `-' '._ 
//  (.-./`-'\.-.)(.-./`-'\.-.)(.-./`-'\.-.)(.-./`-'\.-.)
//   `-'     `-'  `-'     `-'  `-'     `-'  `-'     `-' 


pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Drop.sol";

contract OBYCLabs is ERC1155Drop {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC1155Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}
}