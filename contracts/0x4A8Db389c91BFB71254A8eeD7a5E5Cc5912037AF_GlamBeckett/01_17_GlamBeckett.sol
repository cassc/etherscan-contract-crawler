// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Glam Beckett

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    █████▀█████████████████████████████████████████████████████████████████    //
//    █─▄▄▄▄█▄─▄████▀▄─██▄─▀█▀─▄███▄─▄─▀█▄─▄▄─█─▄▄▄─█▄─█─▄█▄─▄▄─█─▄─▄─█─▄─▄─█    //
//    █─██▄─██─██▀██─▀─███─█▄█─█████─▄─▀██─▄█▀█─███▀██─▄▀███─▄█▀███─█████─███    //
//    ▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▀▄▄▄▀▀▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▀▄▄▄▀▀▀▄▄▄▀▀    //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////

contract GlamBeckett is AdminControl, ICreatorExtensionTokenURI {
    address private constant _creator = 0x2438A0eeFfA36Cb738727953d35047fb89c81417;
    string private _tokenURI;
    bool private minted;

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
       
        uint[] memory amounts = new uint[](1);
        amounts[0] = 125; 
        
        string[] memory uris = new string[](1);
        uris[0] = "";

        IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amounts, uris);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setTokenURI(string memory newTokenURI) public adminRequired {
        _tokenURI = newTokenURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return _tokenURI;
    }
}