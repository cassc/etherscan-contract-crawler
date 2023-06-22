// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import {IRenderer} from "./IRenderer.sol";

contract Spirax is ERC721, ERC2981, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    error MaxMintAmountExceeded();
    error MaxSupplyExceeded();
    error MintingNotEnabled();
    error InvalidTokenState();

    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant MAX_MINT_AMOUNT = 100;
    uint256 lastTokenId;
    bool mintingEnabled = true;
    string contractMeta = "ewogICJuYW1lIjogIlNwaXJheCBPbi1DaGFpbiIsCiAgImRlc2NyaXB0aW9uIjogIldlbGNvbWUgdG8gU3BpcmF4IOKAkyBhIHVuaXF1ZSBjcm9zc3JvYWRzIG9mIGFydCBhbmQgYWxnb3JpdGhtLiBIZXJlLCBzcGlyb2dyYXBoLWluc3BpcmVkIGRlc2lnbnMgbWVldCBibG9ja2NoYWluJ3MgdW5hbHRlcmFibGUgcmVhbGl0eS4gT3VyIGNvbGxlY3Rpb24gdGhyaXZlcyBpbiB0aGUgZGlnaXRhbCByZWFsbSwgb2ZmZXJpbmcgYXJ0aXN0aWNhbGx5IGdlbmVyYXRlZCwgb24tY2hhaW4gTkZUcyB0aGF0IGJsZW5kIHVucHJlZGljdGFiaWxpdHkgd2l0aCBwcmVjaXNpb24uIEV4cGxvcmUgU3BpcmF4LCB3aGVyZSB0aGUgbWF0aGVtYXRpY2FsIGVsZWdhbmNlIG9mIHRoZSBjb3Ntb3MgaXMgY2FwdHVyZWQgaW4gY2FwdGl2YXRpbmcgdmlzdWFscy4iLAogICJpbWFnZSI6ICJodHRwczovL3NwaXJheC53dGYvaWNvbi5zdmciLAogICJleHRlcm5hbF9saW5rIjogImh0dHBzOi8vc3BpcmF4Lnd0ZiIKfQ==";

    IRenderer renderer;
    mapping(uint256 => uint256) tokenSeeds;
    mapping(address => uint256) mints;

    constructor(address _renderer) ERC721("Spirax", "SPRX") {
        renderer = IRenderer(_renderer);
        _setDefaultRoyalty(0x3236E05F02Ca6E667D46bB63FF29f676a3CE07aE, 500);
    }

    function mint(uint32 amount) public {
        if (!mintingEnabled) revert MintingNotEnabled();
        if (mints[msg.sender] + amount > MAX_MINT_AMOUNT) revert MaxMintAmountExceeded();
        mints[msg.sender] += amount;
        uint256 nextTokenId = lastTokenId + 1;

        if (lastTokenId + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        lastTokenId += amount;

        for (; nextTokenId <= lastTokenId; ) {
            tokenSeeds[nextTokenId] = uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), nextTokenId)
                )
            );
            _mint(_msgSender(), nextTokenId);
            unchecked {
                ++nextTokenId;
            }
        }
    }

    function contractURI() public view returns (string memory) {
        return string.concat("data:application/json;base64,", contractMeta);
    }

    function setMintingEnabled(bool _mintingEnabled) public onlyOwner {
        mintingEnabled = _mintingEnabled;
    }

    function setRenderer(address _renderer) public onlyOwner {
        renderer = IRenderer(_renderer);
    }

    function setContractMeta(string memory _contractMeta) public onlyOwner {
        contractMeta = _contractMeta;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return renderer.tokenURI(tokenId, tokenSeeds[tokenId]);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}