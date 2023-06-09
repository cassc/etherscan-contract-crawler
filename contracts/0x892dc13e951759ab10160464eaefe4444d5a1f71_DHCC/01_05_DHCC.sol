// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DolceHeights: Capsules
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                D   O   L   C   E   H   E   I   G   H   T   S                  //
//                                                                               //
//     ▄████▄   ▄▄▄       ██▓███    ██████  █    ██  ██▓    ▓█████   ██████      //
//    ▒██▀ ▀█  ▒████▄    ▓██░  ██▒▒██    ▒  ██  ▓██▒▓██▒    ▓█   ▀ ▒██    ▒      //
//    ▒▓█    ▄ ▒██  ▀█▄  ▓██░ ██▓▒░ ▓██▄   ▓██  ▒██░▒██░    ▒███   ░ ▓██▄        //
//    ▒▓▓▄ ▄██▒░██▄▄▄▄██ ▒██▄█▓▒ ▒  ▒   ██▒▓▓█  ░██░▒██░    ▒▓█  ▄   ▒   ██▒     //
//    ▒ ▓███▀ ░ ▓█   ▓██▒▒██▒ ░  ░▒██████▒▒▒▒█████▓ ░██████▒░▒████▒▒██████▒▒     //
//    ░ ░▒ ▒  ░ ▒▒   ▓▒█░▒▓▒░ ░  ░▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒ ░ ▒░▓  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░     //
//      ░  ▒     ▒   ▒▒ ░░▒ ░     ░ ░▒  ░ ░░░▒░ ░ ░ ░ ░ ▒  ░ ░ ░  ░░ ░▒  ░ ░     //
//    ░          ░   ▒   ░░       ░  ░  ░   ░░░ ░ ░   ░ ░      ░   ░  ░  ░       //
//    ░ ░            ░  ░               ░     ░         ░  ░   ░  ░      ░       //
//    ░                                                                          //
//                                                                               //
//    BY: DOLCEHEIGHTS.NFT                                                       //
//                                                                               //
//    These Digital Collectibles set forth the terms and conditions              //
//    applicable to Digital Collectibles made available by DolceHeights.         //
//    Applicable, by any means, whether through one or more websites,            //
//    mobile applications or other platforms operated by or on behalf of         //
//    DolceHeights Capsules or by “airdrop” or other delivery mechanisms.        //
//    By acquiring, accepting, using, or transferring any                        //
//    non-fungible blockchain-based digital token (“NFT”) made available         //
//    by DolceHeights.                                                           //
//                                                                               //
//    *Digital Collectibles:                                                     //
//    Each NFT made available by DolceHeights Capsules is associated             //
//    with certain digital works of authorship or other content,                 //
//    whether or not copyrighted or copyrightable, and regardless of             //
//    the format in which any of the foregoing is made available                 //
//    (“Related Content”). Related Content is separate from the                  //
//    associated NFT and is not sold or otherwise transferred to you             //
//    but is instead licensed to you as set forth in these Terms.                //
//    A “Digital Collectible” consists of the applicable NFT and the             //
//    license rights granted pursuant to these Terms with respect to             //
//    the Related Content. All licenses under these Terms are granted            //
//    to the person with direct control over the NFT associated with             //
//    the applicable Digital Collectible (the “Holder”) and are, therefore,      //
//    granted to you only for as long as you are the Holder of that NFT.         //
//                                                                               //
//    *License Agreement:                                                        //
//    Subject to your compliance with these Terms, You understand that           //
//    DolceHeights and their respective Affiliates will continue to              //
//    further, modify and develop any Related Content and may                    //
//    create works of authorship similar or identical to Modified Works          //
//    created by you. On behalf of yourself and your heirs, successors,          //
//    and assigns, you irrevocably and perpetually covenant and agree not        //
//    to file or assert before any court or other government tribunal or         //
//    authority, any claim, counterclaim, demand, action, suit, or other         //
//    proceeding alleging or asserting direct or indirect infringement or        //
//    misappropriation of any copyright or other intellectual property           //
//    right that you may have in any Modified Work against DolceHeights,         //
//    any Third Party Rights Owner, any Affiliate of DolceHeights or any         //
//    of their respective shareholders.                                          //
//                                                                               //
//    *Benefits:                                                                 //
//    DolceHeights may make additional content, products, services, or           //
//    other benefits available to the Holder of the applicable NFT.              //
//    DolceHeights Capsules or any third party is not obligated to               //
//    inform you or provide you with any Additional Benefits, and therefore,     //
//    it should not be expected upon acquiring an NFT.                           //
//    It is your responsibility to stay informed about the availability          //
//    of any Additional Benefits and to take the necessary steps to              //
//    apply for or collect them. The terms and conditions governing              //
//    any Additional Benefit will be provided with the relevant                  //
//    information or materials. Any digital works of authorship                  //
//    provided as an Additional Benefit by DolceHeights Capsules will            //
//    be licensed on the same terms as the Related Content. Physical items       //
//    provided as Additional Benefits are not part of the Related Content,       //
//    and you will not have any license rights under any                         //
//    intellectual property rights in or to such physical items,                 //
//    unless otherwise specified in separate terms and conditions.               //
//    DolceHeights Capsules reserves the right to suspend or terminate           //
//    any Additional Benefit at any time, for any reason, including              //
//    but not limited to the transfer of the applicable NFT or the               //
//    termination of license rights.                                             //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract DHCC is ERC1155Creator {
    constructor() ERC1155Creator("DolceHeights: Capsules", "DHCC") {}
}