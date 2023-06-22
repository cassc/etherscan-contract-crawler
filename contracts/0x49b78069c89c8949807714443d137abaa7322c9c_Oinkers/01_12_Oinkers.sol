// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "ERC721A/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Oinkers is Ownable, ERC721A, DefaultOperatorFilterer {
    using Strings for uint256;

    error MintInactive();
    error ContractCaller();
    error InvalidAmount();
    error ExceedsSupply();
    error InvalidValue();
    error LengthsDoNotMatch();
    error InvalidToken();
    error ExceedsMaxMintPerWallet();

    string public baseURI;
    string public hiddenURI;

    uint256 public price = 0.002 ether;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public constant MAX_MINT_PER_WALLET = 5;

    bool public saleActive = false;
    bool public isRevealed = false;

    mapping(address => bool) hasMinted;

    constructor() ERC721A("Oinkers", "OINKERS") Ownable(msg.sender) {
      _mint(msg.sender, 1);
    }

    function mint(uint256 mintAmount_) public payable {
        if (!saleActive) revert MintInactive();
        if (msg.sender != tx.origin) revert ContractCaller();
        if (mintAmount_ > MAX_PER_TX) revert InvalidAmount();
        unchecked {
            if (mintAmount_ + totalSupply() > MAX_SUPPLY)
                revert ExceedsSupply();
            if (_numberMinted(msg.sender) + mintAmount_ > MAX_MINT_PER_WALLET)
                revert ExceedsMaxMintPerWallet();
            if (hasMinted[msg.sender]) {
                if (msg.value != mintAmount_ * price) revert InvalidValue();
            } else {
                if (msg.value != (mintAmount_ - 1) * price)
                    revert InvalidValue();
            }
        }
        hasMinted[msg.sender] = true;
        _mint(msg.sender, mintAmount_);
    }

    function mintForAddress(uint256 mintAmount_, address to_)
        external
        onlyOwner
    {
        if (mintAmount_ + totalSupply() > MAX_SUPPLY) revert ExceedsSupply();
        _mint(to_, mintAmount_);
    }

    function batchMintForAddresses(
        address[] calldata addresses_,
        uint256[] calldata amounts_
    ) external onlyOwner {
        if (addresses_.length != amounts_.length) revert LengthsDoNotMatch();
        unchecked {
            for (uint32 i = 0; i < addresses_.length; i++) {
                if (amounts_[i] + totalSupply() > MAX_SUPPLY)
                    revert ExceedsSupply();
                _mint(addresses_[i], amounts_[i]);
            }
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function flipSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory newBaseURI_) external onlyOwner {
        baseURI = newBaseURI_;
    }

    function reveal() external onlyOwner {
      isRevealed = true;
    }

    function setHiddenURI(string memory newHiddenURI) external onlyOwner {
      hiddenURI = newHiddenURI;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId_)) revert InvalidToken();
        if (isRevealed != true) return hiddenURI;
        return string(abi.encodePacked(baseURI, tokenId_.toString(), ".json"));
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
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}