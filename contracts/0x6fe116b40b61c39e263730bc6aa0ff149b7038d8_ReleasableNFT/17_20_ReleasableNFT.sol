// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Releasable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//     ██████╗ ██████╗  ██████╗ ███╗   ██╗███████╗    █████╗ ██████╗ ████████╗    //
//    ██╔════╝██╔═══██╗██╔═══██╗████╗  ██║██╔════╝   ██╔══██╗██╔══██╗╚══██╔══╝    //
//    ██║     ██║   ██║██║   ██║██╔██╗ ██║█████╗     ███████║██████╔╝   ██║       //
//    ██║     ██║▄▄ ██║██║   ██║██║╚██╗██║██╔══╝     ██╔══██║██╔══██╗   ██║       //
//    ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║███████╗██╗██║  ██║██║  ██║   ██║       //
//     ╚═════╝ ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////
contract ReleasableNFT is ERC721Releasable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    /// @dev 最大铸造数量
    uint16 public _maxMintCount;
    /// @dev 地址前缀
    string public _baseTokenURI;
    /// @dev 当前tokenId
    Counters.Counter private currentTokenId;

    /**
     * @dev 构造函数
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _maxMintCount = 20;
    }

    /**
     * @dev 设置最大铸造数量
     */
    function _setMaxMintCount(uint16 count) public onlyOwner {
        _maxMintCount = count;
    }

    /**
     * @dev 获取地址前缀
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev 设置地址前缀
     */
    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev 铸造NFT
     */
    function mintTo(address to) public onlyOwner returns (uint256) {
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        require(tokenId >= 1 && tokenId <= totalShares(), "Token id out of range.");

        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev 批量铸造NFT
     */
    function mintToBatch(address to, uint16 count) public onlyOwner {
        require(count <= _maxMintCount, "Mint count is out of range.");
        for (uint i = 0; i < count; i++) {
            mintTo(to);
        }
    }

    /**
     * @dev 销毁NFT
     */
    function destroy(uint256 tokenId) public onlyOwner {
        _requireMinted(tokenId);

        _burn(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}