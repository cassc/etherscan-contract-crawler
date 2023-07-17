// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MintDefense is
    ERC721A,
    ERC2981,
    Pausable,
    Ownable,
    DefaultOperatorFilterer
{
    using ECDSA for bytes32;
    address private signer;
    address public payoutWallet;

    address private _recipient;
    uint256 private _royaltyPercentage;

    uint16 public immutable MAX_SUPPLY;
    uint8 public immutable MAX_MINTS_PER_TX;

    uint8 flags;

    uint72 public privateMintPrice;
    uint72 public publicMintPrice;

    uint8 constant PUBLIC_MINT_OPEN = 0x01;
    uint8 constant PRIVATE_MINT_OPEN = 0x02;
    uint8 constant PREPAID_MINT_OPEN = 0x04;

    mapping(uint256 => bytes32) private tokenLicences;
    string private _baseTokenURI;

    mapping (address => bool) public blockedMarketplaces;

    constructor(
        uint16 supply_,
        uint8 maxMintsPerTx_,
        address signer_,
        address payoutWallet_,
        uint72 privateMintPrice_,
        uint72 publicMintPrice_,
        string memory baseURI_
    ) ERC721A("MintDefense Lifetime License", "MDFS") {
        MAX_SUPPLY = supply_;
        MAX_MINTS_PER_TX = maxMintsPerTx_;

        signer = signer_;

        privateMintPrice = privateMintPrice_;
        publicMintPrice = publicMintPrice_;

        payoutWallet = payoutWallet_;
        _baseTokenURI = baseURI_;

        _recipient = payoutWallet_;
        _royaltyPercentage = 5;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721A) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mint(
        uint256 quantity,
        bytes calldata signature
    ) external payable whenNotPaused {
        require(_hasFlag(PUBLIC_MINT_OPEN), "mint: not open");
        require(quantity > 0, "mint: zero quantity");
        require(quantity <= MAX_MINTS_PER_TX, "mint: quantity too high");
        require(
            quantity * publicMintPrice <= msg.value,
            "mint: insufficient funds"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint: supply exceeded"
        );

        bytes32 signedHash = keccak256(abi.encodePacked(msg.sender))
            .toEthSignedMessageHash();
        require(
            SignatureChecker.isValidSignatureNow(signer, signedHash, signature),
            "mint: unauthorized"
        );

        _safeMint(_msgSenderERC721A(), quantity);
    }

    function allowlistMint(
        uint256 quantity,
        uint256 maxMints,
        bool prepaidMint,
        bytes calldata signature
    ) external payable whenNotPaused {
        require(
            (prepaidMint && _hasFlag(PREPAID_MINT_OPEN)) ||
                _hasFlag(PRIVATE_MINT_OPEN),
            "allowlistMint: not open"
        );
        require(quantity > 0, "allowlistMint: zero quantity");
        require(
            prepaidMint || quantity * privateMintPrice <= msg.value,
            "allowlistMint: insufficient funds"
        );

        bytes32 signedHash = keccak256(
            abi.encodePacked(msg.sender, maxMints, prepaidMint)
        ).toEthSignedMessageHash();
        require(
            SignatureChecker.isValidSignatureNow(signer, signedHash, signature),
            "allowlistMint: unauthorized"
        );

        uint256 consumedAllowlists = _getAux(_msgSenderERC721A());
        require(
            consumedAllowlists + quantity <= maxMints,
            "allowlistMint: quantity too high"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "allowlistMint: supply exceeded"
        );

        _setAux(_msgSenderERC721A(), uint64(consumedAllowlists + quantity));
        _safeMint(_msgSenderERC721A(), quantity);
    }

    function findLicence(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), "findLicence: token not found");
        return tokenLicences[tokenId];
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        require(!blockedMarketplaces[operator], "Invalid marketplace, not allowed");
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        require(!blockedMarketplaces[operator], "Invalid marketplace, not allowed");
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

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "tokenURI: token not found");
        return _baseURI();
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        require(payoutWallet != address(0), "withdraw: wallet not set");
        uint256 balance = address(this).balance;
        (bool success, ) = payable(payoutWallet).call{value: balance}("");
        require(success, "withdraw: failed to send funds");
    }

    function setPrepaidMint(bool open) external onlyOwner {
        _setFlag(PREPAID_MINT_OPEN, open);
    }

    function setPrivateMint(bool open) external onlyOwner {
        _setFlag(PRIVATE_MINT_OPEN, open);
    }

    function setPublicMint(bool open) external onlyOwner {
        _setFlag(PUBLIC_MINT_OPEN, open);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setDefaultRoyalty(
        address recipient,
        uint96 value
    ) external onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setWithdrawalWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "setWithdrawalWallet: address zero");
        payoutWallet = wallet;
    }

    function _hasFlag(uint8 flag) internal view returns (bool) {
        return flag & flags > 0;
    }

    function _setFlag(uint8 flag, bool open) internal {
        if (open) {
            flags |= flag;
        } else {
            flags &= ~flag;
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from != address(0)) {
            delete tokenLicences[startTokenId];
        }
    }

    function setblockedMarketplaces(address marketplace, bool allowed) public onlyOwner{
        blockedMarketplaces[marketplace] = allowed;
    }
}