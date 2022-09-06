// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CreampiedMonaLisas is ERC721A, ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard {
    uint public PRICE;
    uint public MAX_SUPPLY;
    uint public MAX_MINT_AMOUNT_PER_TX;
    uint16 public MAX_FREE_MINTS_PER_WALLET;
    string private BASE_URI;
    bool public SALE_IS_ACTIVE = true;
    bool public METADATA_FROZEN;

    uint public totalFreeMinted;

    constructor(uint price,
        uint maxSupply,
        uint maxMintPerTx,
        uint16 maxFreeMintsPerWallet,
        string memory baseUri) ERC721A("CreampiedMonaLisas", "CML") {
        PRICE = price;
        MAX_SUPPLY = maxSupply;
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

    /** SETTERS **/

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
        require(!METADATA_FROZEN, "Metadata frozen!");
        BASE_URI = customBaseURI_;
    }

    function setSaleState(bool state) external onlyOwner {
        SALE_IS_ACTIVE = state;
    }

    function freezeMetadata() external onlyOwner {
        METADATA_FROZEN = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /** MINT **/

    modifier mintCompliance(uint _mintAmount) {
        require(_currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        _;
    }

    function getCreampied(uint32 _mintAmount) public payable mintCompliance(_mintAmount) {
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

    function creampie(address _to, uint _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    /** PAYOUT **/

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
}