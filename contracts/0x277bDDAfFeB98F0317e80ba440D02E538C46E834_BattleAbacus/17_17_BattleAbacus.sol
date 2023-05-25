// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title Rareboy - Battle Abacus Contract
 * @author @SamOsci [via Rareboy Studio]
 * @notice This contract handles the Rareboy - Battle Abacus claim
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error ClaimNotActiveError();
error MissingMedallionContractError();
error NotMedallionOwnerError();
error AlreadyClaimedError();

interface MedallionInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BattleAbacus is
    Ownable,
    ERC721A,
    ERC2981,
    ERC721ABurnable,
    ERC721AQueryable,
    DefaultOperatorFilterer
{
    bool public claimIsActive = false;
    uint256 public startTokenId = 1;
    string public tokenBaseURI;
    address public medallionContractAddress;

    mapping(uint256 => bool) public claims;

    struct ClaimStatus {
        uint256 tokenId;
        bool claimed;
    }

    constructor(
        string memory _tokenName,
        string memory _symbol,
        string memory _tokenBaseURI,
        uint96 _royaltyFee
    ) ERC721A(_tokenName, _symbol) {
        tokenBaseURI = _tokenBaseURI;
        _setDefaultRoyalty(msg.sender, _royaltyFee);
    }

    function contractURI() public view returns (string memory) {
        return string.concat(_baseURI(), "contract");
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function claim(uint256[] memory tokenIds) external {
        if (!claimIsActive) {
            revert ClaimNotActiveError();
        }

        MedallionInterface medallion = MedallionInterface(
            medallionContractAddress
        );

        for (uint16 i = 0; i < tokenIds.length; i++) {
            if (hasClaimed(tokenIds[i])) {
                revert AlreadyClaimedError();
            }
            if (medallion.ownerOf(tokenIds[i]) != msg.sender) {
                revert NotMedallionOwnerError();
            }

            claims[tokenIds[i]] = true;
        }

        _mint(msg.sender, tokenIds.length);
    }

    function hasClaimed(uint256 tokenId) public view returns (bool) {
        return claims[tokenId];
    }

    function batchHasClaimed(
        uint256[] memory tokenIds
    ) public view returns (ClaimStatus[] memory) {
        ClaimStatus[] memory batchClaims = new ClaimStatus[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batchClaims[i].tokenId = tokenIds[i];
            batchClaims[i].claimed = claims[tokenIds[i]];
        }

        return batchClaims;
    }

    // Operator Filtering
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Owner
    function toggleClaimIsActive() external onlyOwner {
        if (!claimIsActive && medallionContractAddress == address(0)) {
            revert MissingMedallionContractError();
        }

        claimIsActive = !claimIsActive;
    }

    function setMedallionContractAddress(
        address contractAddress
    ) external onlyOwner {
        medallionContractAddress = contractAddress;
    }

    function setTokenBaseURI(string memory newTokenBaseURI) external onlyOwner {
        tokenBaseURI = newTokenBaseURI;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 _royaltyFee
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, _royaltyFee);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}