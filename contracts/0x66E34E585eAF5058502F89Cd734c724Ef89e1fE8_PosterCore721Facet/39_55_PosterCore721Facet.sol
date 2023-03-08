// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/LibSort.sol";
import "solady/src/utils/SSTORE2.sol";
import "@solidstate/contracts/utils/Multicall.sol";
import { ERC721D } from "./ERC721D/ERC721D.sol";
import {BookDataFacetPosterExt} from "./BookDataFacetPosterExt.sol";
import {PosterMainFacet} from "./PosterMainFacet.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import "./PosterInternalFacet.sol";

contract PosterCore721Facet is ERC721D, Multicall, PosterInternalFacet, OperatorFilterer {
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721D) returns (string memory) {
        require(_exists(tokenId));
        
        return PosterMainFacet(address(this)).constructTokenURI(tokenId);
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
        return s().operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}