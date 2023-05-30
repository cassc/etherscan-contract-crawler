// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MutantZukis is ERC721A, ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRE_SALE_PRICE;
    uint256 public PUBLIC_PRICE;
    uint256 public MAX_SUPPLY;
    string private BASE_URI;
    uint32 public MAX_MINT_AMOUNT_PER_TX_PRE_SALE;
    uint32 public MAX_MINT_AMOUNT_PER_TX_PUBLIC_SALE;
    uint256 public TOTAL_FREE_MINT_COUNT;

    uint8 public SALE_STATE = 0; // 0: Disabled, 1: Pre, 2: Public
    bool public METADATA_FROZEN;

    address private SIGNER;

    uint256 public totalFreeMinted;

    constructor(uint256 preSalePrice,
        uint256 publicSalePrice,
        uint256 maxSupply,
        string memory baseUri,
        uint32 maxMintPerTxPre,
        uint32 maxMintPerTxPublic,
        uint256 totalFreeMintCount,
        address signer) ERC721A("MutantZukis", "MUTANT") {
        PRE_SALE_PRICE = preSalePrice;
        PUBLIC_PRICE = publicSalePrice;
        MAX_SUPPLY = maxSupply;
        BASE_URI = baseUri;
        MAX_MINT_AMOUNT_PER_TX_PRE_SALE = maxMintPerTxPre;
        MAX_MINT_AMOUNT_PER_TX_PUBLIC_SALE = maxMintPerTxPublic;
        TOTAL_FREE_MINT_COUNT = totalFreeMintCount;
        SIGNER = signer;
    }

    /** GETTERS **/

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getClaimedFreeMints(address minter) external view returns (uint32) {
        uint64 packedData = _getAux(minter);
        return getFreeMints(packedData);
    }

    function getClaimedALMints(address minter) external view returns (uint32) {
        uint64 packedData = _getAux(minter);
        return getAllowListMints(packedData);
    }

    /** SETTERS **/

    function setSigner(address signer) external onlyOwner {
        SIGNER = signer;
    }

    function setPrice(uint256 pre, uint256 pub) external onlyOwner {
        PRE_SALE_PRICE = pre;
        PUBLIC_PRICE = pub;
    }

    function lowerMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "Invalid new max supply");
        require(newMaxSupply >= _currentIndex, "Invalid new max supply");
        MAX_SUPPLY = newMaxSupply;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        require(!METADATA_FROZEN, "Metadata frozen!");
        BASE_URI = customBaseURI_;
    }

    function setMaxMintPerTx(uint32 pre, uint32 pub) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX_PRE_SALE = pre;
        MAX_MINT_AMOUNT_PER_TX_PUBLIC_SALE = pub;
    }

    function setTotalFreeMintCount(uint256 count) external onlyOwner {
        TOTAL_FREE_MINT_COUNT = count;
    }

    function setSaleState(uint8 state) external onlyOwner {
        SALE_STATE = state;
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

    modifier mintCompliance(uint256 _mintAmount) {
        require(_currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        _;
    }

    function mint(uint32 _mintAmount, bytes memory signature, uint32 freeMints, bool allowlisted) public payable mintCompliance(_mintAmount) {
        uint64 packedData = _getAux(msg.sender);
        uint256 remainingFreeMints = uint256(freeMints - getFreeMints(packedData));
        require(_mintAmount <= (SALE_STATE == 1 ? MAX_MINT_AMOUNT_PER_TX_PRE_SALE : MAX_MINT_AMOUNT_PER_TX_PUBLIC_SALE) || _mintAmount <= remainingFreeMints, "Mint limit exceeded!");
        require(_currentIndex >= 10, "First 10 mints are reserved for the owner!");
        require(SALE_STATE > 0, "Sale not started");

        bool inAllowList = allowlisted && recoverSigner(keccak256(abi.encodePacked(msg.sender, freeMints)), signature) == SIGNER;
        require(SALE_STATE == 2 || inAllowList, "You are not in allowlist");

        uint256 price = (inAllowList ? PRE_SALE_PRICE : PUBLIC_PRICE) * _mintAmount;

        uint256 remainingAllowListMints = uint256(MAX_MINT_AMOUNT_PER_TX_PRE_SALE - getAllowListMints(packedData));

        require(SALE_STATE == 2 || _mintAmount <= remainingAllowListMints || _mintAmount <= remainingFreeMints, "Trying to mint too much");

        uint256 freeMinted = 0;

        if (freeMints > 0 && inAllowList && remainingFreeMints > 0) {
            if (_mintAmount >= remainingFreeMints) {
                price -= remainingFreeMints * PRE_SALE_PRICE;
                freeMinted = remainingFreeMints;
                remainingFreeMints = 0;
            } else {
                price -= _mintAmount * PRE_SALE_PRICE;
                freeMinted = _mintAmount;
                remainingFreeMints -= _mintAmount;
            }
        }

        if (_currentIndex == MAX_SUPPLY - TOTAL_FREE_MINT_COUNT + totalFreeMinted) {
            require(_mintAmount <= freeMinted, "Max supply exceeded. (except reserves)");
        }

        if (inAllowList && SALE_STATE == 1) {
            remainingAllowListMints = freeMinted + remainingAllowListMints - _mintAmount;
        }
        require(msg.value == price, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);

        totalFreeMinted += freeMinted;
        _setAux(msg.sender, pack(uint32(freeMints - remainingFreeMints), uint32(MAX_MINT_AMOUNT_PER_TX_PRE_SALE - remainingAllowListMints)));
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
    0x814BbbbFb837B5a7318BacB6702B6f2829D55Ddd; // T

    address private constant payoutAddress2 =
    0x0fD105F5262d3114ab1a3D52877C4b295c2FE223; // H

    address private constant payoutAddress3 =
    0x4a9171794e3b11a12F3D781adDDb0B308DD0B66D; // N

    address private constant payoutAddress4 =
    0xc5A51039527183103B7A4941154F93245e755C8f; // M

    address private constant payoutAddress5 =
    0x03d5C6ab1E17085f098676C759b66c2127c39A9c; // C

    address private constant payoutAddress6 =
    0x2Db6115ABEb6D32819Be22bF1ba3755Ff53351ec; // V

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance * 25 / 100);

        Address.sendValue(payable(payoutAddress2), balance * 25 / 100);

        Address.sendValue(payable(payoutAddress3), balance * 25 / 100);

        Address.sendValue(payable(payoutAddress4), balance * 10 / 100);

        Address.sendValue(payable(payoutAddress5), balance * 8 / 100);

        Address.sendValue(payable(payoutAddress6), balance * 7 / 100);
    }

    /** UTILS **/

    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );

        return ECDSA.recover(messageDigest, signature);
    }

    function pack(uint32 a, uint32 b) pure internal returns (uint64) {
        uint64 fnl = 0x0;
        uint64 shiftedA = uint64(a) << 32;
        fnl = fnl | shiftedA;
        fnl = fnl | uint64(b);
        return fnl;
    }

    function unpack(uint64 packed, uint8 which) pure internal returns (uint32) {
        uint32 a = uint32(packed >> 32);
        uint32 b = uint32((packed) % 2 ** 32);

        if (which == 0) return a;
        else return b;
    }

    function getFreeMints(uint64 packed) pure internal returns (uint32) {
        return unpack(packed, 0);
    }

    function getAllowListMints(uint64 packed) pure internal returns (uint32) {
        return unpack(packed, 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}