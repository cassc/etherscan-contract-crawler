// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: -MEIOS-
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                      :=***+--:---*********=--:---**=-:                                     //
//                                  .=#@@@@@%####%@@@@@@@@@@@#@@@[email protected]=%@:@@+#+-                                 //
//                               :[email protected]*%@####[email protected]@@@@@@@@@@@@@@%%@%@@*@%:@*[email protected]*[email protected]@*+:                              //
//                             [email protected]@[email protected]###@@-------*@@@@@@@=%*[email protected]@**@@@@@[email protected]@:@@[email protected]%*:                            //
//                           :- [email protected]@@%#=    -%%#*==+*%%+-=*#%@#=*@@@@@%*%@[email protected]+*@+-                          //
//                         :%. .    +=-.  .-++-: :=*@@@@@@@%*+:. :=*@@#+=#%[email protected]#@#*##:                        //
//                        [email protected]*+=:       :++=. .=#@@@@@@@@@@@@@@@@@*-  .=#@%*#=*@*@@@%%*:                       //
//                       *@*: .:-=: -==- .-*%@@@%#*+-:.   .:-+*#%@@@%*=: -+%*###*%#.:=%*.                     //
//                      #@##@[email protected]@@=++:  =#@@%*=:                   -=*%@@%+: :+%@@@@[email protected]+ -#.                    //
//                     #%#@%+#@@*:  :*@@*-                            .-*@@%=. -#@@#[email protected]@*=*                    //
//                    :#+#*[email protected]@+.  =%@*-                                   [email protected]@#: [email protected]@=%*+#=                   //
//                    #@**#%=  .+%+--+#@@@@#+:                     -+%@@@%%+--+%#=  -#*+*@%                   //
//                    @@@%:   *%-.*@@@@%+:   :+                  .+.   :[email protected]@@@@*.-%@=  [email protected]@@@                   //
//                    =##   =%= [email protected]@@@@=       .+                 +        [email protected]@@@@- [email protected]%:  *##                   //
//                .:...+: :%+ .#@@@@=          *                 +          =%@@@#. *@= :+:.:.:               //
//              -:  :::=#@@+  %@@@#            #                 +            #@@@%  *@@#=:::  :-             //
//             -  ++. -#@@@- [email protected]@@*             %                 *             #@@@+ [email protected]@@#- :++  -            //
//             -  %. *@@@@@. @@@%             *:                 -=            [email protected]@@@ [email protected]@@@@* .%  +            //
//             =.  +=#@@@@@. @@@-            +-                   *-            [email protected]@@ :@@@@@*==  .-            //
//              :.   *@@%@@- #@@:           +=                     =+           [email protected]@% [email protected]@%@@#   .:             //
//               +*:    #@@% .%@+         =*:                       :*=         *@%. %@@%    -*=              //
//               ##@@%##@@@@*  =%-    .-==.                           .==-.    [email protected]=  *@@@@##%@@##.             //
//                *@@@@@@@@@@=  .:--=--...                             ..:--=--:   [email protected]@@@@@@@@@*               //
//               =%%@@@@@@@@@@#:.---:==-::--==:                   -=+--:--==:--: .#@@@@@@@@@@@@*              //
//                 [email protected]@*@@@@@@@@@@@%*=:.       -+*+:.         .:=+=:       .:=*%@@@@@@@@@@@#@@:                //
//                 .: [email protected]@@@@@@@#+=+*@@@%+.       =#%        :@#=       [email protected]@@@*+=+#@@@@@@@@: :                 //
//                     %@@@@@@=     #@+:*@#-      .%.       :#       -#@+:[email protected]%     [email protected]@@@@@%                    //
//                      ..*%@@#==*#+*##=  -%#.      *       %      .#%- .+*#**#+==*@@%=..                     //
//                          #@@+=%@    *@=  =%:     @#**+*#%@     [email protected]= [email protected]+    %#[email protected]@@                         //
//                          [email protected]#:.%%:   [email protected]= [email protected]:   [email protected]@@@@@@@@=   [email protected] [email protected]=   :%% -#@%.                         //
//                            #@=. =%#[email protected]@@@@@@  [email protected]@@@@@@@@@@+ [email protected]@@@@@@.:-#%= :[email protected]%.                          //
//                             [email protected]*-. [email protected]@-=. .*@@+%@@@@*-#=#@@@@%#@@+. [email protected]@. .-#%-                            //
//                               *@%+*@@:  [email protected]@@@@@@@@::-:[email protected]@@@@@@@@+.  [email protected]@*+%@#                              //
//                                                                                                            //
//                     ...     ..      ..                   .                   .x+=:.                        //
//                  x*8888x.:*8888: -"888:                @88>                z`    ^%                        //
//                X   48888X `8888H  8888                %8P          u.        .   <k                        //
//               X8x.  8888X  8888X  !888>       .u       .     ...ue888b     [email protected]"                        //
//               X8888 X8888  88888   "*8%-   ud8888.   [email protected]   888R Y888r  [email protected]^%8888"                         //
//           '*888!X8888>     X8888  xH8>   :888'8888. ''888E`  888R I888> x88:  `)8b.                        //
//                 `?8 `8888  X888X X888>   d888 '88%"   888E   888R I888> 8888N=*8888                        //
//                 -^  '888"  X888  8888>   8888.+"      888E   888R I888>  %8"    R88                        //
//                  dx '88~x. !88~  8888>   8888L        888E  u8888cJ888       @8Wou 9%                      //
//                .8888Xf.888x:!    X888X.: '8888c. .+   888&   "*888*P"   .888888P`                          //
//                :""888":~"888"     `888*"   "88888%     R888"    'Y"      `   ^"F                           //
//                    "~'    "~        ""       "YP'       ""                                                 //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEIOS is ERC721Creator {
    constructor() ERC721Creator("-MEIOS-", "MEIOS") {}
}