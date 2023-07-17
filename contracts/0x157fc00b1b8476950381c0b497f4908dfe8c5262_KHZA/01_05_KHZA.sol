// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KHZ AIRDROPS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                       .:---:.                                    //
//                                                    .+%#+===+*%*-                                 //
//                                          :+#%###%*[email protected]+         -%#.                               //
//                             .:-:.      .%#-      -%#            %#                               //
//                          -#%*==+*%*=##*@*             ..        %@%#*#%*:                        //
//                        :%#:       #@- =#.       =%#%#%##%.      =.     [email protected]*                       //
//                        @*         .%:          [email protected]:  +-  #+              [email protected]                       //
//                       [email protected]:                       .                      [email protected]*                       //
//                       [email protected]*                                     :+**+.  +*[email protected]=                      //
//                        [email protected]%+     .-==:                        [email protected]#@.   [email protected]%.                     //
//                      [email protected]*--:    #%=--+-                       .    -+#%   :@%=:                   //
//                     :@=       [email protected]                                    [email protected]  -=--*%=                 //
//                     :@=       [email protected]:                    .         .              :@=                //
//                  =*%###.     %#=-                   [email protected]+       [email protected]=              %#                //
//                [email protected]+.         :@=                     %%*%+=--+%#[email protected]*===#%@=   -=*@:                //
//               *@.            :+.           :=     -%#.  =#@@%*-: :-+*[email protected]=  [email protected]+                  //
//              :@-                           [email protected]@###%*- -*%#++==-+*. :#*####@:  #%                  //
//              [email protected]             =#%%##=.      [email protected]     [email protected]#--*%#*#@*.  :#%*+%%@#*#%-                  //
//               %#.          .%%:   [email protected]*---=#%:       ..%@=     #@[email protected]@+   [email protected]%:@=                   //
//                +%*=-:      #@.*@#%%+.-=+=-.         :@@@@-    :@*@@@@+   @%[email protected]:                   //
//                  :@%-      @%     :@#               @@@@@=    [email protected]#@@@@-   @%-.                    //
//                   %@+      %@.   *@#*              [email protected]@@@@#:  [email protected]%[email protected]@@@@= *@+                      //
//                  #%:       :@#   .                 :@@@@@@+ :%#  [email protected]@@@+#%%%                      //
//                  %#         .%%=    -=              [email protected]@@@@*#@%#%%#%@@#+- :@=                     //
//                  [email protected]=          :+#%%%@%       =#%%%*=..+*#*[email protected]#:    [email protected]   [email protected]+                     //
//                   .+%#*++*#-        *@:     @@%=. .=#%+.            .    [email protected]                     //
//                       .::.%#        *@@:   [email protected]+:=:     =#%+-::           [email protected]=                      //
//                            +%*===+#%[email protected]+   :%*:      :=:*@++.        .*@-                       //
//                              :---:.    [email protected]*-  -#%*-.  [email protected]@-         -#@+                         //
//                                           -*%#+-::=*#%##@=     :-+#%+:                           //
//                                              .-+#%%%#**##**#%%%*+-.                              //
//                                                     ..::::..                                     //
//                                                    .                                             //
//       %@@@-:#@@@%- *@@@#. :@@@@ *%%%*  +%%%+   =#@@@@@%= *@@@+ *@@@@+ [email protected]@@%     [email protected]@@@@@@@#       //
//       @@@@#@@@@#.  #@@@@@=:@@@@ #@@@#  *@@@* :@@@@@@@@#  #@@@%@@@@@-  [email protected]@@@     *@@@@@@@@%       //
//       @@@@@@@@=    #@@@@@@%@@@@ #@@@#  *@@@*[email protected]@@@*. .-   #@@@@@@@*    [email protected]@@@     *@@@%+++.        //
//       @@@@@@@@=    #@@@@@@@@@@@ #@@@#  *@@@*:@@@@        #@@@@@@@#    [email protected]@@@     *@@@@@@@.        //
//       @@@@@@@@@+   #@@@#%@@@@@@ *@@@@--%@@@+ %@@@%=-=+-  #@@@@@@@@%.  [email protected]@@@++++ *@@@%+++=-       //
//       @@@@-:@@@@*  #@@@+ *@@@@@  #@@@@@@@@#  .*@@@@@@@@*.#@@@*.%@@@%. [email protected]@@@@@@@.*@@@@@@@@%       //
//       ++++: :++++- =+++-  -++++   :+#%%#+:     .=*#%%#+- =+++-  +++++ :++++++++.-+++++++++       //
//       ******   :*****- +************-      .******=      .*********=:      ***************       //
//       @@@@@@   [email protected]@@@@+ #@@@@@@@@@@@@+      %@@@@@@@:     :@@@@@@@@@@@@*.   @@@@@@@@@@@@@@%       //
//       @@@@@@   [email protected]@@@@+ #@@@@@@@@@@@@+     [email protected]@@@@@@@%     :@@@@@@@@@@@@@@=  @@@@@@@@@@@@@@#       //
//       @@@@@@***%@@@@@+ #@@@@@+====       [email protected]@@@@@@@@@+    :@@@@@%:[email protected]@@@@@- ::::-#@@@@@@@=        //
//       @@@@@@@@@@@@@@@+ #@@@@@@@@@@.      %@@@@@%@@@@@:   :@@@@@#   :@@@@@#    .#@@@@@@#.         //
//       @@@@@@@@@@@@@@@+ #@@@@@@@@@@.     [email protected]@@@@#[email protected]@@@@%   :@@@@@#   [email protected]@@@@*   [email protected]@@@@@@-           //
//       @@@@@@---*@@@@@+ #@@@@@+------.  [email protected]@@@@@@@@@@@@@+  :@@@@@@+*%@@@@@@. :%@@@@@@@#****+       //
//       @@@@@@   [email protected]@@@@+ #@@@@@@@@@@@@+  #@@@@@@@@@@@@@@@: :@@@@@@@@@@@@@%:  @@@@@@@@@@@@@@%       //
//       @@@@@@   [email protected]@@@@+ #@@@@@@@@@@@@+ [email protected]@@@@%::::[email protected]@@@@% :@@@@@@@@@@@#-    @@@@@@@@@@@@@@%       //
//       ------   .-----: :------------: ------.     ------. --------:.       ---------------       //
//       =++++++.=++   -++. .=+*+-  .++.    =+-  .++. :=+++-  -+= ++=    -++ =++++++. .=+*+-        //
//       %@%****  *@@-#@%: #@@*+#@@-:@@:    %@*  :@@:[email protected]@**#%: [email protected]@ [email protected]@=  [email protected]@= %@%****.:@@**#@-       //
//       %@@%%%+   [email protected]@@*  [email protected]@    .. :@@:    %@*  :@@::@@@%#+. [email protected]@  [email protected]@-:@@+  %@@%%%+ .%@@%#+.       //
//       %@%===-  .#@@@@- [email protected]@=  .++::@@-    #@%  [email protected]@. ==-=%@@ [email protected]@   [email protected]@@@*   %@%===-  -=-=#@@       //
//       %@@@@@@[email protected]@* [email protected]@* -#@@@@@+.:@@@@@@*.#@@@@%- -%@@@@@+ [email protected]@    [email protected]@#    %@@@@@@::#@@@@@*       //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract KHZA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}