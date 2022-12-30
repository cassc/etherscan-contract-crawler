// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - CTO, Virtue Labs

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//
//                                                 :==-
//                                              .:[email protected]@@@=:.
//                                              &@@@@@@@@@=
//                                  .:         [email protected]@@@@@@@@@=         :.
//                              .-+%@@+  :.+-##%@@@@@@@@@@@#%**-.: [email protected]@@*=.
//                              #@@@@@@*@%@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@%.
//                    .        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@+.        :
//                  [email protected]@#:   .:*@@@@@@%@@%@@#*+=%@@@@@@@@@@@+=+#@@@@@@@@@@@@*-    :#@@+
//               [email protected]@@@@@*-*@@@@@@@%++##%*   :[email protected]@@@@@@@@@@@*-:  =#%%++*@@@@@@%*=#@@@@@@+.
//              :@@@@@@@@@@@@@@@@@@* [email protected]*  [email protected]@@@@@@@@@@@@@@@#  :%*:- [email protected]@@@@@@@@@@@@@@@@@:
//                [email protected]@@@@@%%@@@@@*-     .-:   :[email protected]@@@@@@%@@@@*-:  .-.     -*@@@@@@@@@@@@@+
//                  #@@@@@@%@@@#++:            %@@@@@@@%%@@:           :+*%@@@@@@@@@@+.
//                 =#@@@@@@@@@@@@@+          :#%@@@@@@@@@%%%-          [email protected]@@@@@@@@@@@@@=.
//               [email protected]@@@@@@@@@@@@@@@#---.    [email protected]%%@@@@@@@@@@%%@#:    .===#@@@@@@@@@@@@@@@#=
//         .+:  =%@@@@@@%[email protected]@@@@@@@%**@+   -: [email protected]@%%@@@@@@@@@@+ .:   [email protected]@#%@@@@@@@@#@@@@@@@@=  -+-
//        .%@@@@@@@@@@@+  #@@@@@@+   &@+--    #@@@%@@@@%@@@@.   :[email protected]@:  *@@@@@@@  *@@@@@@%%@@@@=
//       .%@@@@@@@@%@@-   *@@@@@@@[email protected]@@@=    #@@@@@%%@@@@@@.   -%@@@#[email protected]@@@@@@%   [email protected]@=#@@@@@@@@+
//       =#@@@@@@@-:@=      ....#@@#+++%@@%-:[email protected]@@@%%%%%%%%%%*+=%@@%[email protected]@@-...      [email protected]: &@@@@@@#+
//          +*@@@#*@%%%.       .%@#     .%@@@@@@%%###*#**##%*#%@@-     [email protected]@-       -%@@@##@@@@#.
//          =%@@@@@%     -####*@@@%:    [email protected]@%@@%%%@@@@@@@@#*==***#=    .%@@@####*:  .  #@@@@@@%.
//          .#@@@@@@:   .*%%@%#%%@@@@*:-#@@@@@@@@@@@@@@@@@@@@%*+*###=:*@@@@@%%@%%#+    [email protected]@@@@@@*
//         [email protected]@@@@@*   -%%@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-+%@@@@@@@%@@@@@@##-   [email protected]@@@@@@-
//        :*@@@@@@@##%%@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@%@@@@@%@@@@@=+%@@@@%%@@@@@@@@@%###@@@@@@@@+
//     -+*#@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@%=#@%@@@@@@@@@@@@@@@%@@@@@@@@@@#+=
//  -%%@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@%%@@@@@@%@@@@@%+
//  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@%%@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@#
//  :%%@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@%#%%%@@%@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*
//      .-*@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@%@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-..
//        :*@@@@@@%##@@@@@@@@@@@@@@=:%@@@@@@@%%%%%@@%%@@@@@@@@@@@@@@%.-%@@@@@@@@@@@@@%%@@@@@@@@#
//        [email protected]@@@@@:  .#%%@@@@@@@@*   :@@@@@@@@%%@@@@%%@@@@@@@@@@@@@@.   [email protected]%%@@@@@%@%-  [email protected]@@@@@@:
//        :*@@@@@#    =%%%@%%@%:  :#@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@%=   .*@%@@@@@=    #@@@@@@+
//         .=%@@@#+##%#  [email protected]%%%-   *@@#--*@@@@@@@@@@@@@@@@@@@@@@@@*=#@@%:   :%@@@+  #@%%@@@@@@@-
//          [email protected]@@:.**     .::     #@-   :%@@@@@@@@@@@@@@@@@@@@@@-   .*@.     ::.     *%[email protected]@@@=
//        :+#@@@@% #@:            #+  .*@@#[email protected]@@@@@@@@@@@@@%*[email protected]@+.   *:             %@.#@@@@@*=:
//       [email protected]@@@@@@@@@@@:   =##***%@@%##@@#:    *@@@@@@@@@@@@@    [email protected]@=.:*@@@#*###*   .%@@@@@@@@@@@%.
//        *@@@@@@@@@@@@=  *@@@@@@#--*@@*      *@@@@@@@@@@@@@     .#@@%+*@@@@@@@@  :@@@@@@@@@@@@@.
//         *#+-:=#@@@@@@**@@@@@@@+  [email protected]# ::    *@@@%@@@@%@@@@    .. *@:  [email protected]@@@@@@#*@@@@@@@#--+##.
//               [email protected]@@@@@@@@@@@@@@*+%@+   ::  [email protected]@%@@@@@@#%@%  ..   [email protected]@**@@@@@@@@@@@@@@@@*
//                .+%@@@@@@@@@@@@#::::.     -+%%@@@@@@@@@%#%*-      ::::[email protected]@@@@@@@@@@@@@=
//                  %@%@@@@@@@@@%=          [email protected]%@@@@@@@@@@@%%@:          .%@@@@@@@@@@@@:
//                -.%@@@@@@@@@@@+:           .#@%@@@@@@@@@@#            [email protected]@@@@@@@@@@@.-.
//              [email protected]@@@@@@@@@@@@@@@@@+ : :%*  -%%@@@%@@@@@@@@@#=  [email protected]* . -#@@@@@@@@@@@@@@@@@:
//                [email protected]@@@@%= +#%@@@@@= =%%@#  :#%@@@@@@@@@@@@%*-  [email protected]@@=  %@@@@@%*[email protected]@@@@@*.
//                  [email protected]@*     -**@@@%@@@@@@@@#+*@@@@@@@@@@@@%**%@@@@@@%@@@@%%-.    [email protected]@+.
//                              :%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:        .
//                               :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//                              [email protected]@@@@@:=-+%*@%@@@@@@@@@@@@@@%##=*:%@@@@@#.
//                                :=#%:      [email protected]@@@@@@@@@# :       ##=:
//                                              *@@@@@@@@@=
//                                              **#@@@@##*:
//                                                 #@@@
//

