// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheWizards is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public price = 0.0035 ether;
    uint256 public maxSupply = 7777;
    uint256 public maxFreeSupply = 7777;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 10;
    uint256 public maxFreePerWallet = 1;
    uint256 public totalNormalMint;
    uint256 public totalFreeMinted;
    uint256 public publicSalesTimestamp = 1705258550;

    mapping(address => bool) public freeMinted;
    mapping(address => uint256) private _totalNormalMintPerAccount;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("The Wizards", "WIZARDS") EIP712("The Wizards", "1.0.0") {}

    function mint(uint256 amount) external payable {
        require(totalNormalMint < maxSupply, "Normal mint reached max supply");
        require(totalSupply() + amount <= maxSupply, "Sold Out");
        require(isPublicSalesActive(), "Sales is not active");
        require(amount > 0, "Invalid amount");
        require(amount <= maxPerTx, "Max per TX reached.");

        if (freeMinted[_msgSender()]) {
            require(msg.value >= price * amount, "Insufficient funds!");
            require(
                amount + totalNormalMint <= maxSupply,
                "amount exceeds max supply"
            );
            require(
                amount + _totalNormalMintPerAccount[msg.sender] + 1 <=
                    maxPerWallet,
                "max tokens per account reached"
            );

            totalNormalMint += amount;
            _totalNormalMintPerAccount[msg.sender] += amount;
        } else {
            require(
                totalFreeMinted < maxFreeSupply,
                "Freemint reached max supply!"
            );
            require(msg.value >= price * amount - price, "Insufficient funds!");
            require(
                amount + totalNormalMint <= maxSupply,
                "Amount exceeds max supply"
            );
            require(
                amount + _totalNormalMintPerAccount[msg.sender] <= maxPerWallet,
                "Max tokens per account reached"
            );

            totalFreeMinted += 1;
            freeMinted[_msgSender()] = true;
            totalNormalMint += amount - 1;
            _totalNormalMintPerAccount[msg.sender] += amount - 1;
        }

        _safeMint(_msgSender(), amount);
    }

    function batchMint(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "addresses and amounts doesn't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function totalNormalMintPerAccount(address account)
        public
        view
        returns (uint256)
    {
        return _totalNormalMintPerAccount[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    //
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
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
}