// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Color Noise
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    k▄████▄kkk▒█████kkk██▓kkkkk▒█████kkk██▀███kkk███▄kkkk█kk▒█████kkk██▓kk██████k▓█████k    //
//    ▒██▀k▀█kk▒██▒kk██▒▓██▒kkkk▒██▒kk██▒▓██k▒k██▒k██k▀█kkk█k▒██▒kk██▒▓██▒▒██kkkk▒k▓█kkk▀k    //
//    ▒▓█kkkk▄k▒██░kk██▒▒██░kkkk▒██░kk██▒▓██k░▄█k▒▓██kk▀█k██▒▒██░kk██▒▒██▒░k▓██▄kkk▒███kkk    //
//    ▒▓▓▄k▄██▒▒██kkk██░▒██░kkkk▒██kkk██░▒██▀▀█▄kk▓██▒kk▐▌██▒▒██kkk██░░██░kk▒kkk██▒▒▓█kk▄k    //
//    ▒k▓███▀k░░k████▓▒░░██████▒░k████▓▒░░██▓k▒██▒▒██░kkk▓██░░k████▓▒░░██░▒██████▒▒░▒████▒    //
//    ░k░▒k▒kk░░k▒░▒░▒░k░k▒░▓kk░░k▒░▒░▒░k░k▒▓k░▒▓░░k▒░kkk▒k▒k░k▒░▒░▒░k░▓kk▒k▒▓▒k▒k░░░k▒░k░    //
//    kk░kk▒kkkkk░k▒k▒░k░k░k▒kk░kk░k▒k▒░kkk░▒k░k▒░░k░░kkk░k▒░kk░k▒k▒░kk▒k░░k░▒kk░k░k░k░kk░    //
//    ░kkkkkkkk░k░k░k▒kkkk░k░kkk░k░k░k▒kkkk░░kkk░kkkk░kkk░k░k░k░k░k▒kkk▒k░░kk░kk░kkkkk░kkk    //
//    ░k░kkkkkkkkkk░k░kkkkkk░kk░kkkk░k░kkkkk░kkkkkkkkkkkkkk░kkkkk░k░kkk░kkkkkkkk░kkkkk░kk░    //
//    ░kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract COLORNOISE is ERC721Creator {
    constructor() ERC721Creator("Color Noise", "COLORNOISE") {}
}