//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FixedSale} from "../distribution/FixedSale.sol";
import {TieredMetadata} from "../extensions/TieredMetadata.sol";
import {PassiveStaking} from "../extensions/PassiveStaking.sol";
import {DefaultOperatorFilterer} from "../utils/opensea/DefaultOperatorFilterer.sol";
import {ERC2981Base, ERC2981ContractWideRoyalties} from "../utils/royalties/ERC2981ContractWideRoyalties.sol";

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721AFixedSale is
    ERC721A,
    PassiveStaking,
    TieredMetadata,
    Ownable,
    ERC2981ContractWideRoyalties,
    DefaultOperatorFilterer,
    FixedSale
{
    constructor(
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256 _royalty
    ) ERC721A(_name, _symbol) {
        _setRoyalties(_recipient, _royalty);
    }

    function publicSaleMint(uint8 _quantity) public payable {
        _publicSaleHook(_quantity, totalSupply());
        _safeMint(msg.sender, _quantity);
    }

    function allowlistMint(bytes32[] calldata proof) public payable {
        _allowlistHook(proof);
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _tokenURI(tokenId);
    }

    function reveal() public onlyOwner {
        _setRevealed();
    }

    function setUnrevealedBaseURI(string memory baseUri) public onlyOwner {
        _setUnrevealedBaseURI(baseUri);
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _setBaseURI(baseUri);
    }

    function setTierBaseURI(uint256 tier_, string memory baseUri) public onlyOwner {
        _setTierBaseURI(tier_, baseUri);
    }

    function addTier(Tier memory tier_) public onlyOwner {
        _addTier(tier_);
    }

    function setStakingStartTime(uint256 startTime) public onlyOwner {
        _setStartTime(startTime);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function withdraw() public onlyOwner {
        _withdrawFunds(_royalties.recipient);
    }

    // OVERRIDES FOR OPERATOR FILTERER //
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // END OVERRIDES FOR OPERATOR FILTERER //

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, PassiveStaking, TieredMetadata) {
        TieredMetadata._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981Base) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(ERC2981Base).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}