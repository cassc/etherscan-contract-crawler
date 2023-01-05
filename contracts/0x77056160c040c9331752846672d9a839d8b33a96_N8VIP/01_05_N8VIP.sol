// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: N8_LIFETIME_VIP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                           .-+*#%@@%#*+-.         //
//                                                                       -+%@#+=:.    .:=*%%=       //
//                                                 .:.               .+%@*-.    :-=++=:    :#@:     //
//                                               -%%*@*            =%@+:    -*%@@@@@@@@%:    *@:    //
//                                             .#@-  [email protected]=         [email protected]#-    -#@@@@@@@@@@@@@@-    @#    //
//                                            [email protected]#     @#       [email protected]#:    =%@@@@@@@@@@@@@@@@@    %@    //
//                                           [email protected]*      %@     :%%-    -%@@@@@@@@@%*-#@@@@@@-   %@    //
//                                          [email protected]+       #@    [email protected]*    .#@@@@@@@@#=.   @@@@@@@:   @*    //
//                                         [email protected]=        #@   #@:    [email protected]@@@@@@@+.     [email protected]@@@@@@   [email protected]    //
//                                        [email protected]+         #@  %@.    #@@@@@@@+       :@@@@@@@=   @%     //
//                                       [email protected]+   -*=    %@.%%.   .%@@@@@@%:       [email protected]@@@@@@#   *@:     //
//                                      :@#   [email protected]@@@:  #@@%.   .%@@@@@@*        .%@@@@@@%.  [email protected]+      //
//                                     [email protected]#   [email protected]@@@@%  :*=    :@@@@@@@+ .--    [email protected]@@@@@@@.  :@#       //
//                                    .%%   :@@@@@@@.       :@@@@@@@= [email protected]@@@[email protected]@@@@@@%.  :@#        //
//                                    #@.  [email protected]@@@@@@@       [email protected]@@@@@@= :@@@@@@@@@@@@@@%.  :@#         //
//                                   [email protected]   %@@@@@@@*      [email protected]@@@@@@+  [email protected]@@@@@@@@@@@@#   :@#          //
//                                  [email protected]+   *@@@@@@@@.      #@@@@@@*   :@@@@@@@@@@@@=   [email protected]*           //
//                                 :@#   [email protected]@@@@@@@*      *@@@@@@%     [email protected]@@@@@@@@+    [email protected]+            //
//                                 %%   :@@@@@@@@@.     [email protected]@@@@@@.      .+%@@%*-     *@*             //
//                                #@.   %@@@@@@@@*     :@@@@@@@-                    .=#@*:          //
//                               [email protected]   [email protected]@@@@@@@@:     %@@@@@@%*%@@@@@%*=.          =   [email protected]%-        //
//                              :@*   [email protected]@@@@@@@@@     *@@@@@@@@@@@@@@@@@@@%-       #@*    [email protected]#.      //
//                     :+*#%%%%%@*    *@@@@@@@@@*    [email protected]@@@@@@@@@@@@@@@@@@@@@* -++*%@@@#*+=:.%%      //
//                   [email protected]#=:  .        [email protected]@@@@@@@@@-    @@@@@@@@@@@@@@%+=*@@@@@@: -%@@@@@@@#-  [email protected]*     //
//                  #@-    [email protected]=       %@@@@@@@@@@.   #@@@@@@@@@@@@@+  .%@@@@@@.   @@@@@@@     @#     //
//                 [email protected]:[email protected]@@+-::. [email protected]@@@@@@@@@%   [email protected]@@@@@@#@@@@@@+*#@@@@@@@%.  [email protected]%+-+%@:   :@+     //
//                 #@ .*@@@@@@@@@*:[email protected]@@@@@@@@@@*  [email protected]@@@@@@% @@@@@@@@@@@@@@@@@@*:.      ..  .%%      //
//                 *@   [email protected]@@@@@@.  #@@@@@@@@@@@-  *@@@@@@@-:*@@@@@@@@@@@@@@@@@@@@+:       [email protected]#.      //
//                 #@   [email protected]@%*%@@: [email protected]@@@@@@@@@@@. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=    .#@:       //
//            :+#%%#-   :-     -: %@@@@@@@@@@@@  @@@@@@@@@@@@@@@@%*=-:..  ..-+#@@@@@@%:    %@.      //
//         [email protected]%=:                [email protected]@@@@@@@@@@@% [email protected]@@@@@@@@@@@@#-               .%@@@@@@-   [email protected]+      //
//       .*@*:         .        .@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@#. .-+#%@@@@@%+     [email protected]@@@@@@    @%      //
//      [email protected]#.    .-*#@@@@@@%+.   #@@@@@@[email protected]@@@@@*#@@@@@@@@@@@@=*%@@@@@@@@@@@@%     @@@@@@@-   %@      //
//     [email protected]=    -#@@@@@@@@@@@@@- [email protected]@@@@@= @@@@@@%@@@@@@@@@@@@@@@@@@@*==#@@@@@@.   [email protected]@@@@@@-   %@      //
//    [email protected]+    #@@@@@@@@@@@@@@@%[email protected]@@@@@# [email protected]@@@@@@@@@@@@@@@@@@@@@@@@.  [email protected]@@@@@*   [email protected]@@@@@@@    @#      //
//    #@.   [email protected]@@@@@%=. :%@@@@%@@@@@@%  [email protected]@@@@@@@@@@@@%#@@@@@@@@@@    .=**+:  =%@@@@@@@@:   [email protected]=      //
//    %@    *@@@@@@.     [email protected]@@@@@@:  :@@@@@@@@@@@@@- #@@@@@@@@@*       .-*@@@@@@@@@@:    %@       //
//    *@.   [email protected]@@@@@=       [email protected]@@@@@@-   :@@@@@@@@@@@@#   [email protected]@@@@@@@@@%#*##@@@@@@@@@@@@+     #@:       //
//    :@*    #@@@@@@%*+=+#@@@@@@@@-    [email protected]@@@@@@@@@@@.     =%@@@@@@@@@@@@@@@@@@@@@#=     .%@:        //
//     [email protected]    *@@@@@@@@@@@@@@@@@%: .   [email protected]@@@@@@@@@@+        .=*%@@@@@@@@@@@@@#+-      [email protected]*          //
//      *@-    :#@@@@@@@@@@@@@%=  :@#  [email protected]@@@@@@@@@@              .--====--.         -*@*:           //
//       [email protected]*.    .=*%@@@@@%#=:    %@*  [email protected]@@@@@@@@@+    *%%*=.                   :=#@#=              //
//        .*@#-.               [email protected]@@=  :@@@@@@@@@@.   *@. -+%%*=:.        .:=+#@#+:                 //
//           -*%%*+=-::::::-+*%%[email protected]:  [email protected]@@@@@@@@#    @#      :=*#%%%%%%%%#*=-.                     //
//               :-=+*****++=:    [email protected]   @@@@@@@@@-   :@+                                            //
//                                [email protected]:   #@@@@@@@@    [email protected]=                                            //
//                                [email protected]=   [email protected]@@@@@@%    [email protected]                                            //
//                                 @#    @@@@@@@#    [email protected]                                            //
//                                 *@.   [email protected]@@@@@*    [email protected]                                            //
//                                 [email protected]#    #@@@@@*    [email protected]=                                            //
//                                  [email protected]=    %@@@@#    :@=                                            //
//                                   [email protected]   .%@@@%    :@+                                            //
//                                    [email protected]=    #@@@    [email protected]*                                            //
//                                     [email protected]#.   [email protected]@:    @*                                            //
//                                      .#@=    -.    @#                                            //
//                                        :%%=        @#                                            //
//                                          -%%+.     @#                                            //
//                                            :*@#-   @#                                            //
//                                               -#@#*@=                                            //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract N8VIP is ERC1155Creator {
    constructor() ERC1155Creator("N8_LIFETIME_VIP", "N8VIP") {}
}