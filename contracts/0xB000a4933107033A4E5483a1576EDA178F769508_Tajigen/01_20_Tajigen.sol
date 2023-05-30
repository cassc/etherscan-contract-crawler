// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./TinyERC721.sol";
import "./TokenSale.sol";
import "./ITokenRenderer.sol";

contract Tajigen is TinyERC721, ERC2981, Ownable, TokenSale {
    uint256 public constant MAX_SUPPLY = 7777;

    address private _rendererAddress;

    constructor() TinyERC721("Citizens of Tajigen", "TAJIGEN", 5) {
        _safeMint(_msgSender(), 1);
    }

    function _calculateAux(
        address from,
        address to,
        uint256 tokenId,
        bytes12 current
    ) internal view virtual override returns (bytes12) {
        return
            from == address(0)
                ? bytes12(keccak256(abi.encodePacked(tokenId, to, block.difficulty, block.timestamp)))
                : current;
    }

    function soulHash(uint256 tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, _tokenData(tokenId).aux));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return
            _rendererAddress != address(0) ? ITokenRenderer(_rendererAddress).tokenURI(tokenId, soulHash(tokenId)) : "";
    }

    function setRendererAddress(address rendererAddress) external onlyOwner {
        require(rendererAddress != address(0), "Can't set to zero address");
        _rendererAddress = rendererAddress;
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function _guardMint(address, uint256 quantity) internal view virtual override {
        unchecked {
            require(tx.origin == msg.sender, "Can't mint from contract");
            require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        }
    }

    function _mintTokens(address to, uint256 quantity) internal virtual override {
        _mint(to, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(TinyERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw(address receiver) external onlyOwner {
        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}