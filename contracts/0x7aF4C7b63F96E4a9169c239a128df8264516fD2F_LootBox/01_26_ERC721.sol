// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A, ERC721AQueryable, IERC721A} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

// _msgSender provided by OpenZepplin `Ownable`
abstract contract ERC721 is ERC721AQueryable, Ownable {

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}


    function _baseURI() internal override(ERC721A) view virtual returns (string memory) {
        return ERC721A._baseURI();
    }

    function _startTokenId() internal override(ERC721A) view virtual returns(uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) override(ERC721A, IERC721A) public view virtual returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) override(ERC721A, IERC721A) public view virtual returns(string memory) {
        return ERC721A.tokenURI(tokenId);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalMintedBy(address account) external view returns (uint256) {
        return _numberMinted(account);
    }
}