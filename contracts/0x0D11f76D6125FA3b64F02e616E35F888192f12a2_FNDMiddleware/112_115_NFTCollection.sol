// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/NFTCollection.sol";

contract $NFTCollection is NFTCollection {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _contractFactory) NFTCollection(_contractFactory) {}

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_initializeSequentialMintCollection(address payable _creator,uint32 _maxTokenId) external {
        return super._initializeSequentialMintCollection(_creator,_maxTokenId);
    }

    function $_selfDestruct() external {
        return super._selfDestruct();
    }

    function $_updateMaxTokenId(uint32 _maxTokenId) external {
        return super._updateMaxTokenId(_maxTokenId);
    }

    function $__ERC721Burnable_init() external {
        return super.__ERC721Burnable_init();
    }

    function $__ERC721Burnable_init_unchained() external {
        return super.__ERC721Burnable_init_unchained();
    }

    function $__ERC721_init(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init(name_,symbol_);
    }

    function $__ERC721_init_unchained(string calldata name_,string calldata symbol_) external {
        return super.__ERC721_init_unchained(name_,symbol_);
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_ownerOf(uint256 tokenId) external view returns (address) {
        return super._ownerOf(tokenId);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 arg2,uint256 batchSize) external {
        return super._beforeTokenTransfer(from,to,arg2,batchSize);
    }

    function $_afterTokenTransfer(address from,address to,uint256 firstTokenId,uint256 batchSize) external {
        return super._afterTokenTransfer(from,to,firstTokenId,batchSize);
    }

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }

    receive() external payable {}
}