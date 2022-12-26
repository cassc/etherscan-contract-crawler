// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eyes of Lamia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//       :-::      :-%%=:         [email protected]@@-.   .-%%=:   .--=*=.   .-#%=         .     . -+        .=#*#*.       :%@+:       . . :%+:      .    .:#@@+:..:-:::=:.    :%#=..    //
//       %@*        :%.            =%@=    .+*.       =%@+     =*.       ..         *+           #@#        .%:            .*@*.    .=.      [email protected]@.      .*+=.    =*.       //
//       :@@+      .%-              .#@#. -#-          :#@#. :#-         *%#.      =*            .%@*       #=              .*@%- :*=        [email protected]@        .*@%: -#-         //
//        [email protected]@-     #=                 *@%*+              [email protected]%*+            #@%     -*.             :%@+     **                 =%@**.         [email protected]@.         [email protected]@**           //
//         [email protected]@:   **                   *@@+               [email protected]@*.           .%+=   :%.               [email protected]@-   =*                   [email protected]@#.         [email protected]@           [email protected]@*           //
//          =%%. =#                  .*=:#@%:           .*+:*@#.           :%@+  #:                 [email protected]@- -%.                 .*+.*@%-        [email protected]@         .*+.#@%:         //
//           =%%-%.                 =*.   [email protected]@-         =#:   [email protected]@+           :@@=#=                   *@%-%.                 :#:   =%@+       [email protected]@.       =#.   [email protected]@=        //
//            :*%:                :#=      [email protected]@+       #+      -%%*           [email protected]@*                     *@@-                :*+.     :%@#:     [email protected]@      :#+      -%@*.      //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EOL is ERC721Creator {
    constructor() ERC721Creator("Eyes of Lamia", "EOL") {}
}