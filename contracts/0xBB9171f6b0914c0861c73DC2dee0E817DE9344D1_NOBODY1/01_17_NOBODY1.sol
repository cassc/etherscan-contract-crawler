// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

// @author: white lights (whitelights.eth)
// @shoutout: dom aka dhof (dhof.eth)

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▐     //
//    ▌ ██  NOBODY                                                                   ▐     //
//    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █╟█▌█████████████████████████████████████████████████████████████████████████  ▐     //
//    ██████▀███████████▌██████▌█▌████████▌███▌████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    ██▀▀██╙███▌████│╬╜▌██▌█╫█▌█▌█▌██╠╠██▀█╟█▌████║▀██████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █▌█▄▄▌█▄▄█╣▄▄██████▄███▄▄█▄██▄▄███▄██████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █▌█████▌█████████████████████▌███║███████████████████████████████████████████  ▐     //
//    █╣███████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    ███╣╬▌██║██████████████║█████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████▌███████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █████████████████████████████████████████████████████████████████████████████  ▐     //
//    █ C:\> █                                                                       ▐     //
//    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀     //
//                                                                                         //
//    a collaboration between white lights and nobody (a.i.)                               //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface INobody1Renderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NOBODY1 is AdminControl, ICreatorExtensionTokenURI {
    uint private _tokenId;
    address private _creator;

    INobody1Renderer public renderer =
        INobody1Renderer(0xabA5981b570E9d747BAE95a490934b681b1f4927);
    string[] private _imageParts;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function mint() public adminRequired {
        require(_tokenId == 0, "Cannot mint again");
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 11; // 11:11
        string[] memory uris = new string[](1);
        uris[0] = "";

        _tokenId = IERC1155CreatorCore(_creator).mintExtensionNew(
            addressToSend,
            amounts,
            uris
        )[0];
    }

    function setRenderer(address addr) public onlyOwner {
        renderer = INobody1Renderer(addr);
    }

    function tokenURI(address, uint256)
        public
        view
        override
        returns (string memory)
    {
        return renderer.tokenURI(_tokenId);
    }
}