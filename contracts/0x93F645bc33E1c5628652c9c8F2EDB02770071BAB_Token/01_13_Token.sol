// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./ERC721AQueryable.sol";

contract Token is Ownable, ERC721AQueryable, ReentrancyGuard, PaymentSplitter {
    struct SaleConfig {
        uint256 publicSaleStartTime;
    }

    SaleConfig public _saleConfig;
    uint256 public constant AUCTION_PRICE = 0.01 ether;
    uint256 public immutable _totalAmount;
    uint256 public immutable _maximumPerUser;
    string private _baseTokenURI;
    bool private _revealed = true;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalAmount,
        string memory baseTokenURI,
        uint256 maxPerUser,
        uint256 publicSaleStartTime,
        address[] memory _payees,
        uint256[] memory _shares
    )
    ERC721A(name, symbol)
    PaymentSplitter(_payees, _shares) {
        _totalAmount = totalAmount;
        _baseTokenURI = baseTokenURI;
        _maximumPerUser = maxPerUser;
        _saleConfig.publicSaleStartTime = publicSaleStartTime;
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
            balanceOf(msg.sender) + quantity <= _maximumPerUser,
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
     * Override baseURI getter
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Override _isRevealed getter
     */
    function _isRevealed() internal view virtual override returns (bool) {
        return _revealed;
    }
}