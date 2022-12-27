// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE ART OF JUAN!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                               :%=:               //
//                                                                             -.%@@=               //
//                                                            .+#* .+*-   [email protected]:%*@@@@:               //
//                                                :+#:      -**: =#*-    .=#@%#[email protected]@@@.               //
//                                             :+%#=.      #* :*#-       [email protected]@@@*[email protected]@@@                //
//                                          :[email protected]#=     -##*[email protected]%+.      -*#:@@@@[email protected]@@%                //
//                                        =%#=       #-  :%[email protected]*     :*@@@# %@@@[email protected]@@#                //
//                                     :*@%.         %-   @.-%: .+%@@%=.  %@@@[email protected]@@*                //
//                                 :: **:*@.         .*++*-  .=%@@%+.     %@@@[email protected]@@+                //
//                             :+#@@-     %#               =%@@@+:        %@@@[email protected]@@=                //
//                         +- [email protected]*:#@      [email protected]           -#@@@*:           #@@@[email protected]@@-                //
//                        :@@= %[email protected]=       :@.       -*@@@#-              #@@@-:@@@:                //
//                     #. [email protected][email protected]:@%@::::.....:%.   -*@@@#-  *+             #@@@-:@@@:                //
//                 :.% #: +% #@:+%+*#######*::.:*@@@#=     %@%:           #@@@-:@@@.                //
//                 @[email protected][email protected]: *%:[email protected]@.%*         :[email protected]@@%=. #=    *@@#           *@@@:[email protected]@@.                //
//                 ::::.. #@#[email protected]#:@+     .+%@@@@:   *@+.   [email protected]@@*          *@@@:[email protected]@@.                //
//                 +*@=-: #+   [email protected]*[email protected]= .=#@@@#%@#   [email protected]%#=   :@@@@+         [email protected]@@: @@@.                //
//                 -*#+=: %=    =#::=#@@@+: %@@-  [email protected]% %*   [email protected]@@@@+        [email protected]@@: @@@.                //
//                 +=  .  @+     =#@@@*:   [email protected]@%   #@: [email protected]   @@@*@@+       [email protected]@@: @@@.                //
//                 +#+=-  @+  -#@@@@@.     %@@-  :@+  [email protected]+   @@@ #@@=      [email protected]@@: %@@.                //
//                 #-      -*@@@@*[email protected]@     [email protected]@#   %@.   @#   %@@. #@@=     :@@@- %@@.                //
//                 #.   -*@@@#@@@[email protected]@     @@%-  [email protected]#    %*-  #@@-  #@@-    [email protected]@@- #@@:                //
//                 = :*@@@#-  #@@- @@    [email protected]@#   %@-    +**  #@@*   #@@-    @@@- *@@:                //
//                :*@@@%=     [email protected]@: @@.   @@%-  [email protected]@   .=#%@. [email protected]@#    #@@-   %@@= [email protected]@-                //
//               :@@@+.       :@@: %@.  [email protected]%*  [email protected]@+.:*%#@@@= :@@@     %@@-  #@@= [email protected]@=                //
//                -:          [email protected]@. #@:  %@*:  #@@.-%@%*[email protected]*#  @@@      %@@= [email protected]@+ [email protected]@+                //
//                             @@. *@- =%%-  :@@# -:    **#. #@@.      #@@[email protected]@+ [email protected]@*                //
//                   +%=-      @@. *@= %@+   #@@:       [email protected]*= [email protected]@-       #@@#@@# .%@=                //
//                  :%@@@%=    @@: #@+-%#   [email protected]@@        [email protected]*#  @@+        *@@@@@                     //
//                    :*@@@@+. %@- #@#*#.   @@@+         #@%. [email protected]#         *@@@@.  +=                //
//                      .=%@@@*#@- *@@@*   [email protected]@%.         [email protected]%= [email protected]@          =%@@= %@%                //
//                         :*@@@@= *@@@:  [email protected]@@#          [email protected]@%  %@:          :%@+ =#:                //
//                           [email protected]@+ [email protected]**   [email protected]@@=           #@%  [email protected]           :=-                    //
//                              *+ .=*.   :%@#.           -+*   +                                   //
//                                  .:     .-=              .                                       //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TAOJ is ERC1155Creator {
    constructor() ERC1155Creator("THE ART OF JUAN!", "TAOJ") {}
}