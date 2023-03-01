// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibString.sol";

import "./LibStorage.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {BookInternalFacetV2} from "./BookInternalFacetV2.sol";
import {BookRenderFacet} from "./BookRenderFacet.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import "@solidstate/contracts/utils/Multicall.sol";

import { ERC721D } from "./ERC721D/ERC721D.sol";

contract BookCore721Facet is ERC721D, WithStorage, Multicall, BookInternalFacetV2, OperatorFilterer {
    function setGameContract(address _gameContract) external onlyRole(ADMIN) {
        bk().gameContract = _gameContract;
    }
    
    function setMintIsActive(bool newState) external onlyRole(ADMIN) {
        bk().isMintActive = newState;
    }
    
    function setMetadata(
        string calldata _name,
        string calldata symbol,
        string calldata _nameSingular,
        string calldata _externalLink,
        string calldata _tokenDescription
    ) external onlyRole(ADMIN) {
        _setName(_name);
        _setSymbol(symbol);
        bk().nameSingular = _nameSingular;
        bk().externalLink = _externalLink;
        bk().tokenDescription = _tokenDescription;
    }
    
    function exists(uint punkId) external view returns (bool) {
        return _exists(punkId);
    }
    
    function ownerOfNoRevert(uint punkId) external view returns (address) {
        return _ownerOf(punkId);
    }
    
    function getGameContract() external view returns (address) {
        return bk().gameContract;
    }
    
    function punkHasHiddenAttributeExternal(uint80 packedAssets) external pure returns (bool) {
        return punkHasHiddenAttribute(packedAssets);
    }
    
    function packedAssetsToUnpackedPunkStructExternal(uint80 packedAssets)
        external pure returns (UnpackedPunk memory) {
        return packedAssetsToUnpackedPunkStruct(packedAssets);
    }

    function tokenURI(uint256 id) public view override(ERC721D) returns (string memory) {
        require(_exists(id), "Token does not exist");
        return BookRenderFacet(address(this)).constructTokenURI(id);
    }
    
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return bk().operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}