contract IngredientGrabber is Ownable {
    // ICanSeesU

    bool public boksIzOpen = true;

    enum WenEggHatch {
        HatchMeOussideHowBouDah,
        YuKneedMoarFhood,
        DidDisAlredi
    }

    WenEggHatch public wenItzRedi = WenEggHatch.HatchMeOussideHowBouDah;

    mapping(address => bool) public sunniSiedUpp;

    uint256 public ordurzTakenn;

    //////////

    mapping(uint256 => uint256) public izitsOrIzontitzs;
    CrudeBorneEggs public eggzzz;

    ERC721StorageLayerProto public pantreeDhoor;

    //////////

    /*************************************************************************/
    /*** PAYMENT VARIABLES (Start) *******************************************/
    address[] public based;
    mapping(address => uint256) private howBased;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    modifier onlyBased() {
        _isBased();
        _;
    }
    function _isBased() internal view virtual {
        require(howBased[msg.sender] > 0, "not based");
    }
    /*** PAYMENT VARIABLES (End) *******************************************/
    /***********************************************************************/

    constructor(
        address cbeAddy_,
        address storageLayer_,
        address[] memory based_,
        uint256[] memory howBased_
    ) {
        eggzzz = CrudeBorneEggs(cbeAddy_);
        pantreeDhoor = ERC721StorageLayerProto(storageLayer_);
        pantreeDhoor.registerMintingContract();

        for (uint256 i = 0; i < based_.length; i++) {
            howBased[based_[i]] = howBased_[i];
        }
        based = based_;
    }

    /*********************************************************************/
    /*** PAYMENT LOGIC (Start) *******************************************/
    receive() external payable {
        totalReceived += msg.value;
    }

    function withdraw() public onlyBased {
        uint256 respects = (totalReceived/10000)*howBased[msg.sender];
        uint256 toPay = respects - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = respects;
        (bool press, ) = payable(msg.sender).call{value: toPay}("");
        require(press, "F");
    }

    function withdrawTokens(address tokenAddress) external onlyBased {
        for (uint256 i = 0; i < based.length; i++) {
            IERC20(tokenAddress).transfer(
                based[i],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*howBased[based[i]]
            );
        }
    }

    function emergencyWithdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/

    //////////

    function piknikTiemz() public onlyOwner {
        boksIzOpen = !boksIzOpen;
    }

    function invitoooor(address eggBoksz) public onlyOwner {
        sunniSiedUpp[eggBoksz] = true;
    }

    function tellMiWennDammit(WenEggHatch wennn) public onlyOwner {
        require(wennn != WenEggHatch.HatchMeOussideHowBouDah && wenItzRedi != WenEggHatch.DidDisAlredi);
        wenItzRedi = wennn;
    }

    //////////

    function piknikInvitayshun(uint256 whichEgg) public view returns (bool) {
        uint256 eggBlocc = whichEgg/250;
        uint256 eggSlot = whichEgg - eggBlocc*250;
        return ((izitsOrIzontitzs[eggBlocc] >> eggSlot)%2 == 1);
    }

    function pikanikBaskitz(uint256[] memory eggz) public {
        require(boksIzOpen, 'bio');
        require(wenItzRedi == WenEggHatch.YuKneedMoarFhood || (sunniSiedUpp[msg.sender] && (wenItzRedi == WenEggHatch.HatchMeOussideHowBouDah)), 'ms/a');

        uint256 curBlocc = 0;
        uint256 bloccUpdates = 0;
        uint256 eggBlocc;

        bool fukGroseriz = true;
        bool inDaLibrary = true;

        for (uint256 i = 0; i < eggz.length; i++) {
            eggBlocc = eggz[i]/250;
            if (eggBlocc != curBlocc) {
                izitsOrIzontitzs[curBlocc] = izitsOrIzontitzs[curBlocc] | bloccUpdates;
                curBlocc = eggBlocc;
                bloccUpdates = 0;
            }

            uint256 eggSlot = eggz[i] - curBlocc*250;
            fukGroseriz = fukGroseriz && (izitsOrIzontitzs[curBlocc] >> eggSlot)%2 == 0;
            inDaLibrary = inDaLibrary && eggzzz.ownerOf(eggz[i]) == msg.sender;

            bloccUpdates += (1 << eggSlot);
        }
        require(fukGroseriz && inDaLibrary, 'f;i');

        izitsOrIzontitzs[curBlocc] = izitsOrIzontitzs[curBlocc] | bloccUpdates;

        pantreeDhoor.storage_safeMint(msg.sender, msg.sender, eggz.length);

        ordurzTakenn += eggz.length;
    }
}

////////////////////

abstract contract CrudeBorneEggs {
    function balanceOf(address owner) public view virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract ERC721StorageLayerProto {
    function registerMintingContract() public virtual;
    function storage_safeMint(address msgSender, address to, uint256 quantity) public virtual;
}

////////////////////////////////////////