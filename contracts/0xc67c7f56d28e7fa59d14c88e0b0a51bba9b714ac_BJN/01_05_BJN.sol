// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Incrementum Series
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                  -                                                    .--                     ::           //
//          .     --#.                                       =#+-       #+:         .      %.:+---            //
//          +.     +=+      -++   +.   -.      .              -#+#%*    %=     .+  .#     *-.#-               //
//          .*-=   @*         ==::-#    *. =-  %.                .%:   .%+     =-  %#+. .**:::                //
//          .--**-:@.              -*    ::-%. -%.               [email protected] :*#-      [email protected]#+#*#***:                    //
//              .=%%                -+=-:.  :#.+=    .=          *@:-%:         .:[email protected]%%                        //
//           .*   *+                  :=..---+#%   = #:          #@+=             #%                          //
//           #@:  %:                =+.        .--=#-=           #@#         .  -#%.       ::  +:             //
//          :@@   += :*:            *-    .=      [email protected]   #+.      [email protected]@        .%.+%*         *+  %=             //
//          [email protected]@.    #%:             :      .=--:::[email protected]   [email protected]@:      [email protected]#.       #%#-          *# [email protected]=             //
//         ::@=    #@:             :               %-    -%%*#*+===+%@*.     [email protected]+        +  +%  @-     -:      //
//        :@@=    :@%.   .%     .*@%           *:  *+      ..       :@@%.     #%. :     +: [email protected]: %=    +%       //
//     *   #@:     [email protected]%   :@:  [email protected]%#.   =#+:    +*  -%                .*@@.    .%#:@#:   -*  =#.#*   [email protected]       //
//     %.  :@*     [email protected]+    .-**@#-*-     :+%@#*::%   @*                 :@%-    -#+%@@=  #=    :*%  :%+        //
//     *+   [email protected]*+   @-      [email protected]#.            .%@%=.   :@*  -+.            .=#@-     .+%@#=#*.    [email protected]%+         //
//     .%-   :#@*.:@+      [email protected]%          .-::*@+      [email protected]+  [email protected]%--=+#+.       *@:      :=+%@@:    :@#%%          //
//      +#-. [email protected]@%+*@*     [email protected]@-         [email protected]*.      -%+-+%%     -+      :%*  .##     [email protected]%  -   :%@%          //
//       :=++*%@*   [email protected]*:   =%@*-::  .. +....*#%*####@%%**#%*##*+-       .%#  :#-      [email protected] #     :@@-*        //
//           [email protected]=       -+#*%+==-=+###*###**++*@@-.-+   *:  :+*:=*@@#:   [email protected]=.-+#        %# .*+#*  [email protected]@@+        //
//          [email protected]        ++  #               .#%=   -+    ::+#:    [email protected]@%   [email protected]  +*       #@   #@*   #@@.         //
//          [email protected]        @:  %         **+:-%%-     -=      #       .#@-   %=  *%-      %%  [email protected]@-   #@+          //
//          #%-.      =*   %      .*:..:-. ===    -=      +*.  --. [email protected]=   *@: [email protected]      %#[email protected]*.    #@+          //
//         -*:.* .         %      -.  --.:---*    =-     ++==:   -+ #@=  .%%-:+      +*@#@*     [email protected]%:          //
//        *   -+  +        %         -= =.  :=    =-   +%:  [email protected]   *:.#@*    *%.      *@%+-      *@. .:.=      //
//        -=-. .           %                      +-   =*   +%      =#@@:    %*     :%%:       :@=  +. #      //
//           +-            #                      +:   .:   -=       -#@*   [email protected]=   .#@@+      [email protected]+   =- %=     //
//            *           .#                      +: :                [email protected]@: :*%    #@+#+    :#@*.     +%@-     //
//                        .*                      +:  ::=   -#-       [email protected]%: [email protected]@   [email protected]# [email protected]::*%%-.     %%+-       //
//                        .*                      *. :-#= .:: -.     *@*   [email protected]#   [email protected]@:[email protected]%@#=       =%. =.      //
//                        :*             . .   .  *.    +#=-:=*+   =%@=   [email protected]@=   :%@%@@%-        [email protected]:  *+      //
//                        :+               =  -.  #.=  +=      -++#@@=    :@@%    *@@%%@. =    =%%:  -#       //
//                        :+                  .   #  *#++-      .#@@-      @@@   *@+#@@@= -*#%#-.:=+%-        //
//                        -=        .. ... :..-   # :+   =      %@%.       @@@. [email protected]*  *@@@-#%+.      %         //
//                        -=       .+::+:  .--=   %*+   .*     #@@=       :@@@@.*@#   [email protected]@%.       .*#.        //
//                        --       :@@@@#   .     %.::  .#:   :@@@.       [email protected]@%: :@+   [email protected]@@.       #= -#.      //
//                        --       [email protected]@@@@.  ::  :+% -+  :--   [email protected]@@-      .%@@: .*@+    @@@:  +    .#  .*.     //
//                        =:       :%@@@+:..+=..--#=*.  +.    [email protected]@@%=    -%@@# [email protected]@%.   [email protected]@@.  +     -.         //
//                        =:     .*#@@@@#*=.--:.  #      .    :@@@@@%.  %@@@:[email protected]@#:  :%@@@@  .=*               //
//                        =:    :@@@@@@@@@@+:.    #:           [email protected]@@@@@:[email protected]@@*[email protected]@%  *#@@@@*   +-:               //
//                        =.   .%@@@@@@@@%@@+:    * :           [email protected]@@@@@@@@@#%@@@*%@@@@@* -++-                 //
//                        =.   [email protected][email protected]@@@@@@+.%%.. . *  :           :%@@@@@@@@@@@@@@@@@@@%**+:                   //
//                        +   [email protected]+ %@@@@@@@:.#%  ::*               .#@@@@@@@@@@@@@@@@#-.                       //
//                        +  :@= [email protected]@@@@@@@#  #* .:+  .:.            *@@@@@@@@@@@@@@=                          //
//                        = .%+  [email protected]@@@@@@@@+ [email protected]+ :=                  *@@@@@@@@@@@@:                           //
//                     :%%%#@@@%##%@@@%%%@@@@%@@%%%%#                [email protected]@@@@@@@@@@:                            //
//                      [email protected]@:...#@@-::::---:                [email protected]@@@@@@@@@-                             //
//                        -:      [email protected]@.   [email protected]@=    +=                  [email protected]@@@@@@@@%                              //
//                        ..      :@%    [email protected]@-                        [email protected]@@@@@@@@@                              //
//                                [email protected]#     [email protected]                        [email protected]@@@@@@@@@-                             //
//                                 @%     [email protected]=                        [email protected]@@@@@@@@@:                             //
//                                [email protected]@:    *@#                        #@@@@@@@@@%                              //
//                                :@@=    [email protected]@.                      [email protected]@@@@@@@@@#                              //
//                                 .:      ::                       #@@@@@@@@@@%                              //
//                                                                 *@@@@@@@@@@@@+                             //
//                                                                *@@@@@@@@@@@@@@=.                           //
//                                                              -%@@@@@@@@@@@@@@@@@#:                         //
//                                                     . .....=#@@@@@@@@@@@@@@@@@@@@@+.--..                   //
//                                                   ..:-==+*@@@@@@%@@@@@%%@@@@@@@%@@%%#--::                  //
//                                                  .. :+#%%#*###*%*::*%#..+##*=*==++****+:.                  //
//                                                    :-+-.-  -==--.=-+#===-#.:-+*=++=-                       //
//                                                   .:        ::. ..:.. .-:.::... .:-:.                      //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BJN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}