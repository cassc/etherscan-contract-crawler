// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./DefaultOperatorFilterer.sol";

contract PutinDigitalTradingCards is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintPerAccount = 20;
    uint256 public totalNormalMint;
    uint256 public maxFreeMintSupply = 700;
    uint256 public totalFreeMint;
    uint256 public publicSalesTimestamp = 1671505200;

    mapping(address => bool) public freeMinted;
    mapping(address => uint256) private _totalNormalMintPerAccount;

    string private _contractUri;
    string private _baseUri;

    constructor()
        ERC721A("Putin Digital Trading Cards", "PUTIN")
        EIP712("PutinDigitalTradingCards", "1.0.0")
    {}

    function mint(uint256 amount) external payable {
        require(totalNormalMint < maxSupply, "normal mint reached max supply");
        require(isPublicSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");

        if (freeMinted[_msgSender()]) {
            require(msg.value >= mintPrice * amount, "Insufficient funds!");
            require(
                amount + totalNormalMint <= maxSupply,
                "amount exceeds max supply"
            );
            require(
                amount + _totalNormalMintPerAccount[msg.sender] <=
                    maxMintPerAccount,
                "max tokens per account reached"
            );

        } else {
            require(
                totalFreeMint < maxFreeMintSupply,
                "Freemint reached max supply!"
            );
            require(
                msg.value >= mintPrice * amount - mintPrice,
                "Insufficient funds!"
            );
            require(
                (amount - 1) + totalNormalMint <= maxSupply,
                "amount exceeds max supply"
            );
            require(
                (amount - 1) + _totalNormalMintPerAccount[msg.sender] <=
                    maxMintPerAccount,
                "max tokens per account reached"
            );

            totalFreeMint += 1;
            freeMinted[_msgSender()] = true;
        }
        totalNormalMint += amount - 1;
        _totalNormalMintPerAccount[msg.sender] += amount - 1;
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

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setmintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setmaxMintPerAccount(uint256 maxMintPerAccount_)
        external
        onlyOwner
    {
        maxMintPerAccount = maxMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    //
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}