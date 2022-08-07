// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sakki-Sakki ONE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//       #@@@@@@@#***-:..                                                    ..:-***##%@@@@@@@@@@@@@@@@       //
//      @:@@@@@@[email protected]@@***@@@@@****@@@@@%%#@@@@@**#@@@@***@@@@***@@@**@@@***@@@****@@@@@**#@@@@**@@@@@@@@@@      //
//      @[email protected]@@@@@[email protected]@@@**@@@@@**#@@@@@#***@@@@@##%@@@@@@@@@@@@@@@@@@@@@@#%#@@@@@##@@@@@*#@@@@@##@:@@@@@@@@      //
//      @[email protected]@[email protected]                                                                           @ #[email protected]@@      //
//      @[email protected]@@                                                                                 @:=  [email protected]@@      //
//      @[email protected]@@@#                                                                                . =: [email protected]@@      //
//      *[email protected]@@                                                                                      [email protected]@%      //
//      [email protected]@@@                                       #@@@@@@@@@@%                                   [email protected]@%      //
//      [email protected]#@-                                     [email protected]@@*       #@@                                  [email protected]@@      //
//       %@...                                    [email protected]@    [email protected]@@@#  %@                                [email protected]:#@      //
//       @@* *                                   [email protected]+ [email protected]@@@@@@@@@@ @@                               :*%%:      //
//       @%=                                     @@ @@@@*@#*@*@@@[email protected]                                +%*:      //
//       @%                                     @@ %@**@*%@*@[email protected]@*@ @                                 [email protected]      //
//       *%                                     @- @@@*@@@@@@@@*#@ @:                                [email protected]      //
//       *%                                     @ @@*@@-      @@@@ @@                                 @.      //
//       *%                     @@@@@@@@@@@@@@@@@ @@@@        @@@@ @@@@@@@@@@@@@@@@@@@@#*=            %.      //
//       @@                    @@                 @*@*        @#*%            .::-=**#%@@@:           *       //
//       @@                   @@  @@@@@@@%@@@*@%@%@@@@@@@@*==%@@@@@@*@*@@[email protected]#@@@@@@@@@#:  @            *       //
//       @@                  @@ [email protected]@@@@:@-*=-.    [email protected]@@-#@@@*@@#@@@@@              [email protected]@@@@@ @           [email protected]       //
//       @@                 @@ [email protected]@::::@        [email protected]@@*%@@     @@#**@@+              %::@@@ @           %@       //
//       *@               [email protected]@ @@* @%           =%:@@@-:    *@:@@@@@-              @*@@@@ @           %@       //
//       *#              [email protected]@ @@*               @@:@@%-=    *%::::[email protected]              =#@@@@@ @           @@       //
//       *#              @@ %@*:@              @[email protected]@@@%@    [email protected]@@@@@#          :   @%@#@@@ @           @*       //
//       @@             @@ [email protected]@@@@                                          @ ::[email protected]@@ @[email protected]@ @           @*       //
//       @@            [email protected] [email protected]::*@@ @@@@@@@@@#@[email protected]#@*@*@*@*@*#@@@@@@@@@@@@@@@@@@=::::@  [email protected]@ @           @*       //
//       @@            @@ @@@@@@#@@*@*@*@*@*@*@*@*@[email protected]*@*@*%*@*@*%%[email protected]#*@*@*  :@@@@%%  [email protected]@ @           @@       //
//       @@            @@ @@@@@: :                                  .. ...  [email protected]@@## [email protected][email protected] @           @@       //
//       **            @@ @@@++.-                                          .  [email protected]+-   %@ @           @@       //
//       **            @* @@@=                                                 [email protected]:    [email protected] @           @@       //
//       @#            @= @@:         [email protected]#@@@@@@@-        @-                    [email protected]:.   @@ @           **       //
//       @@            @: @@         @@@@%@#@@@@@@     @@@*@    #@@@@          [email protected]:    #@ @           **       //
//       @@            @. @@%        #@@@@@@@@@@@@     @[email protected]@@   ###[email protected]%@         :@=    @@ @           #*       //
//       @@            @[email protected]@        @[email protected]@@@   [email protected]@@@     @+*#@%  @@@@@@@*       :*-     *@ @           @@       //
//       @@            @ :@@        #@@@@      --      @#[email protected]@@  @@#@@@@#       @ *@    @@ @           @@       //
//       %*            @ =*@        @#[email protected]              @@*@@@  @@%@@@@%         %@    *@ @           @@       //
//       %*            @ **@       [email protected][email protected]@               @@[email protected]@@: @@%[email protected]%@-         @%    @@ @           @@       //
//       %*            @ %@@       %@@@@               @@[email protected]@@@@@*@@@@.         *@    *@ @           **       //
//       @@            @ @@%       @@@%@               @@@@:@@@** @@@@.         #@    @@ @           **       //
//       @@            @ @*-       #@@[email protected]     [email protected]@@@@@   @@@@ @@@@  @@@@:         @@    *@ @           **       //
//       @@            @ @@        :@@@@     @@@@@@@   @[email protected]@ @@@+  @@@@:         %@    @@ @           @@       //
//       @@            @ @@         @#@@      . @@@    @+%@ [email protected]@@  @@@@*        :%@     @ @           @@       //
//       *#            @ @*         *@@@        @@@    @@@@  @@@  @@@@*        [email protected]@     @ @           @@       //
//       *#            @ @*         @@@@:       %@=    @@@@  @@@  @[email protected]+*        *@@   *[email protected] @           @@       //
//       **            @ @@         [email protected]@@@       %@@:   @[email protected]@   @%  @=%=*        #@%    [email protected] @           @@       //
//       **            @ @@         [email protected]@@@=      @@@   [email protected]*@@       @@@%+       +%@@   %@@ @           @*       //
//       @@            @ @%          @@@@@   @@@@@@   @@@@@       @@@@         @@    *@@ @           #*.      //
//       @@            @ @@          @@@@@@@@@@@[email protected]    [email protected][email protected]@       @@@@        @:*-  @[email protected]@:@.          #*.      //
//      [email protected]@            @ @[email protected]          @@@@@@@@@@@:     @@@@        @[email protected]         #@#   [email protected]@[email protected]:          @@.      //
//      [email protected]@            @ @+             .==-.           @@@                    @@#. @[email protected]= @-          @@.      //
//      :**            @ =+%-                                              + + @@#: =%  @@           @@.      //
//      +**            @ @@@@                                               . [email protected]#+ %@  @@            @@.      //
//      +*#            @ @@@ .               ..:-+#@@@@@@@@*=:.            **=:@*[email protected]% [email protected]@             @@.      //
//      *@@            @ @@::-:+ .*@@[email protected]@*@*@@*#@%*@@*@@**@@*@@*@@*@@@@@@-  [email protected]@@@++# @@@              **.      //
//      #@@ @          @ @@@@@@+ **@@@+:.                   [email protected]@@@@@@**@**@ @@@@@+: @@=             = #*.      //
//      %@@%           @ #@@@=.                                       :[email protected]@@@@@@@: @@                %@@.      //
//      @[email protected]          @:       .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#=.      @@                 [email protected]@      //
//      @[email protected][email protected]         @@@@@@@@@@@#=:                               .+#@@@@@@@@@@@                 ::@:@      //
//      @:@@-                                                                                     [email protected][email protected]      //
//      @:@+--                                                                                     [email protected][email protected]      //
//      @:@[email protected]@ :@=                                                                             @*  [email protected]@      //
//      @[email protected]@@@@@@[email protected]                                                                           [email protected]@@@@[email protected]@      //
//      @[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@%%%%%%%%%*=-:.                   ..::--=%%%%%%@@@@@@@@@@@@%%  [email protected]@@@@@[email protected]      //
//      @:@@@@@@[email protected]@%**#@@@@****@@@@@***@@@@@**[email protected]@@@***@@@@***@@@**@@@***@@@****@@@@@**#@@@@**@@[email protected]@@@@@[email protected]      //
//       #@@@@@@%@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#@@@@**@@@@@@@@@@.      //
//        ....                                                                                     ...        //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Sakki is ERC721Creator {
    constructor() ERC721Creator("Sakki-Sakki ONE", "Sakki") {}
}