//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/LibString.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";

import "./LibStorage.sol";

import {ERC2981} from "./ERC2981/ERC2981.sol";

import {ERC1155D} from "./ERC1155D/ERC1155D.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";

contract GameMainFacet is ERC1155D, WithStorage, UsingDiamondOwner,
    ReentrancyGuard, Multicall, OperatorFilterer, ERC2981, GameInternalFacet, AccessControl {
    
    using LibString for *;
    using SafeTransferLib for address;
    
    event NewItemCreatedThroughCombination(
        address indexed user,
        uint indexed toBeCombinedId,
        uint indexed combinedIntoId,
        uint costToCombine
    );
    
    event Withdraw(uint indexed total);
    
    function setTokenInfo(GameItemTokenInfo calldata _tokenInfo) external onlyRole(ADMIN) {
        require(bytes(_tokenInfo.slug).length > 0, "Slug must be set");
        require(bytes(_tokenInfo.name).length > 0, "Name must be set");

        uint tokenId = slugToTokenId(_tokenInfo.slug);
        
        gs().tokenIdToTokenInfo[tokenId] = _tokenInfo;
    }
    
    function createNewItemByCombiningExistingItems(string calldata toBeCombinedSlug) external nonReentrant {
        uint toBeCombinedId = findIdBySlugOrRevert(toBeCombinedSlug);
        
        GameItemTokenInfo memory toBeCombined = gs().tokenIdToTokenInfo[toBeCombinedId];
        
        uint combinedIntoId = findIdBySlugOrRevert(toBeCombined.canBeCombinedIntoSlug);
        
        _burn(msg.sender, toBeCombinedId, toBeCombined.costToCombine);
        _mint(msg.sender, combinedIntoId, 1, "");
        
        emit NewItemCreatedThroughCombination(
            msg.sender,
            toBeCombinedId,
            combinedIntoId,
            toBeCombined.costToCombine
        );
    }
    
    function burnFromPunkContract(address owner, string memory slug, uint amountToBurn) external {
        require(msg.sender == gs().bookContract, "Only punk contract can burn");
        
        _burn(owner, slugToTokenId(slug), amountToBurn);
    }
    
    function uri(uint256 tokenId) public view override(ERC1155D) returns (string memory) {
        GameItemTokenInfo memory tokenInfo = gs().tokenIdToTokenInfo[tokenId];
        
        return string(
            abi.encodePacked(
                'data:application/json;utf-8,{',
                '"name":"', tokenInfo.name.escapeJSON(), '",'
                '"description":"', tokenInfo.description.escapeJSON(), '",'
                '"image":"', tokenInfo.imageURI, '",'
                '"external_url":"', tokenInfo.externalLink, '"'
                '}'
            )
        );
    }
    
    function withdraw() external nonReentrant {
        require(gs().withdrawAddress != address(0), "Withdraw address not set");
        
        emit Withdraw(address(this).balance);

        gs().withdrawAddress.forceSafeTransferETH(address(this).balance);
    }
    
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155D)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155D) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155D) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return gs().operatorFilteringEnabled;
    }
    
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}