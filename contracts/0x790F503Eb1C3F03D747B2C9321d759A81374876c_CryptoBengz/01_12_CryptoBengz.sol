// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Delegates.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoBengz is ERC721A, ReentrancyGuard, Delegated, DefaultOperatorFilterer {
    using Strings for uint256;
    address public artistAddress;
    uint256 public constant MAX_MINT = 20;

    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 3888;

    // ======== PRICE ========
    uint256 public phase_1_Price = 0.03 ether;
    uint256 public phase_2_Price = 0.1 ether;
    uint256 public phase_3_Price = 0.045 ether;

    // ======== SALE STATUS ========
    uint8 public currentMintBatch;

    // ======== METADATA ========
    bool public isRevealed = false;
    string private _baseTokenURI;
    string private notRevealedURI;
    string private baseExtension = ".json";

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("CryoptoBengz", "CBGZ") {}

    // ======== MINTING ========
    function mintBatch1(uint256 quantity) external payable callerIsUser withinSupply(quantity) {
        require(currentMintBatch == 1, "Incorrect mint batch");
        require(msg.value >= phase_1_Price * quantity, "Incorrect ether sent");
        require(
            _numberMinted(msg.sender) + quantity * 2 <= MAX_MINT,
            "Exceeds Max Claim"
        );
        _safeMint(msg.sender, quantity * 2);
    }

    function mintBatch2(uint256 quantity) external payable callerIsUser withinSupply(quantity) {
        require(currentMintBatch == 2, "Incorrect mint batch");
        require(quantity % 2 == 0, "Must order in multiples of 2");
        require(
            msg.value >= phase_2_Price * (quantity / 2),
            "Incorrect ether sent"
        );
        require(
            _numberMinted(msg.sender)<= MAX_MINT - (quantity * 2),
            "Exceeds Max Claim"
        );
        _safeMint(msg.sender, quantity * 2);
    }

    function mintBatch3(uint256 quantity) external payable callerIsUser withinSupply(quantity) {
        require(currentMintBatch == 3, "Incorrect mint batch");
        require(msg.value >= phase_3_Price * quantity, "Incorrect ether sent");
        require(
            _numberMinted(msg.sender) <= MAX_MINT - (quantity),
            "Exceeds Max Claim"
        );
        _safeMint(msg.sender, quantity);
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        _safeMint(msg.sender, _quantity);
    }

    // ======== SETTERS ========
    /**
     * @dev Owner/Delegate sets the Whitelist active flag.
     */
    function setCurrentMintBatch(uint8 _batch) external onlyOwner {
        currentMintBatch = _batch;
    }

    function setPhase1Price(uint256 _price) external onlyOwner {
        phase_1_Price = _price;
    }

    function setPhase2Price(uint256 _price) external onlyOwner {
        phase_2_Price = _price;
    }

    function setPhase3Price(uint256 _price) external onlyOwner {
        phase_3_Price = _price;
    }

    function setBaseURI(string calldata baseURI) external onlyDelegates {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        public
        onlyDelegates
    {
        notRevealedURI = _notRevealedURI;
    }

    function setIsRevealed(bool _reveal) external onlyDelegates {
        isRevealed = _reveal;
    }

    function setArtistAddress(address _artistAddress) external onlyOwner {
        artistAddress = _artistAddress;
    }

    // ======== WITHDRAW ========

    function withdraw(uint256 amount_) external onlyOwner {
        require(
            address(this).balance >= amount_,
            "Address: insufficient balance"
        );

        require(artistAddress != address(0), "Artist address not set");

        // This will pay the artist 12% of the initial sale.
        // =============================================================================
        (bool hs, ) = payable(artistAddress).call{value: (amount_ * 12) / 100}(
            ""
        );
        require(hs);
        // =============================================================================

        // This will payout the owner the remaining 88% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: (amount_ * 88) / 100}("");
        require(os);
        // =============================================================================
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "Zero Balace");
        require(artistAddress != address(0), "Artist address not set");

        // This will pay the artist 12% of the initial sale.
        // =============================================================================
        (bool hs, ) = payable(artistAddress).call{
            value: (address(this).balance * 12) / 100
        }("");
        require(hs);
        // =============================================================================

        // This will payout the owner the remaining 88% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{
            value: (address(this).balance * 88) / 100
        }("");
        require(os);
        // =============================================================================
    }

    // ===== OPENSEA OVERRIDES =====

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return notRevealedURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    // ===== MODIFIERS =====

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier withinSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        _;
    }
}