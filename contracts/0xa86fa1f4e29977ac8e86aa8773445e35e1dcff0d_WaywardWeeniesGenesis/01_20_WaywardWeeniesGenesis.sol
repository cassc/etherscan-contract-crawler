// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract WaywardWeeniesGenesis is
    ERC721,
    Pausable,
    Ownable,
    ERC721Burnable,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    using Strings for uint256;
    address public vault;
    uint256 public constant SILVER_OFFSET = 10000;
    uint256 public constant GOLD_OFFSET = 20000;
    string public uriPrefix =
        "https://weeniesmorph.s3.amazonaws.com/weenies_morph_json_prereveal/";
    string public uriSuffix = ".json";
    IERC721 public oldWeeniesCollection;
    bool public mintPaused = false;
    uint256 public maxMintAmountPerTx = 20;
    uint256 public currentWeenieId = 449;

    uint256 public constant STANDARD_MINT_COST = 0.02 ether;
    uint256 public constant SILVER_MINT_COST = 0.022 ether;
    uint256 public constant GOLD_MINT_COST = 0.024 ether;

    constructor(
        address _oldWeeniesCollection,
        address _vault
    ) ERC721("WaywardWeeniesGenesis", "WWG") {
        oldWeeniesCollection = IERC721(_oldWeeniesCollection);
        vault = _vault;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(!mintPaused, "The mint is paused!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function transferWeeniesToVault(uint256[] calldata ids) private {
        require(
            oldWeeniesCollection.isApprovedForAll(msg.sender, address(this)),
            "Must set approval for the old Weenies collection"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            oldWeeniesCollection.safeTransferFrom(msg.sender, vault, ids[i]);
        }
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintFor(address to, uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                !_exists(tokenIds[i]) &&
                    !_exists(tokenIds[i] + SILVER_OFFSET) &&
                    !_exists(tokenIds[i] + GOLD_OFFSET),
                "Token already exists or has been morphed"
            );
            _safeMint(to, tokenIds[i]);
        }
    }

    function standardMint(
        uint256[] calldata ids
    ) external mintCompliance(ids.length) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                oldWeeniesCollection.ownerOf(ids[i]) == msg.sender,
                "Not owner of the NFT"
            );
            require(
                !_exists(ids[i]) &&
                    !_exists(ids[i] + SILVER_OFFSET) &&
                    !_exists(ids[i] + GOLD_OFFSET),
                "Token already exists or has been morphed"
            );
        }

        transferWeeniesToVault(ids);

        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(msg.sender, ids[i]);
        }
    }

    function silverMint(
        uint256[] calldata ids
    ) external payable mintCompliance(ids.length) {
        require(msg.value >= 0.002 ether * ids.length, "Insufficient payment");

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                oldWeeniesCollection.ownerOf(ids[i]) == msg.sender,
                "Not owner of the NFT"
            );
            require(
                !_exists(ids[i]) &&
                    !_exists(ids[i] + SILVER_OFFSET) &&
                    !_exists(ids[i] + GOLD_OFFSET),
                "Token already exists or has been morphed"
            );
        }

        transferWeeniesToVault(ids);

        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(msg.sender, ids[i] + SILVER_OFFSET);
        }
    }

    function goldMint(
        uint256[] calldata ids
    ) external payable mintCompliance(ids.length) {
        require(msg.value >= 0.004 ether * ids.length, "Insufficient payment");

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                oldWeeniesCollection.ownerOf(ids[i]) == msg.sender,
                "Not owner of the NFT"
            );
            require(
                !_exists(ids[i]) &&
                    !_exists(ids[i] + SILVER_OFFSET) &&
                    !_exists(ids[i] + GOLD_OFFSET),
                "Token already exists or has been morphed"
            );
        }

        transferWeeniesToVault(ids);

        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(msg.sender, ids[i] + GOLD_OFFSET);
        }
    }

    function newStandardMint(
        uint256 _mintAmount
    ) external payable mintCompliance(_mintAmount) {
        require(
            currentWeenieId + _mintAmount <= 4445,
            "Exceeds max Standard Weenies"
        );
        require(
            msg.value == _mintAmount * STANDARD_MINT_COST,
            "Incorrect Ether sent"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, currentWeenieId);
            currentWeenieId++;
        }
    }

    function newSilverMint(
        uint256 _mintAmount
    ) external payable mintCompliance(_mintAmount) {
        require(
            currentWeenieId + SILVER_OFFSET + _mintAmount <= 14445,
            "Exceeds max Silver Weenies"
        );
        require(
            msg.value == _mintAmount * SILVER_MINT_COST,
            "Incorrect Ether sent"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, currentWeenieId + SILVER_OFFSET);
            currentWeenieId++;
        }
    }

    function newGoldMint(
        uint256 _mintAmount
    ) external payable mintCompliance(_mintAmount) {
        require(
            currentWeenieId + GOLD_OFFSET + _mintAmount <= 24445,
            "Exceeds max Gold Weenies"
        );
        require(
            msg.value == _mintAmount * GOLD_MINT_COST,
            "Incorrect Ether sent"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, currentWeenieId + GOLD_OFFSET);
            currentWeenieId++;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) external onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMintPaused(bool _state) external onlyOwner {
        mintPaused = _state;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
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
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Ether");
    }
}