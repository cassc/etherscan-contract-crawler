// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kioppa Rebel Collector Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                         -*%%+                                                              //
//                                      .*%+: *@                                                              //
//                                      %%+- [email protected]                                                              //
//                                      :@# :@+                                                               //
//                .:--:.                %# [email protected]*                 .::-------::.                                  //
//            -*%#*+==+*%#+:           #%  %#    -+##- :-+*#%##*++=======++*#%#*=:                            //
//          =%*--#%%%#+:  -*%+.       [email protected] #%   .%#::@@#*++++*##%%%%%%#%%##*=-. :-+%#=                         //
//         #%. #%:   .=%@*-  =%*:    [email protected]: *@.  :%%  =++#%#+=:.            .:-+*%#=. [email protected]+.                      //
//        #%  #%    -%%*+==-   -%#: [email protected]= [email protected]++#%*=  #%+:                         .=%#:  [email protected]+                     //
//       [email protected] :@-   .%@#####=     -#%@+ [email protected]#+++*%..*@++**+. :=+-=**+:=+=-+*+:-+***+::##: .*%:                   //
//       [email protected]  [email protected]: [email protected]*+#@   [email protected]=     -+  =+#%@@@+.:@%==:[email protected]%*-=%=:[email protected]#[email protected]*:.%%=-...%#  [email protected]=  [email protected]:                  //
//       [email protected]  :@- *%  [email protected]    :@+  =.   #@+. @%-  #-.%@*  #:  -+. -=  :=- .-:%@. *@.   :%%%#=                   //
//       :@-  %# :@+  :*%%%%%*+  .#    [email protected]+.%%  +  %@@: +#  *@* -%. [email protected]%.  :@@: [email protected]                             //
//        %%  [email protected] .*%*+===+*#%@=  . ##: .*@@. -: :@@-.*%  *@# [email protected]: [email protected]%.   %*. :*%@   -*##:                     //
//        [email protected]+  [email protected]   .:----: :@-   *@=%*. .:.=#+  --*@@. .+-.*@-  +=.==  =+ :+%#:.*%*: @*                     //
//         :@*  -%+          *@   [email protected]:  [email protected]+  :#@@@@@#%@: [email protected]##%@- :@#@@*: [email protected]##*-   *@+  #%.                     //
//          .#%:  [email protected]+.      [email protected]:  [email protected]*+*#%#*+.  :===+*#: [email protected]+ [email protected]+ :@+ #@+ :@=       *@. *@.                      //
//            -%#-  =#%*=--#%:  -%*++++*#%%%%-  :**+   .=#%%# .#@#*@* [email protected]@*-:=*##*@: [email protected]:                       //
//              :*%*-. .-=+++- .+*%#+=:.    :#%-  -= .%+  :#   .. #* .=: [email protected]*-: [email protected] [email protected]                        //
//                 :=*#%@@@+: [email protected]@%****++=-:.  :*%#: .#@@#  +: ++-##  -#. [email protected]+ [email protected]=                         //
//                    =%#-:=  =++===---:--=*###+#%  %@%%:.+. -+%@# :%@= :  =*@@* .%*                          //
//                  =%*. -+  %%++++++**%@#*=:  :=. *#+++#@- .#*=+  @%-:*  =#*=+  [email protected]#                          //
//                .#%: [email protected]@: *%.       *%*++====:    .=*%@@- .-*@* .++%@@. :=#@.:+#%%%#%%%##*+=:               //
//                %#  %@@- [email protected]        +%#%%%%@@: [email protected]%*=:  :=#@@%*%@@@@@#*+++++++++++=-::..  .:=+#%#=:          //
//               [email protected] [email protected]@=  [email protected]=             :%#. :@= .-+#%*=: .-+#*+***%@@@@%*+++++++***++=-:     .=#%=        //
//               *%  [email protected]%:+%#-            :*%=  [email protected]*       [email protected]@#-:-. .-+#@#+++#%#*+=-::..:::-=+#%#=.   :%#       //
//               [email protected]:  #@#-            .=%#=-: .%#     -*%*==*%*=*@%+ .. :=*##*+=:.            .=%#.  [email protected]      //
//                [email protected]=  -#%*=-:::::-=*%#+=*@#  %#   :*%+-=#%+:   #@+=#%#%#+=:..:=+*#%#*++======+*%#::[email protected]+       //
//                 :*%*-. :-=++++++***%%*@%  #%  .##-:*@+:      .=+=:    :=+#%%#+=-:::---====+++*#%*=         //
//                    :=*#%%#%#%%#*+=:  #%. *@.  .#%%*-                        .:-=+**######**+=:.            //
//                                     [email protected] =%@                                                                //
//                                    :@- -*%=                                                                //
//                                    .#%%+:                                                                  //
//                                                                                                            //
//                                                                                                            //
//              ## ##    ## ##   ####     ####     ### ###   ## ##   #### ##   ## ##   ### ##                 //
//             ##   ##  ##   ##   ##       ##       ##  ##  ##   ##  # ## ##  ##   ##   ##  ##                //
//             ##       ##   ##   ##       ##       ##      ##         ##     ##   ##   ##  ##                //
//             ##       ##   ##   ##       ##       ## ##   ##         ##     ##   ##   ## ##                 //
//             ##       ##   ##   ##       ##       ##      ##         ##     ##   ##   ## ##                 //
//             ##   ##  ##   ##   ##  ##   ##  ##   ##  ##  ##   ##    ##     ##   ##   ##  ##                //
//              ## ##    ## ##   ### ###  ### ###  ### ###   ## ##    ####     ## ##   #### ##                //
//                                                                                                            //
//                                                                                                            //
//                                ### ##     ##      ## ##    ## ##                                           //
//                                ##  ##     ##    ##   ##  ##   ##                                           //
//                                ##  ##   ## ##   ####     ####                                              //
//                                ##  ##   ##  ##   #####    #####                                            //
//                                ## ##    ## ###      ###      ###                                           //
//                                ##       ##  ##  ##   ##  ##   ##                                           //
//                               ####     ###  ##   ## ##    ## ##                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KRCP is ERC721Creator {
    constructor() ERC721Creator("Kioppa Rebel Collector Pass", "KRCP") {}
}