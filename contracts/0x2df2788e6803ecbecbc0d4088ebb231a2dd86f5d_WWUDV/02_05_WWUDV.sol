// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WW-UNDIVIDED
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@*     %@@@@@@#   #@@@@@@@     *@@@%     *@@@@@@%    @@@@@@@*     @@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@.     %@@@@@%    [email protected]@@@@@:     #@@@=     [email protected]@@@@@:   :@@@@@@+     [email protected]@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@%     [email protected]@@@@@.    #@@@@@+     [email protected]@@@.     %@@@@@=    [email protected]@@@@%     :@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@+     [email protected]@@@@=     @@@@@%     [email protected]@@@%     [email protected]@@@@#     #@@@@@.     %@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@-     #@@@@#     :@@@@@:     %@@@@*     [email protected]@@@@      @@@@@=     *@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@      @@@@@      [email protected]@@@=     *@@@@@-     %@@@@:     :@@@@#     [email protected]@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@%     [email protected]@@@:      %@@@#     [email protected]@@@@@     [email protected]@@@+      [email protected]@@@.    [email protected]@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@+     *@@@+       @@@@.    [email protected]@@@@@#     [email protected]@@#       #@@@-     %@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@:     @@@%   :   [email protected]@@=     %@@@@@@+     *@@@.  :    @@@*     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@     :@@@.  :*   *@@#     *@@@@@@@-     @@@-   %   :@@@.    :@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@#     [email protected]@-   %-   @@@     [email protected]@@@@@@@     :@@*   **   [email protected]@-    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@=     %@+   #@.  [email protected]@-    [email protected]@@@@@@@#     [email protected]%   [email protected]   %@+     %@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@.    :@%   [email protected]@   [email protected]*     #@@@@@@@@+     %@.  :@@.  [email protected]%     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@     [email protected]  :@@*   *%     [email protected]@@@@@@@@:    :@=   %@%   [email protected]:    :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@*     #-   %@@-   %:    [email protected]@@@@@@@@@     +#   *@@*   *+    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@=     *   #@@@.  .+     @@@@@@@@@@*     #   [email protected]@@=   #     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@.    .   [email protected]@@%   .     #@@@@@@@@@@=     :  [email protected]@@@.   .    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@        [email protected]@@@+        [email protected]@@@@@@@@@@.        %@@@@        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@*        %@@@@-       :@@@@@@@@@@@%        *@@@@*        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@-       #@@@@@        %@@@@@@@@@@@*       [email protected]@@@@-       *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@       [email protected]@@@@%       *@@@@@@@@@@@@-      [email protected]@@@@@.      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@[email protected]@@@@@%======*@@@@@@@@@@@@@*======%@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Woszczyna & Wiesnowski @@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ aka. TwoBrooklyners @@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ U N D I V I D E D @@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ WWUDV @@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WWUDV is ERC721Creator {
    constructor() ERC721Creator("WW-UNDIVIDED", "WWUDV") {}
}