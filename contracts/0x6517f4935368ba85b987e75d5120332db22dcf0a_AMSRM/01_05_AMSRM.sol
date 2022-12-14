// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A-Mashiro
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                         .:=+*##%%@@@@@@@@%%##*+=:.                                         //
//                                    :=*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*=:                                    //
//                                -*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-                                //
//                            .=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.                            //
//                          =%@@@@@@@@@@@@@@@@%*+==-::::::::-==+*%@@@@@@@@@@@@@@@@%=                          //
//                       :*@@@@@@@@@@@@@%*=:.                      .:=*%@@@@@@@@@@@@@*:                       //
//                     :#@@@@@@@@@@@@*-.                                .-*@@@@@@@@@@@@#:                     //
//                   :#@@@@@@@@@@@+:   ...                            ...   :[email protected]@@@@@@@@@@#:                   //
//                  *@@@@@@@@@@#-:=*%@@@@@@@%#:.                .:#%@@@@@@@%*=:-#@@@@@@@@@@*                  //
//                [email protected]@@@@@@@@@*-.#@@@@@@@@@@@@@[email protected]:.          .:@[email protected]@@@@@@@@@@@@#.-*@@@@@@@@@@-                //
//               *@@@@@@@@@#:[email protected]@=-%@@@@@@@@@@@[email protected]*#.      .#*[email protected][email protected]@@@@@@@@@@%[email protected]@.:#@@@@@@@@@*               //
//              #@@@@@@@@@-:@%[email protected]@=-%@@@@@@@@@[email protected]*@:+:  :+:@*[email protected][email protected]@@@@@@@@%[email protected]@=-%@:[email protected]@@@@@@@@#              //
//            .%@@@@@@@@# [email protected]@@@%[email protected]@=-%@@@@@@@[email protected]*@:*+-#@#:@*[email protected][email protected]@@@@@@%[email protected]@=-%@@@@. #@@@@@@@@%.            //
//            %@@@@@@@@+  #@@@@@@%[email protected]@=-%@@@@@[email protected]*@::#@@@#:@*[email protected][email protected]@@@@%[email protected]@=-%@@@@@@#  [email protected]@@@@@@@%            //
//           #@@@@@@@@=  [email protected]@@@@@@@@%[email protected]@=-%@@@[email protected]:-#@@@@@#:@*[email protected][email protected]@@%[email protected]@=-%@@@@@@@@@.  [email protected]@@@@@@@#           //
//          [email protected]@@@@@@@+   :@@@@@@@@@@@%[email protected]@=-%@==+-#@@@@@@@#:@*[email protected][email protected]%[email protected]@=-%@@@@@@@@@@@:   [email protected]@@@@@@@+          //
//         [email protected]@@@@@@@#     @@@@@@@@@@@@@%[email protected]@=--:#@@@@@@@@@#:@*[email protected][email protected]@=-%@@@@@@@@@@@@@     #@@@@@@@@.         //
//         *@@@@@@@@.     [email protected]@@@@@@@@@@@@@%-=+-#@@@@@@@@@@@#:@*-%:[email protected]@=-%@@@@@@@@@@@@@@+     [email protected]@@@@@@@*         //
//        [email protected]@@@@@@@=       -+++++++++++++=: *@@@@@@@@@@@@@#:@[email protected]@=:-+++++++++++++++-       [email protected]@@@@@@@.        //
//        [email protected]@@@@@@@         +***********+-#:#@@@@@@@@@@@@@#[email protected]@=.+****************+         @@@@@@@@=        //
//        #@@@@@@@#          .+%%%%%%#-::*@:#@@@@@@@@@@@@%[email protected]@=-#%%%%%%%%%%%%%%%%+.          #@@@@@@@#        //
//        @@@@@@@@+            .:[email protected]*@:#@@@@@@@@@@%[email protected]@=-==++++++++++++++=:.            [email protected]@@@@@@@        //
//        @@@@@@@@=              :+-#[email protected]*@:#@@@@@@@@%[email protected]@=-%@@@@@@@@@@@@@@@@#:              [email protected]@@@@@@@        //
//        @@@@@@@@=              :#@@[email protected]*@:#@@@@@@%[email protected]@=-%@@@@@@@@@@@@@@@@#-+:              [email protected]@@@@@@@        //
//        @@@@@@@@+             *@@@@[email protected]*@:#@@@@%[email protected]@=-%@@@@@@@@@@@@@@@@#[email protected]@@#             [email protected]@@@@@@@        //
//        #@@@@@@@#            %@@@@@[email protected]*@:#@@%[email protected]@=-%@@@@@@@@@@@@@@@@#-:[email protected]@@@@%.           #@@@@@@@#        //
//        [email protected]@@@@@@@           #@@@@@@[email protected]*@:#%[email protected]@=-%@@@@@@@@@@@@@@@@#::@[email protected]@@@@@%           @@@@@@@@=        //
//        [email protected]@@@@@@@=        +:@@@@@@@[email protected]*@::[email protected]@=-%@@@@@@@@@@@@@@@@#-+*[email protected][email protected]@@@@@@-+        [email protected]@@@@@@@.        //
//         *@@@@@@@@.     ::[email protected]@@@@@@[email protected][email protected]@=:#%%%%%%%%%%%%%%%%#[email protected][email protected]@@@@@@++::     [email protected]@@@@@@@*         //
//         [email protected]@@@@@@@#     ==*[email protected]@@@@@@=+%:[email protected]@=-*****************[email protected]@=:%[email protected]@@@@@@=*==     #@@@@@@@@.         //
//          [email protected]@@@@@@@+   :+=%[email protected]@@@@@@[email protected]@=:-++++++++++++++++--.=++-:[email protected]@[email protected]@@@@@@:%=+:   [email protected]@@@@@@@+          //
//           #@@@@@@@@=  .%[email protected][email protected]@@@%[email protected]@=.*#################:-#######*[email protected]@=-%@@@@[email protected]%.  [email protected]@@@@@@@#           //
//            %@@@@@@@@+  #[email protected][email protected]%[email protected]@=-#################+.+############[email protected]@=-%@[email protected]+=#  [email protected]@@@@@@@%            //
//            .%@@@@@@@@# [email protected][email protected]=:[email protected]@=-%@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@%[email protected]@=:[email protected][email protected] #@@@@@@@@%.            //
//              #@@@@@@@@@-:%-:[email protected]@=:%@@@@@@@@@@@@@@@@#:  :*@@@@@@@@@@@@@@@@%:[email protected]@=:-%:[email protected]@@@@@@@@#              //
//               *@@@@@@@@@#:[email protected]@=:#*=+*%@@@@@@@@@%*-        -+#@@@@@@@@@%*+=*#:[email protected]@.:#@@@@@@@@@*               //
//                [email protected]@@@@@@@@@*-.*+==*%%*++++++=-.              .-=++++++*%%*==+*.-*@@@@@@@@@@-                //
//                  *@@@@@@@@@@#-:=**+======-.                    .-======+**=:-#@@@@@@@@@@*                  //
//                   :#@@@@@@@@@@@+:    ..                            ..    :[email protected]@@@@@@@@@@#:                   //
//                     :#@@@@@@@@@@@@*-.                                .-*@@@@@@@@@@@@#:                     //
//                       :*@@@@@@@@@@@@@%*=:.                      .:=*%@@@@@@@@@@@@@*:                       //
//                          =%@@@@@@@@@@@@@@@@%*+==-::::::::-==+*%@@@@@@@@@@@@@@@@%=                          //
//                            .=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.                            //
//                                -*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-                                //
//                                    :=*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*=:                                    //
//                                         .:=+*##%%@@@@@@@@%%##*+=:.                                         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AMSRM is ERC1155Creator {
    constructor() ERC1155Creator("A-Mashiro", "AMSRM") {}
}