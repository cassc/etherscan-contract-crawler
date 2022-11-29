// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

import "./ERC721AQueryable.sol";

contract Token is Ownable, ERC721AQueryable, ReentrancyGuard, PaymentSplitter, OperatorFilterer {
    struct SaleConfig {
        uint256 publicSaleStartTime;
        uint256 claimSaleStartTime;
    }

    bool public operatorFilteringEnabled;
    SaleConfig public _saleConfig;
    uint256 public constant AUCTION_PRICE = 0.085 ether;
    uint256 public immutable _totalAmount;
    uint256 public immutable _maximumPerUser;
    string private _baseTokenURI;
    bool private _revealed = false;
    string private _notRevealedBaseURI = '';

    // mapping for eligible amount tokens per address
    mapping (address => uint) eligibleAddressesAmount;
    uint256 public eligibleAddressesTotalAmountCount = 0;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalAmount,
        string memory baseTokenURI,
        uint256 maxPerUser,
        uint256 publicSaleStartTime,
        uint256 claimSaleStartTime,
        address[] memory _payees,
        uint256[] memory _shares,
        string memory notRevealedURI
    )
    ERC721A(name, symbol)
    PaymentSplitter(_payees, _shares) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        
        _totalAmount = totalAmount;
        _baseTokenURI = baseTokenURI;
        _maximumPerUser = maxPerUser;
        _saleConfig.publicSaleStartTime = publicSaleStartTime;
        _saleConfig.claimSaleStartTime = claimSaleStartTime;
        _notRevealedBaseURI = notRevealedURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity, uint256 totalCost) private {
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    /**
     * Set claim mint addresses
     */
     function setEligebleAddresses(uint256 quantityPerAddress, address[] memory recipients) external onlyOwner {
        require(
            quantityPerAddress > 0,
            "Quantity needs be more than 0"
        );

        require(
            recipients.length > 0,
            "No recipients"
        );

        for(uint i = 0; i < recipients.length; i++) {
            if(recipients[i] != address(0)) {
                eligibleAddressesAmount[recipients[i]] = quantityPerAddress;
            }
        }

        // add to counter
        eligibleAddressesTotalAmountCount = eligibleAddressesTotalAmountCount + (quantityPerAddress * recipients.length);
     }

    /**
     * Claim Mint
     */
     function claimMint() external callerIsUser {
        uint quantity = eligibleAddressesAmount[msg.sender];
        uint256 _saleStartTime = uint256(_saleConfig.claimSaleStartTime);

        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "Claim sale has not started yet"
        );

        require(
            quantity > 0,
            "Nothing to claim"
        );

        require(
            totalSupply() + quantity <= _totalAmount,
            "Exceeds maximum supply"
        );

        // clear eligible amount
        eligibleAddressesAmount[msg.sender] = 0;

        // remove from counter
        eligibleAddressesTotalAmountCount = eligibleAddressesTotalAmountCount - quantity;

        // mint eligible to address
        _safeMint(msg.sender, quantity);
     }

    /**
     * Public Mint
     */
    function publicMint(uint256 quantity) external payable callerIsUser {
        uint256 _saleStartTime = uint256(_saleConfig.publicSaleStartTime);
        uint256 totalCost = AUCTION_PRICE * quantity;

        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "Public sale has not started yet"
        );

        require(
            msg.value >= totalCost,
            "Not enough ETH sent: check price"
        );

        require(
            totalSupply() + quantity <= _totalAmount,
            "Exceeds maximum supply"
        );

        require(
            _numberMinted(msg.sender) + quantity <= _maximumPerUser,
            "Can not mint this many"
        );

        mint(quantity, totalCost);
    }

    /**
     * Owners Mint
     */
    function ownerMint(uint256 quantity) external payable onlyOwner {
        require(
            totalSupply() + quantity <= _totalAmount,
            "Not enough remaining"
        );

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Refunds the sender if the amount sent is greater than required.
     * @param _price The price minter sends to the contract.
     */
    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Need to send more ETH.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    /**
     * Set public mint start time
     */
    function setPublicSaleStartTime(uint256 timestamp) external onlyOwner {
        _saleConfig.publicSaleStartTime = timestamp;
    }

    /**
     * Set claim 'mint' start time
     */
    function setClaimSaleStartTime(uint256 timestamp) external onlyOwner {
        _saleConfig.claimSaleStartTime = timestamp;
    }

    /**
     * @dev Sets revealed to true.
     * This action cannot be reverted. Once the contract is revealed, it cannot be unrevealed.
     */
    function reveal(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
        _revealed = true;
    }

    /**
     * Override baseURI getter
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Override notRevealedURI getter
     */
    function _notRevealedURI() internal view virtual override returns (string memory) {
        return _notRevealedBaseURI;
    }

    /**
     * Override _isRevealed getter
     */
    function _isRevealed() internal view virtual override returns (bool) {
        return _revealed;
    }

    /**
     * Get unclaimed count by owner
     */
    function getOwnerUnclaimedCount(address owner) public view virtual returns (uint) {
        uint quantity = eligibleAddressesAmount[owner];

        return quantity;
    }

    /**
     * Burn token
     */
    function burnToken(uint256 tokenId) external {
        address ownerOfToken = ownerOf(tokenId);

        require(
            ownerOfToken == msg.sender,
            "Not owner of token"
        );

        _burn(tokenId);
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }
}