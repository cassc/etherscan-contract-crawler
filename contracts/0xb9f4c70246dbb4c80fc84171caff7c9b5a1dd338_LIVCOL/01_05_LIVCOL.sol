// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Living Colors
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//    Living Colors by:                                                                                    //
//                                                                                                         //
//    |           (`  ,_|-.                                                                                //
//    |_(|L||`(|  _)(||||_|(|(|()                                                                          //
//                           _|                                                                            //
//    As an NFT owner, you do not have the right to copy, remix, and do other creative things with         //
//    the artwork linked to your NFT. Under this license, you can not incorporate your NFT                 //
//    artwork into other items or derivative work. This collection does NOT come with full commercial      //
//    use rights.                                                                                          //
//                                                                                                         //
//    If you would like full commercial use rights, please feel free to contact us to discuss at           //
//    at our twitter account @laurasantiagomx                                                              //
//                                                                                                         //
//    This NFT shouldn’t be used for illegal, racist, sexist, violent, homophobic stuff... (read           //
//    section 2.4 below). This license does NOT give you ownership of the underlying art,                  //
//    brands, or other intellectual property associated with project/publisher organization.               //
//                                                                                                         //
//    The General NFT License below is a legally binding agreement between you and us, so                  //
//    please review this document carefully before deciding whether to acquire a Living Colors NFT.        //
//                                                                                                         //
//    Living Colors NFT License Agreement                                                                  //
//    This General NFT License (the “License”) states the terms and conditions governing each              //
//    NFT that is offered, sold, or transferred to any person (which may be an individual or an            //
//    entity). If you sell, purchase, transfer, or acquire an NFT, you agree to be bound by the            //
//    terms of this License.                                                                               //
//                                                                                                         //
//    Definitions                                                                                          //
//    Art - means any art, design, drawing, fictional character, illustration, image, vector, video, 3D    //
//    asset, template asset, or other pictorial or graphic work associated with the NFT.                   //
//                                                                                                         //
//    Economic Activity - means any activity engaged in to obtain income, regardless of whether            //
//    or not the activity is aimed at making a profit.                                                     //
//                                                                                                         //
//    NFT - means the NFT created or issued on the project/publisher web site (“we” or “us”) or            //
//    minted directly via smart contract that is linked via metadata with specific Art, including but      //
//    not limited to a specific visual character.                                                          //
//                                                                                                         //
//    NFT - means an Ethereum-based non-fungible token complying with the ERC-721 standard,                //
//    ERC-1155 standard, or other similar non-fungible token standard. Is a unit of data stored on         //
//    a digital ledger, called a blockchain, that certifies a digital asset to be unique and therefore     //
//    not interchangeable.                                                                                 //
//                                                                                                         //
//    1. Intellectual Property Ownership                                                                   //
//    1.1 You own an NFT if your ownership of the NFT is cryptographically verified on the                 //
//    Ethereum blockchain. As an NFT owner, you own the non-fungible token — i.e., the digital             //
//    token recorded on the blockchain — but you do not own the Art associated with the token.             //
//                                                                                                         //
//    1.2 You acknowledge and agree that we own all legal right, title, and interest in and to all         //
//    elements of the Art. You acknowledge that the Art is protected by, as applicable, copyright,         //
//    patent, or trademark laws or other relevant intellectual property and proprietary rights.            //
//                                                                                                         //
//    1.3 You do not have a right to use any trademarks or logos owned by us.                              //
//                                                                                                         //
//    1.4 Living Colors NFT relinquises rights to reproduce the Art as any additional NFT format. If       //
//    found in violation, Minter may use all options under the law to recoup what it may consider          //
//    as lost revenue.                                                                                     //
//                                                                                                         //
//    1.5 You do not have the right to reproduce the Art as any additional NFT format (or creating         //
//    other collections on NFT marketplaces with our Art). If found in violation, we may use all           //
//    options under the law to recoup what we may consider in fines and lost revenue.                      //
//                                                                                                         //
//    2. Your License                                                                                      //
//    2.1 If you own an NFT (section 1.1), then we grant you a personal, non-sublicensable,                //
//    non-exclusive license to use the specific art associated with the NFT which you own, subject         //
//    to the restrictions described in Section 2.4 below.                                                  //
//                                                                                                         //
//    2.2 You may NOT use the Artwork for economic activity without previous consent and agreement         //
//    with Creator and/or Artist.                                                                          //
//                                                                                                         //
//    2.3 Transferring Your NFT. You may sell or transfer your NFT digitized token, and upon               //
//    such sale or transfer, we retain a 10% comission of the net profit of the sale and your entire       //
//    license to the Art and any associated rights will transfer to the new owner. The new owner           //
//    will enjoy the license and any associated rights described in this section, provided that the        //
//    new owner’s ownership of the NFT is cryptographically verifiable on the Ethereum                     //
//    blockchain.                                                                                          //
//                                                                                                         //
//    2.4 Restrictions. You agree to not use the Art in any way that is unlawful, pornographic,            //
//    defamatory, abusive, harassing, obscene, libelous, harmful to minors, racist, sexist,                //
//    homophobic, hate speech, gender discrimination, violence, depicting the use of drugs or              //
//    cigarettes or otherwise objectionable to any persons under the age of 18.                            //
//                                                                                                         //
//    You shall indemnify and defend Living Colors NFT against any claims, damages, proceedings,           //
//    loss or costs arising from such use. User shall not use the Living Colors NFT Licensed Materials     //
//    in any way that could be construed as being adverse or derogatory to the image of Living Colors      //
//    NFT or any of its subjects featured in the NFTs.                                                     //
//                                                                                                         //
//    3. Digital Collectible Not A Security                                                                //
//    THE DIGITAL COLLECTIBLE IS INTENDED FOR CONSUMER ENJOYMENT, USE AND CONSUMPTION ONLY. IT IS NOT      //
//    A “SECURITY,” AS DEFINED UNDER THE SECURITIES ACT OF 1933, AS AMENDED, THE SECURITIES EXCHANGE       //
//    ACT OF 1934, AS AMENDED, THE INVESTMENT COMPANY ACT OF 1940, AS AMENDED, OR UNDER THE SECURITIES     //
//    LAWS OF ANY U.S. STATE.                                                                              //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LIVCOL is ERC721Creator {
    constructor() ERC721Creator("Living Colors", "LIVCOL") {}
}