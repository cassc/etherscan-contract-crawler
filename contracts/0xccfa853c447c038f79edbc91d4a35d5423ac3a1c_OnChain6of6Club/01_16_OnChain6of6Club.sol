// SPDX-License-Identifier: MIT
// OnChain6of6Club Contracts v0.0.1
// Creator: RockArt 🪨 AI

pragma solidity ^0.8.20;

import { IERC721A, ERC721A } from "ERC721A/ERC721A.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC2981 } from "openzeppelin/token/common/ERC2981.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ITokenURI } from "./TokenURI.sol";

/**
 * @title On-Chain 6of6.Club
 */
contract OnChain6of6Club is
    ERC721AQueryable,
    ERC2981,
    Ownable
{
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    uint256 public constant MAX_SUPPLY = 2 ** 16 - 1;
    uint256 public constant MAX_PER_MINT = 2 ** 6;

    address public tokenUri6of6;

    constructor() ERC721A("On-Chain 6of6.Club", "6OF6") {
        _setDefaultRoyalty(msg.sender, 950);
    }

    function setTokenURI(address tokenUri_) public onlyOwner {
        tokenUri6of6 = tokenUri_;
    }

    function mint(uint256 quantity) external { 
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "6of6.Club: You are minting too many (max 65,535)"
        );
        require(
            quantity > 0 && quantity <= MAX_PER_MINT,
            "6of6.Club: Must mint between 1 and 64"
        );
        _mint(msg.sender, quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return ITokenURI(tokenUri6of6).tokenURI(tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        emit BatchMetadataUpdate(startTokenId, startTokenId + quantity);

        uint256 stop = startTokenId + quantity;

        for (uint256 tokenId = startTokenId; tokenId < stop; tokenId++) {
            ITokenURI(tokenUri6of6).setToken(from, tokenId);
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, IERC721A)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4906: 0x49064906
        return interfaceId == bytes4(0x49064906) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function destroyOwner() public onlyOwner {
        transferOwnership(0x000000000000000000000000000000000000dEaD);
    }
}