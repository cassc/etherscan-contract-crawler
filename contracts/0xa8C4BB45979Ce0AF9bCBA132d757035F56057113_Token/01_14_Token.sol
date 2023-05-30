// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";


contract Token is ERC721ABurnable, Ownable, ReentrancyGuard {

    bool public saleActive;
    uint256 public saleDuration;
    uint256 public saleStartTime;
    uint256 public price;
    uint256 public animatedPrice;
    uint8 public transactionLimit;

    event SaleStart(
        uint256 indexed _saleStartTime, uint256 indexed _saleDuration,
        uint256 _price, uint256 _animatedPrice, uint8 _transactionLimit
    );
    event SalePaused(uint256 indexed _salePauseTime, uint256 indexed _timeElapsed, uint256 indexed _totalSupply);

    bool public addTypeToURI = true;
    string private _baseTokenURI;
    mapping(uint256 => bool) private _animatedTokens;

    modifier whenSaleActive() {
        require(saleActive, "FOMA: Sale is not active");
        _;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721A(name_, symbol_)  {
        _baseTokenURI = baseURI_;
    }

    function animatedTokens(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "FOMA: Animated query for nonexistent token");
        return _animatedTokens[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI_ = super.tokenURI(tokenId);
        if (addTypeToURI && _animatedTokens[tokenId]) {
            return string(abi.encodePacked(tokenURI_, "?animated=true"));
        }
        return tokenURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setAddTypeToURI(bool addTypeToURI_) external onlyOwner {
        addTypeToURI = addTypeToURI_;
    }

    function startSale(
        uint256 saleDuration_, uint256 price_, uint256 animatedPrice_, uint8 transactionLimit_
    ) external onlyOwner {
        if (saleActive) { _pauseSale(); }

        saleStartTime = block.timestamp;
        saleDuration = saleDuration_;
        transactionLimit = transactionLimit_;

        price = price_;
        animatedPrice = animatedPrice_;

        saleActive = true;
        emit SaleStart(saleStartTime, saleDuration, price, animatedPrice, transactionLimit);
    }

    function pauseSale() external onlyOwner whenSaleActive {
        _pauseSale();
    }

    function _pauseSale() internal {
        saleActive = false;
        emit SalePaused(block.timestamp, _elapsedSaleTime(), totalSupply());
    }

    function _elapsedSaleTime() internal view returns (uint256) {
        return saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }

    function _remainingSaleTime() internal view returns (uint256) {
        if (saleStartTime == 0 || _elapsedSaleTime() >= saleDuration) {
            return 0;
        }
        return (saleStartTime + saleDuration) - block.timestamp;
    }

    function remainingSaleTime() external view whenSaleActive returns (uint256) {
        require(saleStartTime > 0, "FOMA: Sale hasn't started yet");
        return _remainingSaleTime();
    }

    function _preValidatePurchase(uint256 tokensAmount) internal view {
        require(tokensAmount <= transactionLimit, "FOMA: Limited amount of tokens");
        require(_remainingSaleTime() > 0, "FOMA: Sale is over");
    }

    function mint(uint256 tokensAmount) external payable whenSaleActive nonReentrant {
        _preValidatePurchase(tokensAmount);

        require(price * tokensAmount <= msg.value, "FOMA: Insufficient funds.");

        _safeMint(msg.sender, tokensAmount);
    }

    function animatedMint(uint256 tokensAmount) external payable whenSaleActive nonReentrant {
        _preValidatePurchase(tokensAmount);

        require(animatedPrice * tokensAmount <= msg.value, "FOMA: Insufficient funds. (Animated)");

        for (uint8 i; i < tokensAmount; i +=1) {
            _animatedTokens[_currentIndex + i] = true;
        }
        _safeMint(msg.sender, tokensAmount);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }
}