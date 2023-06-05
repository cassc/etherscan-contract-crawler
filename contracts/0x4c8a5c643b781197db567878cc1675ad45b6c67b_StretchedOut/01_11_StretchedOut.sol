//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721a/contracts/ERC721A.sol";

contract StretchedOut is Ownable, ERC721A, ERC2981, ReentrancyGuard {
    enum SalePhase {
        unavailable,
        whitelistMint,
        publicMint
    }

    bool public IS_REVEALED = false;

    bytes32 public rootHash =
        0x0abfed61bbea364d87dd4413f5af2150f8dc953f237b63ce1610076c46e5143a;

    uint96 public ROYALTY_PERCENTAGE = 750;

    uint256 public immutable MAX_FREE_PER_WALLET = 1;
    uint256 public immutable MAX_SUPPLY = 6666;
    uint256 public immutable MAX_TX_PER_WALLET = 2;
    uint256 public immutable SALE_PRICE = 0.008 ether;
    uint256 public immutable MAX_WHITELIST_TX = 5000;

    string internal prerevealURI = "";
    string internal baseURI = "";

    SalePhase public SALE_PHASE = SalePhase.whitelistMint;

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    constructor() ERC721A("StretchedOut", "StretchedOut") {
        _setDefaultRoyalty(owner(), ROYALTY_PERCENTAGE);
    }

    function internalMint(address buyerAddress, uint256 quantity)
        external
        onlyOwner
        nonReentrant
        isUser
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");

        _mint(buyerAddress, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return IS_REVEALED ? baseURI : prerevealURI;
    }

    function getIsWhitelisted(bytes32[] memory merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isProofValid = MerkleProof.verify(merkleProof, rootHash, leaf);

        return isProofValid;
    }

    function whitelistMint(uint256 quantity, bytes32[] memory merkleProof)
        public
        payable
        virtual
        nonReentrant
        isUser
    {
        require(
            SALE_PHASE == SalePhase.whitelistMint,
            "Not in whitelist mint phase"
        );
        require(getIsWhitelisted(merkleProof), "Invalid Proof");
        require(
            totalSupply() + quantity <= MAX_WHITELIST_TX,
            "Max whitelist supply reached"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET,
            "Max tx per wallet reached"
        );
        require(
            msg.value >= getSalePrice(msg.sender, quantity),
            "Insufficient funds"
        );

        _mint(msg.sender, quantity);
    }

    function externalMint(uint256 quantity)
        public
        payable
        virtual
        nonReentrant
        isUser
    {
        require(
            SALE_PHASE == SalePhase.publicMint,
            "Public mint phase has not started"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET,
            "Exceeded tx limit"
        );
        require(
            msg.value >= getSalePrice(msg.sender, quantity),
            "Insufficient funds"
        );

        _mint(msg.sender, quantity);
    }

    function getTotalMinted(address addr)
        external
        view
        virtual
        returns (uint256)
    {
        return _numberMinted(addr);
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setPrerevealURI(string memory newURI) external virtual onlyOwner {
        prerevealURI = newURI;
    }

    function setIsRevealed(bool isRevealed) external virtual onlyOwner {
        IS_REVEALED = isRevealed;
    }

    function setSalePhase(SalePhase salePhase) external onlyOwner {
        SALE_PHASE = salePhase;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner nonReentrant isUser {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }

    function getSalePrice(address sender, uint256 quantity)
        private
        view
        returns (uint256)
    {
        return
            _numberMinted(sender) > 0
                ? SALE_PRICE * (quantity)
                : SALE_PRICE * (quantity - MAX_FREE_PER_WALLET);
    }
}