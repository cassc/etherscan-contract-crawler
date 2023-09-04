// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IMetaSpaceMin.sol";

contract MetaSpaceToken is ERC721 {
    IMetaSpaceMin public _metaSpaceController;

    constructor(
        string memory name_,
        string memory symbol_,
        address controller_
    ) ERC721(name_, symbol_) {
        _metaSpaceController = IMetaSpaceMin(controller_);
    }

    function mint(address to, uint256 tokenId) external {
        require(
            msg.sender == address(_metaSpaceController),
            "Only for platform"
        );
        _mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {}

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        (, string memory uri, , , ) = _metaSpaceController.getSpaceSecure(
            tokenId
        );
        return uri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address,
        address to,
        uint256 tokenId,
        uint256
    ) internal override {
        _metaSpaceController.updateOwner(tokenId, to);
    }
}