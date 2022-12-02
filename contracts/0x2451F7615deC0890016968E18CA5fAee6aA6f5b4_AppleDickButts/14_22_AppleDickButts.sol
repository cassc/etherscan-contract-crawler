// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AppleDickButts is ERC721A, IERC2981, ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {
    uint public PRICE;
    uint public maxSupply;
    uint public MAX_MINT_AMOUNT_PER_TX;
    uint16 public MAX_FREE_MINTS_PER_WALLET;
    string private BASE_URI;
    bool public SALE_IS_ACTIVE = true;

    uint public totalFreeMinted;

    constructor(uint price,
        uint _maxSupply,
        uint maxMintPerTx,
        uint16 maxFreeMintsPerWallet,
        string memory baseUri) ERC721A("AppleDickButts", "ADB") {
        PRICE = price;
        maxSupply = _maxSupply;
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
        MAX_FREE_MINTS_PER_WALLET = maxFreeMintsPerWallet;
        BASE_URI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getFreeMints(address addy) external view returns (uint64) {
        return _getAux(addy);
    }

    function setPrice(uint price) external onlyOwner {
        PRICE = price;
    }

    function setMaxMintPerTx(uint maxMint) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMint;
    }

    function setMaxFreeMintsPerWallet(uint16 maxFreeMintsPerWallet) external onlyOwner {
        MAX_FREE_MINTS_PER_WALLET = maxFreeMintsPerWallet;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setSaleState(bool state) external onlyOwner {
        SALE_IS_ACTIVE = state;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier mintCompliance(uint _mintAmount) {
        require(_currentIndex + _mintAmount <= maxSupply, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        _;
    }

    function mint(uint32 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(_mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Mint limit exceeded!");
        require(SALE_IS_ACTIVE, "Sale not started");

        uint price = PRICE * _mintAmount;

        uint64 usedFreeMints = _getAux(msg.sender);
        uint64 remainingFreeMints = 0;
        if (MAX_FREE_MINTS_PER_WALLET > usedFreeMints) {
            remainingFreeMints = MAX_FREE_MINTS_PER_WALLET - usedFreeMints;
        }
        uint64 freeMinted = 0;

        if (remainingFreeMints > 0) {
            if (_mintAmount >= remainingFreeMints) {
                price -= remainingFreeMints * PRICE;
                freeMinted = remainingFreeMints;
                remainingFreeMints = 0;
            } else {
                price -= _mintAmount * PRICE;
                freeMinted = _mintAmount;
                remainingFreeMints -= _mintAmount;
            }
        }

        require(msg.value >= price, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);

        totalFreeMinted += freeMinted;
        _setAux(msg.sender, usedFreeMints + freeMinted);
    }

    function airdrop(address _to, uint _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

     function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }

}