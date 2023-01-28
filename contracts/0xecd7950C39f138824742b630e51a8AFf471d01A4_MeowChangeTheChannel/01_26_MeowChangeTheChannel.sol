// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Mad Dog Jones
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//      ####    ####    ####################### ######          #######   ##################                 ###### ###############    ####    ####       //
//      ####    ####    ###################### #######        ########   ####################               ###### ################    ####    ####       //
//  ####    ####    ####    ################# ########      #########   ######         ######              ###### #############    ####    ####    ####   //
//  ####    ####    ####    ################ #########    ##########   ######         ######              ###### ##############    ####    ####    ####   //
//      ####    ####    ################### ##########  ###########   ######         ######              ###### ###################    ####    ####       //
//      ####    ####    ################## ########### ###########   ######         ######              ###### ####################    ####    ####       //
//  ####    ####    ####    ############# #######################   ######         ######   ######     ###### #################    ####    ####    ####   //
//  ####    ####    ####    ############ ######  #######  ######   ######         ######   ######     ###### ##################    ####    ####    ####   //
//      ####    ####    ####    ####### ######   #####   ######   ####################    ################# ###############    ####    ####    ####       //
//      ####    ####    ####    ###### ######           ######   ##################       ############### #################    ####    ####    ####       //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./core/IERC721CreatorCore.sol";
import "./extensions/ICreatorExtensionTokenURI.sol";
import "./redeem/ERC721BurnRedeem.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * Meow - Change the channel
 */
contract MeowChangeTheChannel is Ownable, ERC721BurnRedeem, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string constant private _EDITION_TAG = '<EDITION>';
    string[] private _uriParts;
    bool private _active;

    constructor(address creator) ERC721BurnRedeem(creator, 1, 99) {
        _uriParts.push('data:application/json;utf8,{"name":"Change the channel. #');
        _uriParts.push('<EDITION>');
        _uriParts.push('/99", "created_by":"Mad Dog Jones", ');
        _uriParts.push('"description":"Meow.\\n\\nMichah Dowbak aka Mad Dog Jones (b. 1985)\\n\\nChange the channel., 2023", ');
        _uriParts.push('"image":"https://arweave.net/cudfQEuB1oJSFOsFaSTxI9DpP85K0JnSvA5f-_3Nsh4","image_url":"https://arweave.net/cudfQEuB1oJSFOsFaSTxI9DpP85K0JnSvA5f-_3Nsh4","image_details":{"sha256":"015d8a7259f4cb0d5aef3c5a28bf1b2660d4a3e3372e8be97498c53c3f667843","bytes":8820652,"width":4000,"height":5000,"format":"PNG"},');
        _uriParts.push('"animation":"https://arweave.net/g_3sDenW4iJYdekAPN3qBLDBDDcl1LqY7wTbHRzH0F0","animation_url":"https://arweave.net/g_3sDenW4iJYdekAPN3qBLDBDDcl1LqY7wTbHRzH0F0","animation_details":{"sha256":"ddc7ef32e88c4528b3f4f200bd7ab7ca908e17eef805e5b56bf416f3b94446dc","bytes":180178899,"width":4000,"height":5000,"duration":33,"format":"MP4","codecs":["H.264","AAC"]},');
        _uriParts.push('"attributes":[{"trait_type":"Artist","value":"Mad Dog Jones"},{"trait_type":"Collection","value":"Meow"},{"trait_type":"Edition","value":"D"},{"display_type":"number","trait_type":"Edition","value":');
        _uriParts.push('<EDITION>');
        _uriParts.push(',"max_value":99}]}');

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BurnRedeem, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the first token
     */
    function activate() public onlyOwner {
        // Mint the first one to the owner
        require(!_active, "Already active");
        _active = true;
        _mintRedemption(owner());
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public onlyOwner {
        _uriParts = uriParts;
    }

    /**
     * @dev Generate uri
     */
    function _generateURI(uint256 tokenId) private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _EDITION_TAG)) {
               byteString = abi.encodePacked(byteString, (100-_mintNumbers[tokenId]).toString());
            } else {
              byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     * Override for reverse numbering
     */
    function mintNumber(uint256 tokenId) external view override returns(uint256) {
        require(_mintNumbers[tokenId] != 0, "Invalid token");
        return 100-_mintNumbers[tokenId];
    }

    /**
     * @dev See {IRedeemBase-redeemable}.
     */
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
        require(_active, "Inactive");
        return super.redeemable(contract_, tokenId);
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return _generateURI(tokenId);
    }
    

}