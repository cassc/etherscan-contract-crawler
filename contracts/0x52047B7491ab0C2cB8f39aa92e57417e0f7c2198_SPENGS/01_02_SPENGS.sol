// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Sappy Penguins
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                  ........       .....      .........     .........      ...    ...               //
//               ..::.....::..   .:-:.:-..   .--:.....::.  :--:.....-:..   ---.   ---.              //
//               :--:      ..  .:::.   .:::. .--:     :--. :--.     ---.   ---.   ---.              //
//                 :-:::::::   :--:     :--. .--:     :--. :--.     ---.    .-::::-:                //
//                        :-:. :--:::::::--. .--::::::::   :--:::::::.        .--:                  //
//               ::--     :::. :--:     :--. .--:          :--.               .--:                  //
//                 .::::::::   .::.     :::. .::.          .::.               .::.                  //
//                                                                                                  //
//       ::.                                                                                        //
//      *@@@@%+. =*#%%@*  -*#=   :+*#.   -+***+=.  .-==    .+*##. =++.  -*#=   :+*#.  .=*#*+-       //
//      *@@+:#@% #@@@%*=  [email protected]@@*  [email protected]@@=  %@%=-=%@@- *@@@:   [email protected]@@@:[email protected]@@*  [email protected]@@*  *@@@= [email protected]@%=+%@%.     //
//      [email protected]@%#@%@ [email protected]@@.    [email protected]@@@# [email protected]@@= :@@-   =##= [email protected]@@-   *@@@@. %@@#  :@@@@# [email protected]@@+ [email protected]@%.  .       //
//      :@@@@#+. [email protected]@@@@#   *@@@@##@@@+ [email protected]@: =++++.  %@@=   #@@@%  #@@%   #@@@@##@@@*  :#@@+.        //
//      [email protected]@@%    :@@@%-    :@@@@@@@@@+ [email protected]@- -#@@@=  [email protected]@+  [email protected]@@@:  *@@@   [email protected]@@@@@@@@*    -#@@+       //
//      [email protected]@@+    [email protected]@@%==.   %@@#[email protected]@@@+ [email protected]@#..#@@@-   #@%*%@@@@=   [email protected]@@-   @@@#[email protected]@@@* .%@* [email protected]@-      //
//       %@@:     %@@@%#:   [email protected]@* [email protected]@@=  [email protected]@@@@@@#     +%@@@%*:    [email protected]@@%   *@@* [email protected]@@+  *@@%%@#.      //
//                 .        .==:  .::    .=+**+-                   -==:   .=+:  .:.     .::.        //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

contract SPENGS is ERC721Community {
    constructor() ERC721Community("Sappy Penguins", "SPENGS", 4444, 44, START_FROM_ONE, "ipfs://bafybeihe4zm2tb2ticp3gqyoyqgboxbqnuhzeexqefrq5ogq6zt5qvb4ye/",
                                  MintConfig(0.04 ether, 4, 4, 0, 0x972eCED4d31837e4a9ae1C26008c8C988E411cDe, false, false, false)) {}
}