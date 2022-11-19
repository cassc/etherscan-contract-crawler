// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721AQueryable, ERC721A, IERC721A} from "@erc721a/extensions/ERC721AQueryable.sol";
import {OwnableRoles} from "@solady/auth/OwnableRoles.sol";
import {DefaultOperatorFilterer} from "@os/DefaultOperatorFilterer.sol";
import {IDeadCrew} from "./interfaces/IDeadCrew.sol";

contract DeadCrew is
    IDeadCrew,
    ERC721AQueryable,
    OwnableRoles,
    DefaultOperatorFilterer
{
    string public baseURI;

    constructor(string memory baseURI_)
        ERC721A("D3ADCREW", "CR3W")
        DefaultOperatorFilterer()
    {
        baseURI = baseURI_;
        _initializeOwner(msg.sender);
        setAuthorized(msg.sender, 1);
    }

    function mint(address dest, uint256 quantity) public onlyAuthorized {
        _mint(dest, quantity);
    }

    function burn(uint256[] memory tokenIds) public onlyAuthorized {
        for (uint256 t; t < tokenIds.length; ++t) {
            _burn(tokenIds[t]);
        }
    }

    modifier onlyAuthorized() {
        require(_getAux(msg.sender) == 1, "Unauthorized");
        _;
    }

    function setAuthorized(address address_, uint64 authorized)
        public
        onlyOwner
    {
        require(authorized == 1 || authorized == 0, "Binary only");
        _setAux(address_, authorized);
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}