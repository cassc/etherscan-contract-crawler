//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";
import "./ReentrancyGuard.sol";

contract POP is
    ERC721A("!POP", "!POP"),
    ERC721AQueryable,
    Ownable,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    enum ContractStatus {
        disable,
        publicmint
    }

    // ------------------------------------------------------------------------
    // * Storage
    // ------------------------------------------------------------------------

    uint256 public PRICE = 0.003 ether;
    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public MAX_TX_PER_WALLET = 5;

    ContractStatus public CONTRACT_STATUS = ContractStatus.disable;

    uint256 public publicMintCounter;
    string internal baseURI = "";

    // ------------------------------------------------------------------------
    // * Modifiers
    // ------------------------------------------------------------------------

    modifier isEthAvailable(uint256 quantity) {
        require(
            msg.value >= getSalePrice(msg.sender, quantity),
            "Insufficient funds"
        );
        _;
    }

    modifier isMaxTxReached(uint256 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET,
            "Exceeded transaction limit"
        );
        _;
    }

    modifier isSupplyUnavailable(uint256 quantity) {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Out of stock");
        _;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    function getSalePrice(
        address sender,
        uint256 quantity
    ) private view returns (uint256 COST) {
        int256 INT_FREE_QUOTA = int256(MAX_FREE_PER_WALLET) -
            int256(_numberMinted(sender));
        int256 INT_COST;

        if (INT_FREE_QUOTA > 0) {
            if (int256(quantity) < INT_FREE_QUOTA) {
                INT_COST = 0;
            } else {
                INT_COST = int256(PRICE) * (int256(quantity) - INT_FREE_QUOTA);
            }
        } else {
            INT_COST = int256(PRICE) * (int256(quantity));
        }

        COST = uint256(INT_COST);
    }

    // ------------------------------------------------------------------------
    // * Frontend view helpers
    // ------------------------------------------------------------------------

    function getTotalSupplyLeft() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function getTotalMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function getPublicMintCounter() public view returns (uint) {
        return publicMintCounter;
    }

    // ------------------------------------------------------------------------
    // * Mint
    // ------------------------------------------------------------------------

    function mint(
        uint256 quantity
    )
        public
        payable
        virtual
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
        isMaxTxReached(quantity)
        isEthAvailable(quantity)
    {
        require(
            CONTRACT_STATUS == ContractStatus.publicmint,
            "Contract is not open for Public Mint"
        );

        _mint(msg.sender, quantity);
        publicMintCounter += quantity;
    }

    // ------------------------------------------------------------------------
    // * Admin Functions
    // ------------------------------------------------------------------------

    function internalMint(
        uint256 quantity
    )
        public
        virtual
        onlyOwner
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
    {
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setStatus(ContractStatus status) external onlyOwner {
        CONTRACT_STATUS = status;
    }

    function setPrice(uint newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setSupply(uint newSupply) external onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function setMaxPerWallet(uint newMaxPerWallet) external onlyOwner {
        MAX_TX_PER_WALLET = newMaxPerWallet;
    }

    function withdrawAll() external onlyOwner nonReentrant isUser {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // ------------------------------------------------------------------------
    // * Operator Filterer Overrides
    // ------------------------------------------------------------------------

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ------------------------------------------------------------------------
    // * Internal Overrides
    // ------------------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
