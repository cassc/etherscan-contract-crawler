// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tania del Rio Inktober Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                   .::.                                                                           //
//               .+%%%@###+          =+               .=       +%-   .-=#@**-.+-                    //
//               =: =%=       .      =-              :@#  ..  #%*    -.*#=.#@.+:  :.                //
//                 +%* =*%#[email protected]+*@+.## :+##++    .+#*@@:=%#**[email protected]*     .#@**%*=%=.*@*#*               //
//                :%% *@+-%*[email protected]@*@@-%@[email protected]%:#%.   :%+ #@[email protected]@+#[email protected]%.   .=%@@%: :@@.%@= %*               //
//                *@::@#+%# %@[email protected][email protected]% %%+#@:    #@=*@#.%@--:=%-     [email protected]*=%* *@[email protected]@:#+                //
//                #+  :: :- -.  -  -: .:..=.     :: :=: -=: .=.     -+  *@*.-. .--.                 //
//                                                                       .--                        //
//                                                                         .::::--**=..             //
//               ..........:::::::----------------------------------=====+*###****=--=-:::.         //
//           =#**+**+*****+**+****#######**####*****#######*#**#*##########*####*##*+++*+-.         //
//           :=-----:--::::::.::::::.......    ...........   .....         ..:=-:::=--              //
//                                                .                                                 //
//                      .-#@@*         %#       :%*        -*                                       //
//                      =+%@@-        #@*      [email protected]#         %@-                                      //
//                      .#%@=:=. :-  [email protected]@-.=:-*%@@#:-++=.  *@%-=:   :+*-  == :+=                     //
//                      *@@[email protected]@+#@@= @@@*+#@.#%#.:#@#:*@[email protected]@#=#@--%@#[email protected][email protected]@*#@@:                    //
//                     =%@-:@@@#@@%[email protected]@@*#*:*%%:[email protected]@# [email protected]%[email protected]@* [email protected]@[email protected]@%=%*:@@@=                        //
//                     #@= %%@[email protected]%: %@@@-  [email protected]@+ [email protected]@:.#%:#@*:*%%:#@%*=. *@@-                         //
//                    :@+  @%: :@* :#[email protected]@#   @@%:.#@##+..%@@@%=  :%%++-.*%:                          //
//                    .=              .*@+-: ::                                                     //
//                                       ..                                                         //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TDRIC is ERC1155Creator {
    constructor() ERC1155Creator("Tania del Rio Inktober Collection", "TDRIC") {}
}