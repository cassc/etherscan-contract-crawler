// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: HOWLERZ
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                      .                        ...              //
//             ...'''..          ..'...,,                      .;:'               //
//                 .':c:'     .;cl:,''c:.     ..          ..,:cl;.                //
//                    ;dd,  .;ll,..,cl;.      ':'       .cllc;'.                  //
//      ..',;;'.      .cxc..cdc,,col;.         ;ol'    ,oc'.                      //
//         ..;lc.      .ol;cdolcc;'.            ,oo'  .l:  .                      //
//            .:l'     .cxoc'....          ..   .:o' .cl. .;.                     //
//     ..      'ol.     :d;   .:'         .;;   ,l:..cl' .;;.      '.             //
//     .,:'    'do.    .co. .,l:.        .;l:..:doclo:..,:'       ':.             //
//       ;o,   .od,    .:dccoo:.         .coocodlcclool:'. ..   .;l,              //
//       'dc.   .lo,    :xdc;.           .:oxdl:.   .:l:,;:::;::cc'               //
//       'dl.    .lo.  .:l'..            .:oxddl'...  .:dxc......                 //
//       'do'     ,o;..;ol';c'.         .:ddxxxdlcll;.  .;cccc:;,.                //
//        ,ooc,'',lxdlcc:::oxxoc:,.....'cxxxxxxo,..:dc.    ...,;:::;.             //
//         .':ccc::;'..    ,oxxxxxdoddxxxxxxxxxd:. .;ooc;,'...    .;c:'.          //
//                         .cxxxxxxxxxxxxxxxxxxxxl.  ....'....      .,:c:,'.      //
//                         'oxxxxxxxxxxxxxxxxdolld:.                     ..       //
//                        .oxxxxxxxxxdc;;cldd;.  .;'                              //
//                       .cxxxxxxxxxl.     'c'    .:.                             //
//                       'dxxxxxxxxx:.     .cl,...:dc.                            //
//                       ;xxxxxxxxxxo;...',cxxxdodxxx:                            //
//                       ,dxxxxxxxxxxxdodxxxxxxxxxxxxd;                           //
//                       .oxxxxxxxxxxxdodxxxxxxxxxxxxxo'                          //
//                        ,oxxxxxxxxxxc..';:odxxxxxxxxo'                          //
//                         'oxxxxxxxxxo.    ..;codddo:.                           //
//                          .cdxxxxxxxx:.        ....                             //
//                           .;dxxxxxxxd;.                                        //
//                             ;dxxxxxxxd:'.                                      //
//                             .lxxxxxxxxxxo'                                     //
//                              :xxxxxxxxxxxdc,..                                 //
//                           ..;oxxxxxxxxxxxxxxdolllllllcc:,.                     //
//                       ..,:odxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl,                   //
//                   .';codxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.                 //
//                .,cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:.                //
//               'lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,                //
//             .;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.               //
//             ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.               //
//            .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.               //
//            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.               //
//            :xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.               //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Prey is AdminControl, ERC721 {
    using Strings for uint256;

    string private _tokenURIPrefix;
    uint256 private _tokenIndex;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("PREY", "PREY") {}

    /**
      * @dev See {IERC165-supportsInterface}.
      */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId)
            || AdminControl.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function airdrop(address[] calldata receivers) external adminRequired {
        require(_tokenIndex + receivers.length <= 5000, "Only 5000 total supply");
        for (uint i = 0; i < receivers.length; i++) {
            _tokenIndex++;
            _mint(receivers[i], _tokenIndex);
        }
    }

    /**
    *  @dev Set the tokenURI prefix
    */
    function setTokenURIPrefix(string calldata uri) external adminRequired {
        _tokenURIPrefix = uri;
    }

    /**
      * @dev See {IERC721Metadata-tokenURI}.
      */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString()));
    }

    /**
      * ROYALTY FUNCTIONS
      */

    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}