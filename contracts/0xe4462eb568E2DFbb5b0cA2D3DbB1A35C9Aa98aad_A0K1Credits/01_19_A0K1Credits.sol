// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Steve Aoki
/// @title: A0K1 Credits
/// @author: manifold.xyz

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                    ,xWWWWWx,.                                   //
//                                   'OWWWWWWWNd.                                  //
//                                  .xWWWK0KNWWNl                                  //
//                                 .oNWWXc.,xWWWX:                                 //
//                                 lNWWNo.  .OWWW0,                                //
//                                :XWWWx.    ,0WWWO'                               //
//                               ,0WWWO.      :XWWWx.                              //
//                              'OWWW0,  ...   lNWWNd.                             //
//                             .xWWWX:   o0k;  .dNWWXl                             //
//                            .dNWWNl   cXWW0'  .kWWWX:                            //
//                            lXWWNd.  ;KWWWWk.  '0WWW0,                           //
//                           :XWWWk.  '0WWWWWNd.  ;KWWWO'                          //
//                          ,0WWWO'  .kWWWWWWWNo.  cXWWWx.                         //
//                         .OWWWK;  .dNWWWWWWWWXc  .oNWWNo.                        //
//                        .xWWWXc   oNWWWKOKNWWWK;  .xWWWXl                        //
//                       .oNWWNo   cXWWWX:.,dNWWW0'  'OWWWX:                       //
//                       lXWWWd.  ;KWWWNl   .kWWWWk.  ;KWWW0,                      //
//                      :XWWWk.  '0WWWNd.    ,0WWWWd.  :XWWWO'                     //
//                     ,0WWW0'   ;dddxl.      ,ddddo'   lNWWWx.                    //
//                    .xWWWNl                           .OWWWNc                    //
//                     :XWWWO.   ,llll:.      .clllc.   :KWWWO'                    //
//                      lNWWWx.  ;KWWWNo.    .OWWWWk.  ,0WWWK,                     //
//                      .dNWWNo   :XWWWXc   .xWWWWO'  .OWWWX:                      //
//                       .xWWWXc   lNWWWK;..oNWWWK;  .xWWWNl                       //
//                        'OWWWK;  .dNWWW0kOXWWWX:   oNWWNd.                       //
//                         ,0WWWO'  .kWWWWWWWWWNl   cXWWWx.                        //
//                          :XWWWk.  'OWWWWWWWNd.  ;KWWWO'                         //
//                           lNWWNd.  ;KWWWWWWk.  '0WWWK;                          //
//                           .dNWWNl   :XWWWWO'  .kWWWX:                           //
//                            .xWWWK:   lNWWK;  .dNWWNl                            //
//                             'OWWW0,  .dK0c   lNWWNd.                            //
//                              ,0WWWk.  .,..  :XWWWx.                             //
//                               :XWWWx.      ,KWWWO'                              //
//                                lNWWNo     'OWWWK,                               //
//                                .dNWWXc   .xWWWX:                                //
//                                 .xWWWK;..oNWWNl                                 //
//                                  'OWWW0x0XWWNd.                                 //
//                                   ,KWWWWWWWWx.                                  //
//                                    :XWWWWWWO'                                   //
//                                    .l000O0l.                                    //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./ERC1155CollectionBase.sol";

/**
 * ERC1155 Collection Drop Contract
 */
contract A0K1Credits is ERC1155, ERC1155CollectionBase, AdminControl {

    constructor(address signingAddress_) ERC1155('') {
        _initialize(
            50000,                  // maxSupply
            25000,                  // purchaseMax
            250000000000000000,     // purchasePrice
            0,                      // purchaseLimit
            24,                     // transactionLimit
            250000000000000000,     // presalePurchasePrice
            0,                      // presalePurchaseLimit
            signingAddress_
        );
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AdminControl) returns (bool) {
      return ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
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
     * @dev See {IERC1155Collection-updateRoyalties}.
     */
    function updateRoyalties(address payable recipient, uint256 bps) external override adminRequired {
      _updateRoyalties(recipient, bps);
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
}