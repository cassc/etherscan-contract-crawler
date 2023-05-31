////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                 ....                                                                                   //
//                         .-+#%- [email protected]@@%=:=-.                                  :-.:-===-:-**=-: -=.   .                    //
//                     -=:.#@@@* [email protected]@@@: [email protected]@@%+  -.              .::-+=:-::-+#@[email protected]@@@@@@@= #@@@[email protected]@*-  *#=. :              //
//                .-+%@@@@:[email protected]@@* *@@@@  @@@@@@: [email protected]%*+=--*+==: [email protected]@@@[email protected]@@@@@@*[email protected]@@@*[email protected]@@@[email protected]@@@[email protected]@@%-:@@@@*:%*-.          //
//             :#@@@@@@@@# %@@@# [email protected]@@%  @@@@@@%  @@@@+  [email protected]@@:  [email protected]@@*:@@%@@@@% *@@@*  #@@@.:@@@%[email protected]@@: %@@@#  [email protected]@@@*:       //
//            [email protected]@@@#::@@% [email protected]@@@#*@@@@- :@@%@@@@: @@@@*  #@@@+ [email protected]@@@.#*:[email protected]@@# [email protected]@@@- :@@@*.%@@@@@@@%  #@@@=  #@@@%         //
//            %@@@*  @@*[email protected]@@@@@@@@@= [email protected]@@+%@@@ :@@@@+ :@@@@@.%@@@-:.  @@@% [email protected]@@@* .%@@% #@@@@@@#-  [email protected]@@@: :@@@@@         //
//           [email protected]@@@: -:   [email protected]@@#-%@@@= [email protected]@@@.%@@= #@@@@: #@@@@@%%@@#    *@@@= [email protected]@@%  %@@@= @@@@@@@@# [email protected]@@%  [email protected]@@@@*         //
//           [email protected]@@@: :=+=.:@@@+ %@@@  @@@@%[email protected]@@: @@@@@. #@@@@@@@@@-  :%@@@*  .%@@%  @@@@# %@@@*@@@@[email protected]@@#  #@@@@%          //
//          [email protected]@@@% .*@@@*[email protected]@@# [email protected]@@. *@@@*%@@@* [email protected]@@@* [email protected]@@%@@@@@= [email protected]@@@=  [email protected]@@* [email protected]@@% #@@@[email protected]@@# %@@@= [email protected]@@@*          //
//          *@@@@: [email protected]@@%.*@@@: [email protected]@@* .*@@# :@@@= *@@@@. #@@=*@@@@@ *@@%..-#@[email protected]@@#.*@@@::@@@@ :@@@@ *@@@%  *@@@@:         //
//          @@@@+ :@@@% [email protected]@@*:.+#%@@[email protected]@@@[email protected]@* [email protected]@@%  *@@% *@@@@-%@@@@@@@@*.%@@@@@@%:[email protected]@@@%  @@@@:[email protected]@@@. :@@@@#         //
//         :@@@@%%@@@@[email protected]*:        :=-.:=+=:%@@- @@@@- [email protected]@@@: %@@@-#@@@@@@@@*  -+**=: .---+#@*-%@@@* #@@@%[email protected]@@@%         //
//         #@@@@@@@@%=  -                 :-=+#+.:.=%+ *@@@#  *@@@..+-:::.                  [email protected]@- [email protected]@@@@@@@@@         //
//        [email protected]@%#*+=:                                  :: :*@* :%@@@#.                               -+-. :+#%@@@@@*        //
//       ..                                                ..   ..::.                                         ..:-:       //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libs/ERC721AProxy.sol";
import "./libs/Initialize.sol";

// @author: miinded.com

contract ZokusByChainZoku is ERC721AProxy, Initialize {

    constructor()
    ERC721AProxy("ZokusByChainZoku", "ZOKUS"){}

    function init(string memory baseURI, address _chainzokuManager, address _multiSigContract) public onlyOwner isNotInitialized {
        ERC721AProxy._setManager(_chainzokuManager);
        ERC721AProxy.setBaseUri(baseURI);
        MultiSigProxy._setMultiSigContract(_multiSigContract);
    }

}