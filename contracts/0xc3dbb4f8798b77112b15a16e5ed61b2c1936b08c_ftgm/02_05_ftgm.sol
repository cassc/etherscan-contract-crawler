// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: freedom to gm
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//           FFFF  FFFF  rRRr rRRr      eEEe eEEEe  eEEe eEEEe     DDDD  DDDD        oOo  oOo      m mmm      m MMMM                  //
//           FFFF  FFFF  RRRR rRRRr     EEEE eEEEe  EEEE eEEEe     DDDDD DDDDD      OOOo oOOOo     M mMMm     M MMMM                  //
//           FFFF  fff   RRRR rRRRRr    EEEE  eEe   EEEE  eEe      DDDDD dDDDDD    oOOOo  oOOOo    mm mMMm   mm MMMM                  //
//           FFFF        rRRr  rRRRr    EEEE        EEEE           DDDDD  dDDDD    oOOo   oOOOo    MM mMMm   MM MMMM                  //
//           FFFF        RRRR  rRRRr    EEEE        EEEE           DDDDD   DDDD    oOOo    oOOo    MM  WMM   MM MMMM                  //
//           FFFF        RRRR  rRRRr    EEEE        EEEE           DDDDD   DDDDD   oOOo    oOOo    MMm mMMm  MM MMMM                  //
//           FFFF  FFF   rRRr rRRRR     EEEE eEEe   EEEE eEEe      DDDDD   DDDDD   oOOo    oOOo    MMm mMMm mMM MMMM                  //
//           FFFF fFFF   RRRR RRRR      EEEE eEEe   EEEE eEEe      DDDDD   DDDDD   oOOo    oOOo    MMM mMMm mMM MMMM                  //
//           FFFF  fFf   RRRr RRRRR     EEEE  eEe   EEEE  eEe      DDDDD   DDDDD   oOOo    oOOo    MMM  MMm mMM MMMM                  //
//           FFFF        RRRR  rRRRr    EEEE        EEEE           DDDDD   DDDDD   oOOo    oOOo    MMM  mMm MMm MMMM                  //
//           FFFF        RRRR   RRRr    EEEE        EEEE           DDDDD   DDDDD   oOOo    oOOo    MMMm mMm MMm MMMM                  //
//           FFFF        rRRr   RRRr    EEEE        EEEE           DDDDD  dDDDD    oOOo   oOOOo    MMMm  mm MM  MMMM                  //
//           FFFF        RRRR   RRRr    EEEE eeee   EEEE eeee      DDDDD dDDDDD    oOOOo  oOOOo    MMMM  mMmMm  MMMM                  //
//           FFFF        RRRR   RRRr    EEEE eEEEe  EEEE eEEEe     DDDDD DDDDD      oOOo ooOOo     MMMM  mMMMm  MMMM                  //
//           FFFF        rRRr   RRRr    EEEE eEEEe  EEEE eEEEe     DDDD DDDDD        oOo  oOo      MMMM  mMMm   MMMM                  //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                 TT tt TT  o00o                                                     //
//                                                                    TT    o0oo0o                                                    //
//                                                                    tt    o0  0o                                                    //
//                                                                    TT    o0  0o                                                    //
//                                                                    TT    o0oo0o                                                    //
//                                                                    tt     o00o                                                     //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                ggggggggg     ggggg         mmmmm      mmmmmmmmm      mmmmmmmmmm                    //
//                                             ggGGGGGGGGGGGgg ggGGGgg       mMMMMMm  mMMMMMMMMMMmm   mmMMMMMMMMmmmm                  //
//                                           ggGGGGGGggggggGGggGGGGGGgg      mMMMMMMmmMMMMMMMMMMMMMmmmMMMMMMMMMMMMMMm                 //
//                                         ggGGGGGGggg   ggggGGGGGGGGGg      mMMMMMMMMMmm  mmMMMMMMMMMMmmm  mmMMMMMMMm                //
//                                        ggGGGGGGgg        ggGGGGGGGGg      mMMMMMMMmm      mMMMMMMMMm       mMMMMMMm                //
//                                       ggGGGGGGgg          ggGGGGGGGg      mMMMMMMmm        mMMMMMMm        mMMMMMMm                //
//                                       ggGGGGGgg            ggGGGGGGg      mMMMMMMm         mMMMMMMm        mMMMMMMm                //
//                                       ggGGGGGgg            ggGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                       ggGGGGGgg            ggGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                        ggGGGGGgg          ggGGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                        ggGGGGGGgg        ggGGGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                         ggGGGGGGggg   gggGGGGGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                          ggGGGGGGGGgggggGGGggGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMMm                //
//                                            ggGGGGGGGGGGgg  ggGGGGGGg      mMMMMMMm         mMMMMMm         mMMMMMWm                //
//                                                ggggggg     ggGGGGGGg       mmmmmm           mmmmm            mmmmm                 //
//                                          gggg             ggGGGGGGGg                                                               //
//                                         ggGGGgg           ggGGGGGGgg                                                               //
//                                         ggGGGGGgggggggggggGGGGGGgg                                                                 //
//                                          ggGGGGGGGGGGGGGGGGGGGgg                                                                   //
//                                             ggGGGGGGGGGGGGGGgg                                                                     //
//                                                   ggggggg                                                                          //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ftgm is ERC721Creator {
    constructor() ERC721Creator("freedom to gm", "ftgm") {}
}