// SPDX-License-Identifier: MIT

/*
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
·:··:::··:·····::··::::::·····:::::··:··::··:::··:·····::··::::::·····:::::··:··:
:::::::::::::::::::::::::::::: Hop3 Minting Contract ::::::::::::::::::::::::::::
.:..:::..:.....::..::::::.....:::::..:..::..:::..:.....::..::::::.....:::::..:...
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
·:··:::··:·····::··::::::·····:::::··:··::··:::··:·····::··::::::·····:::::··:··:
:::::::::::: 88        88    ,ad8888ba,    88888888ba    ad888888b,  ::::::::::::
:::::::::::: 88        88   d8"'    `"8b   88      "8b  d8"     "88  ::::::::::::
:::::::::::: 88        88  d8'        `8b  88      ,8P          a8P  ::::::::::::
:::::::::::: 88aaaaaaaa88  88          88  88aaaaaa8P'       aad8"   ::::::::::::
:::::::::::: 88""""""""88  88          88  88""""""'         ""Y8,   ::::::::::::
:::::::::::: 88        88  Y8,        ,8P  88                   "8b  ::::::::::::
:::::::::::: 88        88   Y8a.    .a8P   88           Y8,     a88  ::::::::::::
:::::::::::: 88        88    `"Y8888Y"'    88            "Y888888P'  ::::::::::::
.:..:::..:.....::..::::::.....:::::..:..::..:::..:.....::..::::::.....:::::..:...
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IHop3Cr3ds.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Hop3 is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter,
    DefaultOperatorFilterer
{
    using ECDSA for bytes32;

    string public baseURI;

    uint256 public maxSupply = 10000;
    uint256 public walletLimit = 6;

    uint256 public preSalePrice = 0.15 ether;
    uint256 public publicPrice = 0.3 ether;
    uint256 public txLimit = 2;
    bool public preSale;
    bool public publicSale;

    address public Hop3Cr3ds;

    address public signer;
    mapping(bytes => bool) public signatureUsed;

    // mapping(address => bool) public Hop3WhitelistClaimed;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721A("HOP3", "HOP3")
        PaymentSplitter(payees, shares)
    {}

    modifier senderCheck() {
        require(tx.origin == msg.sender);
        _;
    }

    modifier saleActive() {
        require(isMintLive(), "Sale is not live");
        _;
    }

    modifier preSaleActive() {
        require(isPreSaleLive(), "Presale is not live");
        _;
    }

    function preSaleMint(
        uint256 amount,
        bytes32 hash,
        bytes memory signature
    ) external payable nonReentrant senderCheck preSaleActive {
        uint256 qtyMinted = _numberMinted(msg.sender);

        require(recoverSigner(hash, signature) == signer, "Invalid signature.");
        require(!signatureUsed[signature], "Signature has already been used.");

        require(!isMintLive(), "Public sale has already started!");

        require(
            qtyMinted + amount <= walletLimit,
            "You have already minted a max of 5 HOP3s!"
        );
        require(totalSupply() + amount <= maxSupply, "Sorry, Sold out!");
        require(
            msg.value == amount * preSalePrice,
            "Please send the correct amount of ether."
        );
        require(
            amount <= txLimit,
            "You can only mint 2 HOP3s per transaction!"
        );

        _mint(msg.sender, amount);

        signatureUsed[signature] = true;
    }

    function mint(uint256 amount)
        external
        payable
        nonReentrant
        senderCheck
        saleActive
    {
        uint256 qtyMinted = _numberMinted(msg.sender);

        require(
            qtyMinted + amount <= walletLimit,
            "You have already minted a max of 5 HOP3s!"
        );
        require(totalSupply() + amount <= maxSupply, "Sorry, Sold out!");
        require(
            msg.value == amount * publicPrice,
            "Please send the correct amount of ether."
        );
        require(
            amount <= txLimit,
            "You can only mint 2 HOP3s per transaction!"
        );

        _mint(msg.sender, amount);
    }

    function burnHop(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function isMintLive() public view returns (bool) {
        return _totalMinted() < maxSupply && publicSale;
    }

    function isPreSaleLive() public view returns (bool) {
        return _totalMinted() < maxSupply && preSale;
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        require(totalSupply() + amount <= maxSupply);

        _mint(msg.sender, amount);
    }

    function togglePreSaleState() external onlyOwner {
        require(!isMintLive(), "Public sale has already started!");

        preSale = !preSale;
    }

    function togglePublicSaleState() external onlyOwner {
        require(!isPreSaleLive(), "Pre sale has not stopped yet!");

        publicSale = !publicSale;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        walletLimit = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from != address(0)) {
            IHop3Cr3ds(Hop3Cr3ds).stopDripping(from, uint128(quantity));
        }

        if (to != address(0)) {
            IHop3Cr3ds(Hop3Cr3ds).startDripping(to, uint128(quantity));
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setHop3TokenAddress(address _hop3Token) external onlyOwner {
        Hop3Cr3ds = _hop3Token;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}