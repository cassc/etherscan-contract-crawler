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

import "./libs/ERC1155Proxy.sol";
import "./libs/Initialize.sol";

contract ZokuHomeByChainZoku is Initialize, ERC1155Proxy {

    constructor(string memory baseURI) ERC1155Proxy(baseURI){}

    function init(address _chainzokuCartManager, address _multiSigContract) public onlyOwner isNotInitialized {
        MultiSigProxy._setMultiSigContract(_multiSigContract);
        ExternalContracts._setExternalContract(_chainzokuCartManager, true);
    }
}