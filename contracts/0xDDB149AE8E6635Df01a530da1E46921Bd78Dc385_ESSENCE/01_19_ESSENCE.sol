// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: FVCKRENDER
/// @title: ESSENCE//
/// @author: manifold.xyz

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                   ______ _____ _____  ______ _   __ ______ ______    __  ___             //
//                  / ____// ___// ___/ / ____// | / // ____// ____/  _/_/_/_/              //
//                 / __/   \__ \ \__ \ / __/  /  |/ // /    / __/   _/_/_/_/                //
//                / /___  ___/ /___/ // /___ / /|  // /___ / /___ _/_/_/_/                  //
//               /_____/ /____//____//_____//_/ |_/ \____//_____//_/ /_/                    //
//                                                                                          //
//                                                                                          //
//                                                                ,*69.                     //
//                                                             ,**.*@@@.                    //
//                                                   %.#/.,/ /,/((/@@@@,     @@@.           //
//                                     ,(@@@@#&/,,@@/(%(& (@@%@&/##@@@..  /%@*@*,.          //
//                               #@.&@@@#@@@@@@%#@@.. @&@.*(,/,*#%&##%#,(@%/(/(@@           //
//                            &@(@@@@/@@@@*%**,.(%#%&@[email protected]*/@&/&@@#%*/#%#%(##(@@/*.           //
//                         .&%@@@@@@@@@@@@@@@%#(////****//(#(,@.&&%%((//#%%%&*#,,           //
//                        (@%*,#@,*%&@@@@@@@@@%(//////(/**/*/,,.%%%%#*/*/(((*(**,,          //
//                      //,/*/,..#@@@@@@@@@@&%(//********/(/*,,@%%,*/*/////(69/%@.          //
//                    /#@&/#%../#@@@@@@@@@@&%(/*******,*********.%(**#*****/*(              //
//                     (%@(# .*@@@@@@@69#((//***,,,,,,,,,,,,,****,(&**%//(@.                //
//                    //#%*&/(*(%##((///***,,,,.....,,,,,,,,,,,*** @&&/*(/                  //
//                    *(*&. %/,,*/*,,........... ....... .  ..,,*.&&&&#*/(,,                //
//                     &%,  %**..,,.....             ....*(*,,.,,&&&&(,//(**                //
//                  ,*,#%/%%*,/*.......             .  ....,,.,..%(#(,.**/.                 //
//                   */&(*,#(&%/*,,,.            ...     .,*///@/#%,(.((,/                  //
//                   *@(/(/%(@@.****,.. .     ,*,        ./*/@/%&. .(,&&/                   //
//                 .,.,#%//*,#%#*,***.         *,,,    *###@%***#,./(#,                     //
//                 *@@@@(@#@*@ *%,*.*.   .,    &@/**%*#@/*,*(*/@  ,#%&                      //
//                *@@%///*@(%&/,.%.%*&. . /%,,.,&@@&/## %,#  ((@@#((                        //
//             .,@@,@@%&%#**,*//((%**/&,..*,&@.((#%//.,   @@,@(@.                           //
//             [email protected]@@@@@((/(#///.,,/**/(%,#(%@@@@%%&@@@&#@/./..                              //
//             ,,,,,%@@@@,,%#/*,,&***(,*/,/#%@&@@@@%@@*(%#/                                 //
//                ,***@@@@,&*/[email protected]*,(,,,,.,.                                                  //
//                 ///@@,..,&    .,69.,                                                     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./ERC1155CollectionBase.sol";

contract ESSENCE is ERC1155, ERC1155CollectionBase, AdminControl {

    constructor(address signingAddress_) ERC1155('') {
        _initialize(
            // total supply
            12969,
            // total supply available to purchase
            12969,
            // 0.469 eth public sale price
            469000000000000000,
            // purchase limit (0 for no limit)
            0,
            // transaction limit (0 for no limit)
            1,
            // 0.2 eth presale price
            200000000000000000,
            // presale limit (unused but 0 for no limit)
            0,
            signingAddress_,
            // use dynamic presale purchase limit
            true
        );
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CollectionBase, AdminControl) returns (bool) {
      return ERC1155CollectionBase.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Collection-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC1155.balanceOf(owner, TOKEN_ID);
    }

    /**
     * @dev See {IERC1155Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC1155Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }
    
    /**
     * @dev See {IERC1155Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC1155Collection-premint}.
     */
    function premint(uint16[] calldata amounts, address[] calldata addresses) external override adminRequired {
        _premint(amounts, addresses);
    }

    /**
     * @dev See {IERC1155Collection-mintReserve}.
     */
    function mintReserve(uint16 amount) external override adminRequired {
        _mintReserve(amount, owner());
    }

    /**
     * @dev See {IERC1155Collection-mintReserve}.
     */
    function mintReserve(uint16[] calldata amounts, address[] calldata addresses) external override adminRequired {
        _mintReserve(amounts, addresses);
    }

    /**
     * @dev See {IERC1155Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC1155Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC1155Collection-setCollectionURI}.
     */
    function setCollectionURI(string calldata uri) external override adminRequired {
        _setURI(uri);
    }

    /**
     * @dev See {IERC1155Collection-burn}
     */
    function burn(address from, uint16 amount) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");
        ERC1155._burn(from, TOKEN_ID, amount);
    }

    /**
     * @dev See {ERC1155CollectionBase-_mint}.
     */
    function _mintERC1155(address to, uint16 amount) internal virtual override {
        ERC1155._mint(to, TOKEN_ID, amount, "");
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address, address from, address, uint256[] memory, uint256[] memory, bytes memory) internal virtual override {
        _validateTokenTransferability(from);
    }
    
    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
      _updateRoyalties(recipient, bps);
    }

}