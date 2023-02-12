// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aramint in Manifold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                           -!+++++++++++++++++++++++++++++++++++++++++++++;.                                //
//                            ;l9qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqql~                               //
//                              ;IGqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqk|'                             //
//                               .!2qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq4r'                           //
//                                 -?Pqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqe_                          //
//                                   ';;;;;;;;;;;;;;;;;;;;;;;;;;;;!f9qqqqqqqqqqqkT_                           //
//                                                              .!yGqqqqqqqqqqk7~                             //
//                                        ',,,,,,,,,,,-.      .!yGqqqqqqqqqqkc~                               //
//                                        _TkqqqqqqqqqGC".  .!yGqqqqqqqqqqPL~                                 //
//                                          _TkqqqqqqqqqGC!!yGqqqqqqqqqqPL~                                   //
//                                            _7kqqqqqqqqqqqqqqqqqqqqqP*~                                     //
//                                              _ckqqqqqqqqqqqqPaaaao?~                                       //
//                                                _Lkqqqqqqqqqq4r-...                                         //
//                                                  _LPqqqqqqqqqGe!.                                          //
//                                                    ~LSPPPPPPPPP5f^.                                        //
//                                                      .```````````.                                         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract arm is ERC721Creator {
    constructor() ERC721Creator("aramint in Manifold", "arm") {}
}