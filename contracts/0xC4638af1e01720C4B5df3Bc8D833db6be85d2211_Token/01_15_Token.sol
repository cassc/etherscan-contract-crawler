// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract Token is ERC721Enumerable, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _allowList;

    event AddedToAllowList(address indexed _address);
    event RemovedFromAllowList(address indexed _address);

    mapping(address => uint) public presalePurchasedAmount;

    uint8 public presaleLimit;
    uint256 public presalePrice;
    bool public presaleActive;
    uint256 public presaleDuration;
    uint256 public presaleStartTime;

    event PresaleStart(
        uint256 indexed _presaleDuration, uint256 indexed _presaleStartTime,
        uint256 indexed _presalePrice, uint8 _presaleLimit
    );
    event PresalePaused(uint256 indexed _timeElapsed, uint256 indexed _totalSupply);


    uint8 public saleTransactionLimit;
    uint256 public salePrice;
    bool public saleActive;

    event SaleStart(uint256 indexed _saleStartTime, uint256 indexed _salePrice, uint8 _saleLimit);
    event SalePaused(uint256 indexed _salePauseTime, uint256 indexed _totalSupply);


    string private _baseTokenURI;
    uint256 private _limitSupply;
    uint256 private _ownerLimit;

    uint16 public addToAllowListLimit;
    uint16 public removeFromAllowListLimit;

    modifier whenPresaleActive() {
        require(presaleActive, "DA: Presale is not active");
        _;
    }

    modifier whenPresalePaused() {
        require(!presaleActive, "DA: Presale is not paused");
        _;
    }

    modifier whenSaleActive() {
        require(saleActive, "DA: Sale is not active");
        _;
    }

    modifier whenSalePaused() {
        require(!saleActive, "DA: Sale is not paused");
        _;
    }

    modifier whenAnySaleActive() {
        require(presaleActive || saleActive, "DA: Any sale is terminated");
        _;
    }

    constructor(
        string memory name_, string memory symbol_, string memory baseURI_, uint256 limitSupply_, uint256 ownerLimit_,
        uint16 addToAllowListLimit_, uint16 removeFromAllowListLimit_
    ) ERC721(name_, symbol_)  {
        _baseTokenURI = baseURI_;
        _limitSupply = limitSupply_;
        _ownerLimit = ownerLimit_;
        addToAllowListLimit = addToAllowListLimit_;
        removeFromAllowListLimit = removeFromAllowListLimit_;
    }

    function limitSupply() public view virtual returns (uint256) {
        return _limitSupply;
    }

    function ownerLimit() public view virtual returns (uint256) {
        return _ownerLimit;
    }

    function publicLimit() public view virtual returns (uint256) {
        return limitSupply() - ownerLimit();
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setAddToAllowListLimit(uint16 addToAllowListLimit_) external onlyOwner {
        addToAllowListLimit = addToAllowListLimit_;
    }

    function setRemoveFromAllowListLimit(uint16 removeFromAllowListLimit_) external onlyOwner {
        removeFromAllowListLimit = removeFromAllowListLimit_;
    }

    function addToAllowList(address[] memory addresses) external onlyOwner whenPresalePaused whenSalePaused {
        require(addresses.length <= addToAllowListLimit, "DA: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index+=1) {
            if (_allowList.add(addresses[index])) {
                emit AddedToAllowList(addresses[index]);
            }
        }
    }

    function removeFromAllowList(address[] memory addresses) external onlyOwner whenPresalePaused whenSalePaused {
        require(addresses.length <= removeFromAllowListLimit, "DA: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index+=1) {
            if (_allowList.remove(addresses[index])) {
                emit RemovedFromAllowList(addresses[index]);
            }
        }
    }

    function inAllowList(address value) public view returns (bool) {
        return _allowList.contains(value);
    }

    function allowListLength() external view returns (uint256) {
        return _allowList.length();
    }

    function allowAddressByIndex(uint256 index) external view returns (address) {
        require(index < _allowList.length(), "DA: Index out of bounds");
        return _allowList.at(index);
    }

    function startPresale(
        uint256 presaleDuration_, uint256 presalePrice_, uint8 presaleLimit_
    ) external onlyOwner whenPresalePaused whenSalePaused {
        presaleStartTime = block.timestamp;
        presaleDuration = presaleDuration_;
        presalePrice = presalePrice_;
        presaleLimit = presaleLimit_;

        presaleActive = true;
        emit PresaleStart(presaleDuration, presaleStartTime, presalePrice, presaleLimit);
    }

    function pausePresale() external onlyOwner whenPresaleActive {
        presaleActive = false;
        emit PresalePaused(_elapsedPresaleTime(), totalSupply());
    }

    function startPublicSale(uint256 salePrice_, uint8 saleTransactionLimit_) external onlyOwner whenPresalePaused whenSalePaused {
        salePrice = salePrice_;
        saleTransactionLimit = saleTransactionLimit_;

        saleActive = true;
        emit SaleStart(block.timestamp, salePrice, saleTransactionLimit);
    }

    function pausePublicSale() external onlyOwner whenSaleActive {
        saleActive = false;
        emit SalePaused(totalSupply(), block.timestamp);
    }

    function price() external view whenAnySaleActive returns (uint256) {
        return presaleActive ? presalePrice : salePrice;
    }

    function _elapsedPresaleTime() internal view returns (uint256) {
        return presaleStartTime > 0 ? block.timestamp - presaleStartTime : 0;
    }

    function _remainingPresaleTime() internal view returns (uint256) {
        if (presaleStartTime == 0 || _elapsedPresaleTime() >= presaleDuration) {
            return 0;
        }

        return (presaleStartTime + presaleDuration) - block.timestamp;
    }

    function remainingPresaleTime() external view whenPresaleActive returns (uint256) {
        require(presaleStartTime > 0, "DA: Presale hasn't started yet");
        return _remainingPresaleTime();
    }

    function _preValidatePurchase(uint256 tokensAmount) internal view {
        require(msg.sender != address(0));
        require(tokensAmount > 0, "DA: Must mint at least one token");
        require(totalSupply() + tokensAmount <= publicLimit(), "DA: Minting would exceed max supply");
        if (presaleActive) {
            require(_remainingPresaleTime() > 0, "DA: Presale is over");
            require(inAllowList(msg.sender), "DA: Address isn't in the allow list");
            require(tokensAmount + presalePurchasedAmount[msg.sender] <= presaleLimit, "DA: Presale, limited amount of tokens");
            require(presalePrice * tokensAmount <= msg.value, "DA: Presale, insufficient funds");
        } else {
            require(tokensAmount <= saleTransactionLimit, "DA: Limited amount of tokens");
            require(salePrice * tokensAmount <= msg.value, "DA: Insufficient funds");
        }
    }

    function _processPurchaseToken(address recipient) internal returns (uint256) {
        uint256 newItemId = totalSupply() + 1;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function mintTokens(uint256 tokensAmount) external payable whenAnySaleActive nonReentrant returns (uint256[] memory) {
        _preValidatePurchase(tokensAmount);

        uint256[] memory tokens = new uint256[](tokensAmount);
        for (uint index = 0; index < tokensAmount; index += 1) {
            tokens[index] = _processPurchaseToken(msg.sender);
        }

        if (presaleActive) {
            presalePurchasedAmount[msg.sender] += tokensAmount;
        }

        return tokens;
    }

    function mintToken(address recipient) external onlyOwner nonReentrant returns (uint256) {
        require(recipient != address(0));
        require(totalSupply() >= publicLimit(), "DA: Public minting is active");
        require(totalSupply() < limitSupply(), "DA: Minting would exceed max supply");
        return _processPurchaseToken(recipient);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }
}