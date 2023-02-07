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
 * Meow - De-escalation
 */
contract MeowDeEscalation is Ownable, ERC721BurnRedeem, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string constant private _EDITION_TAG = '<EDITION>';
    string[] private _uriParts;
    bool private _active;

    constructor(address creator) ERC721BurnRedeem(creator, 1, 11) {
        _uriParts.push('data:application/json;utf8,{"name":"De-escalation. #');
        _uriParts.push('<EDITION>');
        _uriParts.push('/11", "created_by":"Mad Dog Jones", ');
        _uriParts.push(unicode'"description":"Déjà vu.\\n\\nMichah Dowbak aka Mad Dog Jones (b. 1985)\\n\\nDe-escalation., 2023", ');
        _uriParts.push('"image":"https://arweave.net/_GAO4O66fEmSTjMvE9X5e4kGLFCWLTEHEO9UUymVNCM","image_url":"https://arweave.net/_GAO4O66fEmSTjMvE9X5e4kGLFCWLTEHEO9UUymVNCM","image_details":{"sha256":"3b590f6fa939861727ceae10f0afd7451f826817a79a7a7203d1e1cc87d26dad","bytes":7936693,"width":2400,"height":3000,"format":"PNG"},');
        _uriParts.push('"animation":"https://arweave.net/I_gLrrZc1La9SenOWM-4dEhl6j9u2YiToaGvOlPtyPg","animation_url":"https://arweave.net/I_gLrrZc1La9SenOWM-4dEhl6j9u2YiToaGvOlPtyPg","animation_details":{"sha256":"9763825d48b7c3c1b8e77c6d7c2179296e7982723ca774cdef1638a9b1f8f5d0","bytes":65284057,"width":4000,"height":5000,"duration":28,"format":"MP4","codecs":["H.264","AAC"]},');
        _uriParts.push(unicode'"attributes":[{"trait_type":"Artist","value":"Mad Dog Jones"},{"trait_type":"Collection","value":"Déjà vu"},{"trait_type":"Edition","value":"A"},{"display_type":"number","trait_type":"Edition","value":');
        _uriParts.push('<EDITION>');
        _uriParts.push(',"max_value":11}]}');

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
               byteString = abi.encodePacked(byteString, (12-_mintNumbers[tokenId]).toString());
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
        return 12-_mintNumbers[tokenId];
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