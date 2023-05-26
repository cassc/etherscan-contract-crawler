// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721A } from 'erc721a/contracts/ERC721A.sol';
import { ERC2981 } from '@openzeppelin/contracts/token/common/ERC2981.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract AmbushTerminalGasoline is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {

    error MintNotEnabled();
    error WrongAmount();
    error AlreadyMinted();
    error SoldOut();

    string public baseURI;
    bool private uniqueTokenUri = false;
    bool public paused = true;
    uint256 public maxSupply = 100;
    uint256 public price = 0.09 ether;

    constructor() ERC721A("Ambush Terminal Gasoline", "AMBTERMGAS") {
        _setDefaultRoyalty(0xC71Df678A0026861d1975EbD7478E73F3845A2ce, 250);
        _mint(owner(), 1);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setBaseURI(string memory baseURI_, bool unique) external onlyOwner { 
        uniqueTokenUri = unique;
        baseURI = baseURI_;
    }

    function setMintEnabled(bool enabled) external onlyOwner {
        paused = !enabled;
    }

    function ownerMint(address[] calldata recipients) external onlyOwner {
        uint256 count = recipients.length;
        if (count + totalSupply() > maxSupply) {
            revert SoldOut();
        }

        for (uint256 i; i < count;) {
            _mint(recipients[i], 1);
            unchecked {
                ++i;
            }
        }
    }

    function mint() external payable {
        if (paused) {
            revert MintNotEnabled();
        }
        if (msg.value != price) {
            revert WrongAmount();
        }
        if (_numberMinted(msg.sender) > 0) {
            revert AlreadyMinted();
        }
        if (totalSupply() >= maxSupply) {
            revert SoldOut();
        }

        _safeMint(msg.sender, 1);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool successA, ) = payable(0xC71Df678A0026861d1975EbD7478E73F3845A2ce)
            .call{value: balance}("");
        require(successA, "Withdraw failed");
        assert(address(this).balance == 0);
    }

    function supportsInterface(bytes4 interfaceId) public override(ERC721A, ERC2981) view returns (bool) {
        return ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (uniqueTokenUri) {
            return ERC721A.tokenURI(tokenId);
        }

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? baseURI : '';
    }

    function minted(address wallet) external view returns (bool) {
        return _numberMinted(wallet) > 0;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*
        Operator filter overrides
    */
   function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}