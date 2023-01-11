// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: loaf'23
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//       ____                                    ?~~bL     //
//      [email protected]~ b                                    |  `U,    //
//     ]@[  |                                   ]'  [email protected]'    //
//     [email protected]~' `|, .__     _----L___----, __, .  _t'   `@j    //
//    `@L_,   "-~ `--"~-a,           `C.  ~""O_    ._`@    //
//     [email protected]~'   ]P       ]@[            `Y=,   `H+z_  `[email protected]    //
//     `@L  [email protected]        [email protected]               Ya     `[email protected],_a'    //
//      `[email protected]@a'       )@[               `VL      `[email protected]@'     //
//        aa~'   ],  [email protected]'croissantisbread qqL  ), ./~      //
//        @@_  _z~  [email protected][                 [email protected]  .L_d'        //
//         "[email protected]@@'  ]@@@'        __      )@[email protected]@-"         //
//           `[email protected]@@@L        )@@z     ]@@=%-"            //
//             "[email protected]@@@@bz_    [email protected]@@@[email protected]                //
//                 "[email protected]@@@@@@@@@@@@@@@@@~"                 //
//                    `[email protected][email protected]@~~~~~'                    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract loaf is ERC721Creator {
    constructor() ERC721Creator("loaf'23", "loaf") {}
}