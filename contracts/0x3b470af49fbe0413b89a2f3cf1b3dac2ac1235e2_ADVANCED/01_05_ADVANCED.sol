// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Advanced Leisure
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                             .::#@#:.                                                                                                  //
//                                                                           =*%@@@%#@+                                                                                                  //
//                                                                         [email protected]@@@:    @%                                                                                                  //
//                                                                       =#@@+-     *@+                                                                                                  //
//                                                                      @@@-       .%@+                                                                                                  //
//                                                                   :#@@*.        [email protected]@                                                                                                   //
//                                                                  *%@@:         [email protected]@:                                                                                                   //
//                                                                :@@@:           %@=                                                                                                    //
//                                                               *@@+:           [email protected]%.                                                                                                    //
//                                                              @@@.             @@                                                                                                      //
//                                                            *@@+              @@*                                                                                                      //
//                                                          .%@@               [email protected]#                                                                                                       //
//                                                         [email protected]@*:               @@=                                                                                                       //
//                                                        [email protected]@-                %@%                                                                                                        //
//                                                      [email protected]@%-                [email protected]%                                                                                                         //
//                                                     .%@*                 .%@+                                                                                                         //
//                                                    [email protected]@%                  [email protected]%                                                                                                          //
//                                                   *@%-                  [email protected]@                                                                                                           //
//                                                  %@@                    #@=                                                                                                           //
//                                                 *@%.                   [email protected]%.        .%*                                                           =%                                   //
//                                                %@@.                    @@.         %@.                                                          [email protected]                                   //
//                                              .#@+                     @@*        [email protected]%                                                          .%@*                                    //
//                                           :+*%@@****************-    [email protected]#        #@@.                                                         :%@+                                     //
//                                   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+  [email protected]@*      #@@@          =+     [email protected]@-      ::             ..   *@@@      [email protected]@@#                                      //
//                            [email protected]@@@@@*[email protected]@@=                :+=.  #@#  =+*#**@@-  .+%@- :[email protected]+%+=   [email protected]@=-+++=  :++%+++: [email protected]@=+: :=+#+*#@@                                       //
//                            @@@@:         [email protected]@:                      *@@. *@@[email protected]+ [email protected]@@@= %@[email protected] [email protected]@*@*[email protected]@%@+  #@@%.  %@@@@@*    #@[email protected]@@@@@@@%#@: #@@@%                                    //
//                            -.           [email protected]@=                      [email protected]@-  +**-          +**=   +**          :*+         -*****          **+.                                            //
//                                        [email protected]@:                       %@:                                                                                                                 //
//                                       [email protected]@=                        *                                                                                                                   //
//                                      [email protected]@-                                                                                                                                             //
//                                     [email protected]@-  ==*++*@@+%[email protected]#@@%@#%%####%@%@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@=                                   //
//                                    .%@=                                                                                                                                               //
//                                    %@:                                                                                                                                                //
//                                   *@=     =%.             :@#*=             %=             % #             +%. *             *@*=             [email protected]**-                                   //
//                                  %@:       *               @- .             +             :* +              #                [email protected] #              #  -                                   //
//                                 #@=        *               @-               +             :@.               #                [email protected] #              # :                                    //
//                                #@*         *               @#*.             +              #@=              #                [email protected]*=              @*@                                    //
//                               *@@          *               @- .             +               [email protected]              #                [email protected]:              # %                                    //
//                              :@%.          *               @-               +             :  #              #                [email protected]#              #                                      //
//                              @@            *  .            @-               +             +  #              #                [email protected] %              #  =                                   //
//                            [email protected]%.           .= *            .*:.=             -.            -=-+              *=--             -* *:             + =-                                   //
//                            %@:               .                                             ::                ::                                  .                                    //
//                           [email protected]#                                                                                                                                                         //
//                          [email protected]*              +:.=.-:::::-*==*-++=:-=****+*****+******+*******=***=:-:+=:=+ -::-+=*+*==-*=+=*:++*+=:..:-.:-:.:.                                           //
//                         :@%                                                                                                                                                           //
//                         %%                                                                                                                                                            //
//                        #@-                                                                                                                                                            //
//                       [email protected]+                                                                                                                                                             //
//                       =-                                                                                                                                                              //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ADVANCED is ERC1155Creator {
    constructor() ERC1155Creator("Advanced Leisure", "ADVANCED") {}
}