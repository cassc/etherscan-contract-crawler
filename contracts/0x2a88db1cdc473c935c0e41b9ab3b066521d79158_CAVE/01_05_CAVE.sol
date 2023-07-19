// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enter The Cave
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                    :-.=.::===-.==.             .                                                                               //
//                    =#[email protected]**+.#*.#*[email protected]             :                                                                               //
//                    =#-#%%+ #* #[email protected]            :    .=*##+-:                                                                    //
//                    =#-#[email protected]+ #* #[email protected]            :  .*@@@*:  -#:                                                                  //
//                    :=.= =- -- .++:            : [email protected]@@@-  :#@@@*       :                                                         //
//                    -*******= **=  -**.:******#  #@@@-  [email protected]@@%--+      : .::-*##+:   :***+  **=   -*+ +******:                   //
//                    :++%@@[email protected]@*  [email protected]@:[email protected]@#+++*  @@@#  :@@@*   *     .:.-.  *+*@@=  [email protected]@@@  %@%   %@* %@@++++:                   //
//                       #@@   [email protected]@*  [email protected]@:[email protected]@-   : [email protected]@@-  #@@@    %        =: --  @@*  %@*@@- [email protected]@. [email protected]@- %@%                        //
//                       #@@   [email protected]@*  [email protected]@:[email protected]@=... : @@@:  %@@#   :%        . .%=  ::. :@@[email protected]@# :@@= [email protected]@  %@%...                     //
//                       #@@   [email protected]@@@@@@@:[email protected]@@@@@ - @@@-  #@@@   .+         [email protected]@=      [email protected]% *@@  @@# *@#  %@@@@@+                    //
//                       #@@   [email protected]@#::[email protected]@:[email protected]@=... : #@@*  [email protected]@@=  +       [email protected]@=  --: %@+ [email protected]@- *@@ @@=  %@%...                     //
//                       #@@   [email protected]@*  [email protected]@:[email protected]@-     [email protected]@@:  *@@@++.      :  -:@@=  %@*:@@@%@@@* :@@*@@.  %@%                        //
//                       #@@   [email protected]@*  [email protected]@:[email protected]@*==== : #@@@.  [email protected]@#       :.  +:@@#[email protected]@[email protected]@:::%@@  @@@@%   %@@====.                   //
//                       +%%   .%%+  -%%::%%%%%%% .. #@@@= :=:      .:   .=:=+%@%#= *%+   -%%: +%%%=   *%%%%%%-                   //
//                                                 :. .-=-:     .::.   .:::.-:-                                                   //
//                                                  .:      ....   ::--:--..  :.                                                  //
//                                                  :-=:-=:.  ..:---:...       -                                                  //
//                                                   - .-- .  :.:               ....                                              //
//                                                    -. =-: .:=-          ...       ....                                         //
//                                                  ..=+.- +=  .-.     ....              ....                                     //
//                                               .::  ..  [email protected]+.::                                                                 //
//                                              . :        =+                                                                     //
//                                             :  :        #=                                                                     //
//                                             .           =-                                                                     //
//                                                          :                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CAVE is ERC1155Creator {
    constructor() ERC1155Creator("Enter The Cave", "CAVE") {}
}