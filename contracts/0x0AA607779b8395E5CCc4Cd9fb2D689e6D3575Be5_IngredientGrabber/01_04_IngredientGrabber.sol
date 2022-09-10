// SPDX-License-Identifier: Unlicense
// Creator: Mr. Masterchef

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**********************************************************************************/
/*   ______   _______  _______  _______ _________    _________          _______   */
/*  (  ___ \ (  ___  )(  ___  )(  ____ \\__   __/    \__   __/|\     /|(  ____ \  */
/*  | (   ) )| (   ) || (   ) || (    \/   ) (          ) (   | )   ( || (    \/  */
/*  | (__/ / | |   | || |   | || (_____    | |          | |   | (___) || (__      */
/*  |  __ (  | |   | || |   | |(_____  )   | |          | |   |  ___  ||  __)     */
/*  | (  \ \ | |   | || |   | |      ) |   | |          | |   | (   ) || (        */
/*  | )___) )| (___) || (___) |/\____) |   | |          | |   | )   ( || (____/\  */
/*  |/ \___/ (_______)(_______)\_______)   )_(          )_(   |/     \|(_______/  */
/*                                                                                */
/*              _______ _________ _______  _        _______  _                    */
/*             (  ____ \\__   __/(  ____ \( (    /|(  ___  )( \                   */
/*             | (    \/   ) (   | (    \/|  \  ( || (   ) || (                   */
/*             | (_____    | |   | |      |   \ | || (___) || |                   */
/*             (_____  )   | |   | | ____ | (\ \) ||  ___  || |                   */
/*                   ) |   | |   | | \_  )| | \   || (   ) || |                   */
/*             /\____) |___) (___| (___) || )  \  || )   ( || (____/\             */
/*             \_______)\_______/(_______)|/    )_)|/     \|(_______/             */
/**********************************************************************************/

contract IngredientGrabber is Ownable {
    bool public portalFlow = true;

    enum ArWiDerYett {
        ISwearToGodIWillTurnThisCarAround,
        AllDaPeeps,
        AlrediDer
    }

    ArWiDerYett public spotInJurKnee = ArWiDerYett.ISwearToGodIWillTurnThisCarAround;

    mapping(address => bool) public chefsHat;

    uint256 public howMuchSoFar;

    //////////

    mapping(uint256 => uint256) public deyWatchinUuu;
    CrudeBorneEggs public eggzzz;

    ERC721StorageLayerProto public werzDaBookz;

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
        werzDaBookz = ERC721StorageLayerProto(storageLayer_);
        werzDaBookz.registerMintingContract();

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

    function deyCanSeesUuuu() public onlyBased {
        uint256 respects = (totalReceived/10000)*howBased[msg.sender];
        uint256 toPay = respects - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = respects;
        (bool press, ) = payable(msg.sender).call{value: toPay}("");
        require(press, "F");
    }

    function modsAsleepQuickPostSinks(address wotSinks) external onlyBased {
        for (uint256 i = 0; i < based.length; i++) {
            IERC20(wotSinks).transfer(
                based[i],
                (IERC20(wotSinks).balanceOf(address(this))/10000)*howBased[based[i]]
            );
        }
    }

    function daWitchIzDed(address unfathomablyBased) external onlyOwner {
        IERC20(unfathomablyBased).transfer(msg.sender, IERC20(unfathomablyBased).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/

    //////////

    function fryersOn() public onlyOwner {
        portalFlow = !portalFlow;
    }

    function openKitchen(address whoGetzDaKey) public onlyOwner {
        chefsHat[whoGetzDaKey] = true;
    }

    function arYuTravln(ArWiDerYett newSpott) public onlyOwner {
        require(newSpott != ArWiDerYett.ISwearToGodIWillTurnThisCarAround && spotInJurKnee != ArWiDerYett.AlrediDer);
        spotInJurKnee = newSpott;
    }

    //////////

    function harambeIsStillAlive(uint256 whichEgg) public view returns (bool) {
        uint256 eggBlocc = whichEgg/250;
        uint256 eggSlot = whichEgg - eggBlocc*250;
        return ((deyWatchinUuu[eggBlocc] >> eggSlot)%2 == 1);
    }

    function groseriRun(uint256[] memory eggz) public {
        require(portalFlow, 'pf');
        require(spotInJurKnee == ArWiDerYett.AllDaPeeps || (chefsHat[msg.sender] && (spotInJurKnee == ArWiDerYett.ISwearToGodIWillTurnThisCarAround)), 'ms/a');

        uint256 curBlocc = 0;
        uint256 bloccUpdates = 0;
        uint256 eggBlocc;

        bool fukGroseriz = true;
        bool inDaLibrary = true;

        for (uint256 i = 0; i < eggz.length; i++) {
            eggBlocc = eggz[i]/250;
            if (eggBlocc != curBlocc) {
                deyWatchinUuu[curBlocc] = deyWatchinUuu[curBlocc] | bloccUpdates;
                curBlocc = eggBlocc;
                bloccUpdates = 0;
            }

            uint256 eggSlot = eggz[i] - curBlocc*250;
            fukGroseriz = fukGroseriz && (deyWatchinUuu[curBlocc] >> eggSlot)%2 == 0;
            inDaLibrary = inDaLibrary && eggzzz.ownerOf(eggz[i]) == msg.sender;

            bloccUpdates += (1 << eggSlot);
        }
        require(fukGroseriz && inDaLibrary, 'f;i');

        deyWatchinUuu[curBlocc] = deyWatchinUuu[curBlocc] | bloccUpdates;

        werzDaBookz.storage_safeMint(msg.sender, msg.sender, eggz.length);

        howMuchSoFar += eggz.length;
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