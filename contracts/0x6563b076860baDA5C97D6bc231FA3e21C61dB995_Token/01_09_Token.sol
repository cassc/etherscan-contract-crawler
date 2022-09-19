// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./StartTokenIdHelper.sol";


contract Token is StartTokenIdHelper, ERC721ABurnable, Ownable, ReentrancyGuard {

    string private _baseTokenURI;
    uint256 public limitSupply;
    uint256 public limitFreeSupply;
    mapping(address => uint16) public freeReceivePerAddress;

    bool public saleActive;
    uint256 public saleFreeSupply;
    uint256 public price;
    uint16 public freeLimitPerAddress;
    uint16 public transactionLimit;

    event SaleStart(uint256 indexed _saleStartTime, uint256 _price, uint16 _freeLimitPerAddress, uint16 _transactionLimit);
    event SalePaused(uint256 indexed _salePauseTime, uint256 _saleFreeSupply);
    event LimitSupplyDefined(uint256 indexed _limitStartTime, uint256 _limitSupply);
    event LimitFreeSupplyDefined(uint256 indexed _limitFreeStartTime, uint256 _limitFreeSupply);

    modifier whenSaleActive() {
        require(saleActive, "IBY: Sale is not active.");
        _;
    }

    constructor(
        string memory name_, string memory symbol_,string memory baseURI_, uint256 startTokenId_
    ) StartTokenIdHelper(startTokenId_) ERC721A(name_, symbol_) {
        _baseTokenURI = baseURI_;
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setLimitSupply(uint256 limit_) external onlyOwner  {
        require(limitSupply == 0, "IBY: Limit supply has already defined.");
        limitSupply = limit_;
        emit LimitSupplyDefined(block.timestamp, limitSupply);
    }

    function setLimitFreeSupply(uint256 limit_) external onlyOwner  {
        require(limitFreeSupply == 0, "IBY: Limit free supply has already defined.");
        limitFreeSupply = limit_;
        emit LimitFreeSupplyDefined(block.timestamp, limitFreeSupply);
    }

    function startSale(uint256 price_, uint16 freeLimitPerAddress_, uint16 transactionLimit_) external onlyOwner {
        require(limitSupply > 0, "IBY: Limit supply should be defined.");
        if (saleActive) { _pauseSale(); }

        transactionLimit = transactionLimit_;
        freeLimitPerAddress = freeLimitPerAddress_;
        price = price_;
        saleFreeSupply = 0;
        saleActive = true;
        emit SaleStart(block.timestamp, price, freeLimitPerAddress, transactionLimit);
    }

    function pauseSale() external onlyOwner whenSaleActive {
        _pauseSale();
    }

    function _pauseSale() internal {
        saleActive = false;
        emit SalePaused(block.timestamp, saleFreeSupply);
    }

    function mint(uint16 tokensAmount) external payable whenSaleActive nonReentrant {
        require(tokensAmount <= transactionLimit, "IBY: Limited amount of tokens per transaction.");
        require(totalSupply() + tokensAmount <= limitSupply, "IBY: Limited amount of tokens.");

        if (saleFreeSupply < limitFreeSupply && freeReceivePerAddress[msg.sender] < freeLimitPerAddress) {
            uint16 freeTokensAmount = freeLimitPerAddress - freeReceivePerAddress[msg.sender];
            if (limitFreeSupply - saleFreeSupply < freeTokensAmount) {
                freeTokensAmount = uint16(limitFreeSupply - saleFreeSupply);
            }
            if (tokensAmount < freeTokensAmount) {
                freeTokensAmount = tokensAmount;
            }

            require(price * (tokensAmount - freeTokensAmount) <= msg.value, "IBY: Insufficient funds.");

            freeReceivePerAddress[msg.sender] += freeTokensAmount;
            saleFreeSupply += freeTokensAmount;
        } else {
            require(price * tokensAmount <= msg.value, "IBY: Insufficient funds.");
        }
        _safeMint(msg.sender, tokensAmount);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }
}