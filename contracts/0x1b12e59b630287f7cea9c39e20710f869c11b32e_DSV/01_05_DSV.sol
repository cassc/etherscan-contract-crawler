// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deslav
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                            .:--##-::                                             //
//            [email protected]@@@@@@@@@@@@@%#*+-        .=#@@@@@@@@@@@@#=.   [email protected]@@@@@@@@#    *@@@@@@@@@*           //
//            [email protected]@@@@@@@@@@@@@@@@@@@+     [email protected]@@@@@@@@@@@@@@@@@=  :@@@@@@@@@@    %@@@@@@@@@-           //
//            [email protected]@@@@@@@@@@@@@@@@@@@@*   [email protected]@@@@@@@@@@@@@@@@@@@:  @@@@@@@@@@:   @@@@@@@@@@.           //
//            [email protected]@@@@@@@@+:-%@@@@@@@@@   *@@@@@@@@[email protected]@@@@@@@+  *@@@@@@@@@=  :@@@@@@@@@%            //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@:  %@@@@@@@@[email protected]@@@@@@@*  [email protected]@@@@@@@@*  [email protected]@@@@@@@@+            //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@:  #@@@@@@@@#++:********=   @@@@@@@@@%  [email protected]@@@@@@@@-            //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@:  [email protected]@@@@@@@@@#:            *@@@@@@@@@  #@@@@@@@@@             //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@-   %@@@@@@@@@@@@+:         [email protected]@@@@@@@@: %@@@@@@@@%             //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@-   .*@@@@@@@@@@@@@@+.       @@@@@@@@@= @@@@@@@@@+             //
//    ++++++++#@@@@@@@@@#++#@@@@@@@@@*+++++*#%@@@@@@@@@@@@@%*[email protected]@@@@@@@@%*@@@@@@@@@*+++++++++    //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@-        .+%@@@@@@@@@@@@-    [email protected]@@@@@@@%[email protected]@@@@@@@@              //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@-           :#@@@@@@@@@@@    [email protected]@@@@@@@@[email protected]@@@@@@@%              //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@-  [email protected]@@@@@@@++*[email protected]@@@@@@@@-    %@@@@@@@@%@@@@@@@@+              //
//            [email protected]@@@@@@@@-  [email protected]@@@@@@@@:  [email protected]@@@@@@@+++ @@@@@@@@@=    [email protected]@@@@@@@@@@@@@@@@:              //
//            [email protected]@@@@@@@@-  *@@@@@@@@@:  [email protected]@@@@@@@+++ %@@@@@@@@=    :@@@@@@@@@@@@@@@@@               //
//            [email protected]@@@@@@@@*=*@@@@@@@@@@.  :@@@@@@@@#++:@@@@@@@@@:     @@@@@@@@@@@@@@@@#               //
//            [email protected]@@@@@@@@@@@@@@@@@@@@%    #@@@@@@@@@@@@@@@@@@@%      *@@@@@@@@@@@@@@@=               //
//            [email protected]@@@@@@@@@@@@@@@@@@@#.     [email protected]@@@@@@@@@@@@@@@@*.      [email protected]@@@@@@@@@@@@@@:               //
//            -################*+=.         -*#@@@@@@@@@%*=.        .###############                //
//                                               .**..                                              //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                ++                                                //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract DSV is ERC721Creator {
    constructor() ERC721Creator("Deslav", "DSV") {}
}