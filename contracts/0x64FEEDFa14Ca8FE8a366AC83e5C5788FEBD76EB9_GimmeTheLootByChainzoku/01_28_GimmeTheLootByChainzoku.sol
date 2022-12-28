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

import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleProof.sol";
import "./ERC1155MultiSupplies.sol";
import "./MultiMint.sol";
import "./Initialize.sol";
import "./ShareProxy.sol";

// @author: miinded.com

contract GimmeTheLootByChainzoku is Initialize, ERC1155Multi, MultiMint, MerkleProofVerify, ShareProxy {
    using Strings for uint256;

    mapping(uint256 => uint256) public burnThemAllStart;

    constructor(string memory baseURI) ERC1155(baseURI) {}

    function init(uint256 _id, Supply memory _supply, address _multiSigContract, address _shareContract) public onlyOwner isNotInitialized {
        MultiSigProxy._setMultiSigContract(_multiSigContract);
        ShareProxy._setShareContract(_shareContract);
        ERC1155Multi._setSupply(_id, _supply);
    }

    function GimmeTheBox(bytes32[] memory _proof, uint256 _id, uint256 _count, uint256 _max)
        public
        payable
        merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), _id, _max)))
        notSoldOut(_id, uint64(_count))
        canMint(string.concat("BOX_", _id.toString()), uint64(_count))
        nonReentrant
    {
        require(mintBalance(string.concat("BOX_", _id.toString()), _msgSender()) <= _max, "Stop! You have already minted too many boxes!");

        _mintTokens(_msgSender(), _id, uint64(_count));
    }

    function GimmeTheLoot(uint256 _id, uint64 _count) public {
        require(burnThemAllStart[_id] > 0 && block.timestamp >= burnThemAllStart[_id], "No, you can't open it now!");
        burn(_id, _count);
    }

    function BurnThemAll(uint256 _id, uint256 _burnThemAllStart) public onlyOwnerOrAdmins {
        burnThemAllStart[_id] = _burnThemAllStart;
    }

    function ToTheVault(uint256 _id) public onlyOwnerOrAdmins {
        uint256 count = supplies[_id].max - supplies[_id].minted;
        require(mintIsOpen(string.concat("BOX_", _id.toString())) == false, "Mhh, it's not the right time");
        require(count > 0, "There are no boxes left");

        _mintTokens(_msgSender(), _id, uint64(count));
    }

    receive() external payable {}
}