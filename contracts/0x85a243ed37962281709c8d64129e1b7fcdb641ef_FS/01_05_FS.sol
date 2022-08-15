// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Facu Serif
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                ,aemmm,,                                                                   //
//             s#%7|    ~`"@m,                               ,e######m,                      //
//           ##`             7%#m,                       ,e#M^        '"@m                   //
//          #b                   |7%@#mmw,,,,,,,,,se###MT" ,emmm,        |@Q                 //
//         @M                           `'^|```|^``      ####%[email protected]##[email protected]#M"7%@m     //
//         #b        !#w                                @##b       ]#`         @#      \#    //
//         @b          "%@mg                            ###p       @#          @Q      ]#    //
//          @p             ^7%#Mm,                    ,#####m,      @#w         @#g  ,##^    //
//           %#                  '"75%W###########MW%777|77%@###M"[email protected]#777777777``      //
//            '[email protected]                                                      ;#C                  //
//               '"@#w                                              ,s#M"                    //
//                   |"%#m,                                    ,,##M^`                       //
//                        '75W#Mm,,                     ,,e##M87`                            //
//                               ~"775%WWM#######MWW%577|,                                   //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract FS is ERC721Creator {
    constructor() ERC721Creator("Facu Serif", "FS") {}
}