// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GNOS15 - Master Boot Record
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                 .:....    .:-.      ..:..     .....:         ::....     .:--..    .:.....                   //
//               +#:     .-   :#@-       :     -#:  .  +*     *@-      :.   [email protected]@    [email protected]+      .:                 //
//              %%       .=   : *@=      :    *@.   :   #%.  [email protected]#       ::    @%   [email protected]@       .-                 //
//             *@=     ..     :  [email protected]+     :   [email protected]*    -   [email protected]#  .#@*-. ..       @%    [email protected]#=.  .                    //
//             @@.  ..        :   [email protected]+    : ..*@+...-#:..:@@... .=#%@%*-      @%     .-*%@%*=.                  //
//             %@: .   ....:  :    [email protected]*   :   [email protected]+    :   :@%         :=%@+    @%       .  .-#@*                 //
//             [email protected]*         +  :     :@#  :   [email protected]%    :   [email protected]=  :         @@:   @%   :         #@=                //
//              [email protected]=       ::  :      .%% :    :%=   .  [email protected]+   =        [email protected]%    @%   -         %@:                //
//               .==:..... . .-:.     .#*:      --....:=.    . ......-*-   .:%%.. . ......-+=.                 //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                            Master Boot Record                                               //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMBR is ERC721Creator {
    constructor() ERC721Creator("GNOS15 - Master Boot Record", "GMBR") {}
}