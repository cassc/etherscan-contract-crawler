// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - CTO, Virtue Labs

pragma solidity ^0.8.17;

//
//                                                  .:
//                                                   .
//                                                  .==+
//                                                  .=#%.
//                                                . .*#*=
//                                            -   =:-*%#*
//                                           :#- :+#%%@@%.
//                                           =#%+##%%#%%%++
//                                           =%%#%%%%%@%%%%
//                                          :-###%%%@%@%%@%*+:
//          .                              -+*#*######%##%@@@%  .
//       . =##:                  .::-: .:. +**#*#*##%%####%%%##*%#*= :.-.:
//       :+%%@%=               .-+************###%%%%%%%#%%%%%%%@@@%#####%#*
//      -##%%@@@% .          -#######*%###%####%%@%@@%%%%%%%%%@@@@@@@@@@%%@@%=*.
//     .*%%@@@@@@%##+##*##==*##%%#####%@%%####%%%%%@%####%%%%%@@@@%%%%%%%@@@@@@@%#*+--.
//     .##%%%#%#%%%@%%@@%%%@@@@%%%#**############%%%%%%%@%%%%%%%%%%%##%%%%%@@@@@@%%@@@@%#**=+.
//  .--*#%%%%%#***###%%@@@@@%%%%%%%%#########%%%@@@%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-
//  #@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@%%%%%%%%@@@@@@@@@@%@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:
//   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    .+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=:.
//       :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+-
//          .=*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+==:.
//              --=*-::..-+#*%@@@@@@@@#=-*%@@%*%@@@@@@@@@@@@@@%*###*=-: :
//                            .--=#%%#-             .-=--=-.
//

import "./ERC721TopLevel.sol";

contract Ingredient is ERC721TopLevel {
    bytes32 public solvesyWordz;
    uint256 private howManyWordz;

    string private _notSolveddd = "";
    string private _ooooShinyy = "";

    mapping(address => bool) public isRevealed;

    constructor(
        address werIzDaInfo,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_
    ) ERC721TopLevel() {
        ERC721StorageProto(werIzDaInfo).registerTopLevel(name_, symbol_, description_, image_);

        setStorageLayer(werIzDaInfo);
    }

    //////////

    function setSolutionHash(bytes32 wotWurdz_, uint256 howManyyy_) public onlyOwner {
        solvesyWordz = wotWurdz_;
        howManyWordz = howManyyy_;
    }

    function youreekcar(string[] memory whoaa) public {
        require(howManyWordz > 0, "nw0");
        require(whoaa.length == howManyWordz, "nw");
        bytes32 amIRiteOrWut = keccak256(abi.encodePacked("eggzzz"));
        for (uint256 i = 0; i < whoaa.length; i++) {
            amIRiteOrWut = keccak256(abi.encodePacked(amIRiteOrWut, whoaa[i]));
        }
        require(amIRiteOrWut == solvesyWordz, "sln");

        isRevealed[msg.sender] = true;
    }

    function hmmmHmmmmm(string memory hmmm___) public onlyOwner {
        _notSolveddd = hmmm___;
    }

    function AHA(string memory ahhh___) public onlyOwner {
        _ooooShinyy = ahhh___;
    }

    //////////

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (isRevealed[ownerOf(tokenId)]) {
            return _ooooShinyy;
        }
        else {
            return _notSolveddd;
        }
    }

    //////////

    function urBlocced(address whomst) public onlyOwner {
        _restrictOperator(whomst);
    }

    function unbloccc(address whomst) public onlyOwner {
        _releaseOperator(whomst);
    }

    function noMoarBlok() public onlyOwner {
        _preventNewRestrictions();
    }
}

////////////////////////////////////////