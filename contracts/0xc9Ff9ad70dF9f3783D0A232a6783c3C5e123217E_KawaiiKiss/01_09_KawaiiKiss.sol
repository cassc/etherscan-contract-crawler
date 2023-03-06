// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// import "erc721a/contracts/extensions/ERC721ABurnable.sol";


contract KawaiiKiss is ERC721A, Ownable, DefaultOperatorFilterer {

    bool public isSaleActive;

    uint256 public max_supply = 999;
    uint256 public price = 0.0066 ether;
    uint256 public per_wallet = 5;

    mapping(address => uint256) WALLETS_MINTS;

    string private baseUri;

    constructor() ERC721A("Kawaii Kiss", "KSS") {
        isSaleActive = false;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(uint256 quantity) external payable {
        require(isSaleActive, "Public sale has not started yet");
        require(quantity > 0, "Quantity cannot be 0");
        require(
            WALLETS_MINTS[msg.sender] + quantity <= per_wallet,
            "Mint limit reached for this wallet"
        );
        require(
            totalSupply() + quantity <= max_supply,
            "Not enough NFTs left to mint"
        );
        require(
            price * quantity <= msg.value,
            "Insufficient funds sent"
        );

        WALLETS_MINTS[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function airdrop(uint256 quantity, address to) external onlyOwner {
        require(quantity > 0, "Quantity cannot be 0");
        require(
            totalSupply() + quantity <= max_supply,
            "Not enough NFTs left to mint"
        );
        _safeMint(to, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPerWallet(uint256 _per) external onlyOwner {
        per_wallet = _per;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
}