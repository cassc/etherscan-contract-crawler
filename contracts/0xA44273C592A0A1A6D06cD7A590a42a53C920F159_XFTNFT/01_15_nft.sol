// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract XFTNFT is ERC721, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;

    bytes32[] public MINTER_ROLES = [keccak256("BELIEVER_ROLE"), keccak256("DEV_ROLE"), keccak256("TEAM_ROLE")];

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Offshift NFT", "XFT NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        address[4] memory believers = [0xB9B1D084b9AccD6eBf35d1D3AB1e49B859c8D8b5, 0x7e26F4789f93096baA659Bc57955331B5Fd00878, 0x40aE8D46b6759deF119b2dEaDa4FCD75705fe32d, 0x1a9f0864831dBfAd8958bBFBb4b22970E54819ED];
        address[4] memory devs = [0xbB63416296409EE0f6AD4625aA8485C3Ca293D22, 0xd0148668c0b539b762a32073E75553c856e7554D, 0x286d4F57fedaEb8b82709682b17A20F4125A9F78, 0x09887B4cE335E6770763266f25D14F1c2dc476c8];
        address[2] memory team = [0x447afC6Ba27be30488043Bc4FF674aa0D11eFDBE, 0x94ebB5C7b3B538fa6B43Adf67e6a4B8CB13B228F];
        for (uint i = 0; i < 4; i++){
            _grantRole(MINTER_ROLES[0], believers[i]);
        }
        for (uint i = 0; i < 4; i++){
            _grantRole(MINTER_ROLES[1], devs[i]);
        }
        for (uint i = 0; i < 2; i++){
            _grantRole(MINTER_ROLES[2], team[i]);
        }
    }
    function BELIEVERMint(address to) public onlyRole(MINTER_ROLES[0]) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        string memory uri = "data:application/json;base64,ewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJPZmZzaGlmdCBCRUxJRVZFUiBzcGVjaWFsIG1pbnQgbmZ0IiwKICAgICAgICAiZXh0ZXJuYWxfdXJsIjogImh0dHBzOi8vb2Zmc2hpZnQuaW8iLAogICAgICAgICJpbWFnZSI6ICJpcGZzOi8vYmFmeWJlaWNtdHBvdGhka2d1bGd2NmN1bGpiNGlnM3hibGRyM2k1cGxrZHp6eXlucnd6d2VweGprcWUiLAogICAgICAgICJuYW1lIjogIk9mZnNoaWZ0IEJFTElFVkVSIiwKICAgICAgICAiYW5pbWF0aW9uX3VybCI6ICJpcGZzOi8vYmFmeWJlaWZ1Mm01Mnh4cWd1MmdsbGZmZW4ycnl6ZHVtejNkYWxpZmVrMzR0MnhmZmI3bmZ1ZGJ6NXkiCiAgICB9";
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    function DevMint(address to) public onlyRole(MINTER_ROLES[1]) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        string memory uri = "data:application/json;base64,ewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJPZmZzaGlmdCBERVYgc3BlY2lhbCBtaW50IG5mdCIsCiAgICAgICAgImV4dGVybmFsX3VybCI6ICJodHRwczovL29mZnNoaWZ0LmlvIiwKICAgICAgICAiaW1hZ2UiOiAiaXBmczovL2JhZnliZWllNXdjaTN2a2t1bjVnczdnemtybDI1bzRxYWhxNjJ6NGtsZzdzc2k0dGxmMzNhdnB1aGRtIiwKICAgICAgICAibmFtZSI6ICJPZmZzaGlmdCBERVYiLAogICAgICAgICJhbmltYXRpb25fdXJsIjogImlwZnM6Ly9iYWZ5YmVpZmlibHF1eHF1cmt0Y25mb2FlZ242ZXp3YXJxZW1jMno2dG92d2p4b2hydGsybmRvazdmYSIKICAgIH0=";
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    function TeamMint(address to) public onlyRole(MINTER_ROLES[2]) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        string memory uri = "data:application/json;base64,ewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJPZmZzaGlmdCBURUFNIHNwZWNpYWwgbWludCBuZnQiLAogICAgICAgICJleHRlcm5hbF91cmwiOiAiaHR0cHM6Ly9vZmZzaGlmdC5pbyIsCiAgICAgICAgImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpZmF0aTZvaWFnYXprdmNhcGN6Ym9kaHc0NWNoNXhjMndzeWtrMzJ5dnhxNHZxN2w0eXN5cSIsCiAgICAgICAgIm5hbWUiOiAiT2Zmc2hpZnQgVEVBTSIsCiAgICAgICAgImFuaW1hdGlvbl91cmwiOiAiaXBmczovL2JhZnliZWlkM2RxZHhjaTJoZmdtdWJ6NWRydTI2NGh3dDJsanFncndjeWl0M2kzZm9xbmg0NmJndHdlIgogICAgfQ==";
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}