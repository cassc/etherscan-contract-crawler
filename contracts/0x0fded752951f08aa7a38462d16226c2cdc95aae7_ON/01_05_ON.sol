// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPTICNERD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//         *@%****************************************************************************************************#@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+     :---:.            :::::::.             ::::::::::::.         :::::::::::              .:---:.  :@%        //
//         *@+  .*@@@@@@@@+          %@@@@@@@@%=         -@@@@@@@@@@@@*        .@@@@@@@@@@%           :*@@@@@@@@+ :@%        //
//         *@+ -@@@+:..-%@@#         %@@+..:=%@@%         ....+@@%....          ...=@@@....          +@@@*-...:=- :@%        //
//         *@+ @@@=     .@@@-        %@@=    .@@@-            +@@%                 -@@@             =@@@-         :@%        //
//         *@+-@@@.      %@@*        %@@=    +@@@.            +@@%                 -@@@             #@@%          :@%        //
//         *@+=@@@       #@@*        %@@%***@@@%:             +@@%                 -@@@             %@@#          :@%        //
//         *@+:@@@:      @@@=        %@@%##**=:               +@@%                 -@@@             *@@@.         :@%        //
//         *@+ #@@%.    *@@%         %@@=                     +@@%                 -@@@             :@@@%:      . :@%        //
//         *@+  *@@@%##@@@#.         %@@=                     +@@%             .###%@@@###*          .#@@@@%#%@@+ :@%        //
//         *@+   .=**#*+=.           +*+:                     :++=             .+++++++++*+            .-+****+=. :@%        //
//         *@+            @@@@*    :@@#         +@@@@@@@@@@          @@@@@@@@%*:         -@@@@@@@@%+:             :@%        //
//         *@+            @@@@@=   :@@#         +@@%:::::::          @@@=::-#@@@:        -@@@::-=*@@@*            :@%        //
//         *@+            @@@%@@=  :@@#         +@@#                 @@@:    @@@=        -@@@     :@@@=           :@%        //
//         *@+            @@@ %@@- :@@#         +@@%======-          @@@=::=#@@#         -@@@      #@@%           :@%        //
//         *@+            @@@ .@@@::@@#         +@@@%%%%%%*          @@@@@@@@*.          -@@@      *@@%           :@%        //
//         *@+            @@@  :@@@=@@#         +@@#                 @@@- -@@@+          -@@@      %@@*           :@%        //
//         *@+            @@@   -@@@@@#         +@@#                 @@@:  .@@@+         -@@@    .#@@@.           :@%        //
//         *@+            @@@    -@@@@#         +@@@*******          @@@:   :@@@+        -@@@**#%@@@*             :@%        //
//         *@+            ***     =***+         -**********          ***:    -***:       :******+=:               :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                          =  :--            .                           .-     .                    :@%        //
//         *@+                  .=    ::                 .=+-.     ::     -           .-.   :=+-                  :@%        //
//         *@+                  -.. .:            .:=:.    .-      --   ::           +=.*-    .-                  :@%        //
//         *@+                                                                                                    :@%        //
//         *@+                                                                                                    :@%        //
//         *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%        //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ON is ERC721Creator {
    constructor() ERC721Creator("OPTICNERD", "ON") {}
}