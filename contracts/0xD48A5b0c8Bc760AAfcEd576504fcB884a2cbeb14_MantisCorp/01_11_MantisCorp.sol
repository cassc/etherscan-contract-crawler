//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract MantisCorp is Ownable, ERC721A, ERC2981, ReentrancyGuard {
    enum Phase {
        unavailable,
        whitelistMint,
        publicMint
    }

    bool public IS_REVEALED = false;
    bytes32 public rootHash =
        0xcfebd697a7d7f93b99584a7e37a07ab60a7a308a55a68faa504978e0933cdaa4;
    Phase public PHASE = Phase.unavailable;
    uint96 public ROYALTY_FEE_NUMERATOR = 750;
    uint256 public TOTAL_SUPPLY = 6666;
    uint256 public immutable MAX_FREE_PER_WALLET = 1;
    uint256 public immutable MAX_TX_PER_WALLET = 3;
    uint256 public immutable PRICE = 0.007 ether;
    string internal reviewURI = "";
    string internal baseURI = "";

    modifier isFundsSufficient(uint256 quantity) {
        require(msg.value >= getSalePrice(msg.sender, quantity), "Insufficient funds");
        _;
    }

    modifier isMaxSupplyReached(uint256 quantity) {
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Max supply reached");
        _;
    }

    modifier isMaxTxReached(uint256 quantity) {
        require(_numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET, "Exceeded tx limit");
        _;
    }

    modifier isTxValid() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    constructor() ERC721A("MantisCorp", "MantisCorp") {
        _setDefaultRoyalty(owner(), ROYALTY_FEE_NUMERATOR);
    }

    function getTotalSupplyLeft() public view returns (uint256) {
        return TOTAL_SUPPLY - totalSupply();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return IS_REVEALED ? baseURI : reviewURI;
    }

    function isWhitelisted(bytes32[] memory merkleProof)
        public
        view
        returns (bool)
    {
        bytes memory encodedUserAddress = abi.encodePacked(msg.sender);
        bytes32 leaf = keccak256(encodedUserAddress);
        bool isProofValid = MerkleProof.verify(merkleProof, rootHash, leaf);

        return isProofValid;
    }

    function devMint(address buyerAddress, uint256 quantity)
        external
        onlyOwner
        nonReentrant
        isTxValid
        isMaxSupplyReached(quantity)
    {
        _mint(buyerAddress, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] memory merkleProof)
        public
        payable
        virtual
        nonReentrant
        isTxValid
        isMaxSupplyReached(quantity)
        isMaxTxReached(quantity)
        isFundsSufficient(quantity)
    {
        require(PHASE == Phase.whitelistMint,"Not in whitelist mint phase");
        require(isWhitelisted(merkleProof), "Invalid Proof");

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        public
        payable
        virtual
        nonReentrant
        isTxValid
        isMaxSupplyReached(quantity)
        isMaxTxReached(quantity)
        isFundsSufficient(quantity)
    {
        require(
            PHASE == Phase.publicMint,
            "Not in whitelist mint phase"
        );

        _mint(msg.sender, quantity);
    }

    function getTotalMinted(address addr)
        public
        view
        returns (uint256)
    {
        return _numberMinted(addr);
    }

    function reduceTotalSupply(uint256 quantity)
        external
        onlyOwner
        nonReentrant
        isTxValid
        isMaxSupplyReached(quantity)
    {
        TOTAL_SUPPLY = TOTAL_SUPPLY - quantity;
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setReviewURI(string memory newURI) external virtual onlyOwner {
        reviewURI = newURI;
    }

    function setIsRevealed(bool isRevealed) external virtual onlyOwner {
        IS_REVEALED = isRevealed;
    }

    function setPhase(Phase phase) external onlyOwner {
        PHASE = phase;
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

    function partialWithdraw(uint256 balance)external onlyOwner nonReentrant isTxValid {
        (bool success, ) = msg.sender.call{value: balance}("");

        require(success, "Transfer failed.");
    }

    function withdraw() external onlyOwner nonReentrant isTxValid {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }

    function getSalePrice(address sender, uint256 quantity)
        private
        view
        returns (uint256)
    {
        bool isAlreadyMinted = _numberMinted(sender) > 0;

        return
            isAlreadyMinted
                ? PRICE * (quantity)
                : PRICE * (quantity - MAX_FREE_PER_WALLET);
    }
}