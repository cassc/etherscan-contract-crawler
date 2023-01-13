// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                .----:     :--:     :--:    :------:    :----.     :----:     :----.     :--:   .---:     :---.            //
//                #@@@@%     *@@@-    [email protected]@#  :%@@@@@@@@%-  *@@@@#     %@@@@+    [email protected]@@@@#     #@@*    #@@%.   [email protected]@@#             //
//               :@@@%@@=    *@@@@-   [email protected]@#  %@@%=--=#@@%  *@@@@@-   [email protected]@@@@+    [email protected]@%@@@:    #@@*    .%@@#   #@@%.             //
//               *@@*[email protected]@%    *@@@@@:  [email protected]@#  @@@=    [email protected]@@. *@@*%@#   %@##@@+    %@@=*@@*    #@@*     :@@@= [email protected]@@:              //
//              [email protected]@@:[email protected]@@-   *@@%@@%: [email protected]@#  @@@=    [email protected]@@. *@@*[email protected]@- [email protected]@-#@@+   [email protected]@% :@@@.   #@@*      [email protected]@@[email protected]@@-               //
//              *@@#  [email protected]@#   *@@#:@@%[email protected]@#  @@@=    [email protected]@@. *@@* %@%.%@# #@@+   #@@+  #@@+   #@@*       [email protected]@@@@=                //
//             [email protected]@@-  [email protected]@@:  *@@# [email protected]@%*@@#  @@@=    [email protected]@@. *@@* [email protected]@#@@: #@@+  [email protected]@@.  [email protected]@@.  #@@*        #@@@*                 //
//             [email protected]@@%#  #@@*  *@@#  [email protected]@@@@#  @@@=    [email protected]@@. *@@*  #@@@*  #@@+  #@@@%+  %@@=  #@@*        :@@@:                 //
//             %@@#**. [email protected]@@: *@@#   [email protected]@@@#  @@@*    [email protected]@@. *@@*  :+++.  #@@+ :@@@##*  [email protected]@%  #@@*        :@@@:                 //
//            [email protected]@@.     %@@* *@@#    [email protected]@@#  [email protected]@@@@@@@@@*  *@@*         #@@+ *@@%     [email protected]@@= #@@@@@@@@@: :@@@:                 //
//            *##+      -### =##+     +##*   :+######*-   +##+         +##= ###-      +##* *#########: :###.                 //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./MiindedERC721.sol";

// @author: miinded.com

contract AnomalyGenesis is MiindedERC721 {

    constructor() ERC721("Anomaly Genesis", "ANOMALY") {}

    function WhitelistMint(bytes32[] memory _proof, string memory _name, uint256 _count, uint256 _max)
    public payable notSoldOut(_count) canMint(_name, _count) merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), _name, _max))) nonReentrant {
        require(mintBalance(_name, _msgSender()) <= _max, "Max minted");

        _mintTokens(_msgSender(), _count);
    }
}