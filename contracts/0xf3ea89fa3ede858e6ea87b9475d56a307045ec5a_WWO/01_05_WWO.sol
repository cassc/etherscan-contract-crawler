// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wicked Wide Ones
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                     :::                                                                                     ::.                //
//                    [email protected]@%##%##*+==-::.                                                           .::-=++##%%##@@@                //
//                    [email protected]@*     .::-==+*###%#####*++====---::::::::::::::::::::::--=====+*#####%###*+==-::.    [email protected]@@                //
//                    [email protected]@*                      ....:::----------=======----------:::....   ..:---::.         [email protected]@@                //
//                    [email protected]@*                                                              .+%@#+==-==+#@%+.     [email protected]@@                //
//                    [email protected]@*                                                              @@@.          *@@     [email protected]@@                //
//                    [email protected]@*                            :+#%#+:                :+###+:    [email protected]@*-:     .:[email protected]@+     [email protected]@@                //
//                    [email protected]@*                        .=#@%+- :+%@#=:        .=#@%+-.-+%@#=.  :-=++***++=-:       [email protected]@@                //
//                    [email protected]@*                     .=%@#=         -*@%+:  :+%@*-        .=#@%=.                   [email protected]@@                //
//                    [email protected]@*                  .+%@%+.              -#@@@@*=               =%@%+.                [email protected]@@                //
//                    [email protected]@*               .=%@#=.                -*@%*-                    .=#@%=.             [email protected]@@                //
//                    [email protected]@*            -+%@#-                :+#@#=.                           -*@%+-          [email protected]@@                //
//                    [email protected]@*         -#@%+:       .:::::--==*@@@%+++++++++++========--::::..       :+%@#=       [email protected]@@                //
//                    [email protected]@*     .-*@@@#*###%%####*++=====--::::::::::::::::::::::--=====+*####%%###*+*@@@*-    [email protected]@@                //
//                    [email protected]@%****++=--::..                      ::::                                 ..::-==++***#@@@                //
//                                                        .#@@@@@@%+.                                                             //
//                                                        %@@@@@@@@@@+   [email protected]@@@*#@@                                                //
//                                                       [email protected]@@@@@@@@@@@:  [email protected]@@**[email protected]@                                                //
//                                                       %@@@@@@@@@@@@.  [email protected]@#[email protected]:*%%                                            //
//                                                       [email protected]@@@@@@@@@@:  :#@@=    @-%@@                                            //
//                                                        -%@@@@@@@*.   [email protected]@+.  [email protected] [email protected]@                                            //
//                                                 .=%@@@#*=====-:      [email protected]@*=:.:@ =%#                                            //
//                                              [email protected]@@@@@@@@@@@@@@%#=.     -------=:+#%%#                                          //
//                                             [email protected]@@@@@@@@@@@@@@@@@@@@%=        -*@@@@@@%                                          //
//                                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@*: :=#@@@@@@@*-                                           //
//                                             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+: -                                            //
//                                               [email protected]@@@@@@@@@@@@@@@%..-=#@@@@@@***%@+                                              //
//                                                [email protected]@@@@@@@@@@@@@@-     .+*=. :@@@@-                                              //
//                                                %@@@@@@@@@@@@@@@            [email protected]@@@                                               //
//                                               [email protected]@@@@@@@@@@@@@@=             @@@@                                               //
//                                               @@@@@@@@@@@@@@@@            -=****=                                              //
//                                              [email protected]@@@@@@@@@@@@@@*            *@:@-%#                                              //
//                                               *@@@@@@@@@@@@@@#            @= @:[email protected]                                             //
//                                                @@@@@@@@@@@@@@@%-         #*  @: :@.                                            //
//                                                :@@@@@@@@@@@@@@@@%-      *#   @   [email protected]                                           //
//                                                 [email protected]@@@@@@%*@@@@@@@@%:   [email protected]   %    #%                                           //
//                                                  [email protected]@@@@@@+:@@@@@@@@@*[email protected]:    %    :@*                                          //
//                                           .:-=+=- [email protected]@@@@@@= -#@@@@@@@@=+     %     [email protected]:+*@@@@@@@@@@%                           //
//                                     :-+#%#*=:.    [email protected]@@@@@@@:  [email protected]@@@@@@=      %      -#   .*@@@@@@@@*:                          //
//                                 -+#@@%*-          %@@@@@@@%.   @@@@@@@=      @.      #:    [email protected]@@@@*#@@#+-.                     //
//                             :+%@@@%*.            %@@@@@@@-     @@@@@@@-      @       :@      .*@@#   -*@@@%+:                  //
//                          =#@@@@#-              .%@@@@@@@.      @@@@@@@=      @        #%        -       -*@@@@*=.              //
//                       .*@@@@@@-                #@@@@@@@-      [email protected]@@@@@@+      %         #*                 .%@@@@@#-            //
//                     .*@@@@@@@=                [email protected]@@@@@@*       [email protected]@@@@@@+      %          @-                 [email protected]@@@@@@*           //
//                    [email protected]@@@@@@@#                [email protected]@@@@@@+         @@@@@@@+      %          :@:                [email protected]@@@@@@@@-         //
//                   *@@@@@@@@@@                #@@@@@@+          #@@@@@@+      %           [email protected]                [email protected]@@@@@@@@@-        //
//                   @@@@@@@@@@@%.     [email protected]%      :%@@@@=           .*@@@@*       @            -:               #@@@@@@@@@@@        //
//                  [email protected]@@@@@@@@@@@@=   *@@@:       .::                ..                                     -%@@@@@@@@@@@@        //
//                  [email protected]@@@@@@@@@@@@@%+%@@@@#                                                              [email protected]@@@@@@@@@@@@@%        //
//                   :@@@@@@@@@@@@@@@@@@@@@:                                                          .#@@@@@@@@@@@@@@@@%.        //
//                    [email protected]@@@@@@@@@@@@@@@@@@@+                                                           [email protected]@@@@@@@@@@@@@@#          //
//                      *@@@@@@@@@@@@@@@@@@%                                                            -%@@@@@@@@@@@@+           //
//                       .+#@@@@@@@@@@@@@@@@:                                                             =%@@@@@@@%=.            //
//                          [email protected]@@@@@@@@@@@@@%                                                               [email protected]@@%=.               //
//                           [email protected]@@@@@@@@@@@@@@:                                                               .=.                  //
//                          [email protected]@@@@@@@@@@%#*+-.                                                                                    //
//                         [email protected]@%#**+-:.                                                                                            //
//                         :.                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WWO is ERC721Creator {
    constructor() ERC721Creator("Wicked Wide Ones", "WWO") {}
}