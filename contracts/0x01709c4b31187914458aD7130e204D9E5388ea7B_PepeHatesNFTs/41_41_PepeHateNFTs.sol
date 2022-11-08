// SPDX-License-Identifier: Apache-2.0

/******************************************
 *        Amendeded by AAA Devs           *
 *         Author: C1Apepe.ᴱᵀᴴ            *
 ******************************************/

// .______    _______ .______    _______  __    __       ___   .___________. _______     _______..__   __.  _______ .___________.    _______.
// |   _  \  |   ____||   _  \  |   ____||  |  |  |     /   \  |           ||   ____|   /       ||  \ |  | |   ____||           |   /       |
// |  |_)  | |  |__   |  |_)  | |  |__   |  |__|  |    /  ^  \ `---|  |----`|  |__     |   (----`|   \|  | |  |__   `---|  |----`  |   (----`
// |   ___/  |   __|  |   ___/  |   __|  |   __   |   /  /_\  \    |  |     |   __|     \   \    |  . `  | |   __|      |  |        \   \    
// |  |      |  |____ |  |      |  |____ |  |  |  |  /  _____  \   |  |     |  |____.----)   |   |  |\   | |  |         |  |    .----)   |   
 //| _|      |_______|| _|      |_______||__|  |__| /__/     \__\  |__|     |_______|_______/    |__| \__| |__|         |__|    |_______/    
 //                                                                                                                                                                                                                                                                                   \

pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract PepeHatesNFTs is ERC721Drop {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}
}