// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BLeUPunks is ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard {
    uint public MAX_SUPPLY;
    uint64 public MAX_MINT_PER_WALLET;
    string private BASE_URI;
    bool public SALE_IS_ACTIVE = true;
    bool public METADATA_FROZEN;

    constructor(uint _maxSupply,
        uint64 maxMintPerWallet,
        string memory baseUri) ERC721A("BLeUPunks", "BLeUP") {
        MAX_SUPPLY = _maxSupply;
        MAX_MINT_PER_WALLET = maxMintPerWallet;
        BASE_URI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function maxSupply() external view returns (uint) {
        return MAX_SUPPLY;
    }

    /** SETTERS **/
    function setMaxMintPerWallet(uint64 maxMint) external onlyOwner {
        MAX_MINT_PER_WALLET = maxMint;
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

    function mint(uint32 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(SALE_IS_ACTIVE, "Sale not started");
        require(_currentIndex < MAX_SUPPLY - 333, "Remaining mints are reserved.");

        uint64 usedMints = _getAux(msg.sender);
        uint64 remainingMints = 0;
        if (MAX_MINT_PER_WALLET > usedMints) {
            remainingMints = MAX_MINT_PER_WALLET - usedMints;
        }

        require(remainingMints >= _mintAmount, "Mint limit exceeded.");

        _setAux(msg.sender, usedMints + _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
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