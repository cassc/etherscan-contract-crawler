// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NiceDrips is ERC721, Pausable, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    uint256 public MAX_SUPPLY = 11111;
    uint256 _totalSupply = 0;
    uint256 _reservedCount = 13;
    uint256 _baseMintPrice = 0.03 ether;
    uint256 _maxPurchaseCount = 8;
    string _baseURIValue;
    uint256 _saleStart;

    constructor(
        uint256 saleStart_,
        string memory baseURIVal_,
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("Nice Drips", "DRIPS") PaymentSplitter(payees, paymentShares) {
        _baseURIValue = baseURIVal_;
        _saleStart = saleStart_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function setSaleStart(uint256 saleStart_) public onlyOwner {
        _saleStart = saleStart_;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedCount;
    }

    modifier ensureSaleHasStarted() {
        require(saleHasStarted(), "Sale has not started yet");
        _;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }

    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint256 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function baseMintPrice() public view returns (uint256) {
        return _baseMintPrice;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens > 0, "Cannot mint zero");
        return _baseMintPrice.mul(numberOfTokens);
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            _totalSupply.add(_reservedCount).add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 8 tokens at a time"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    function _mintTokens(address to, uint256 numberOfTokens) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _totalSupply += 1;
            _safeMint(to, _totalSupply);
        }
    }

    function mintTokens(uint256 numberOfTokens)
        public
        payable
        whenNotPaused
        ensureSaleHasStarted
        mintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        _mintTokens(msg.sender, numberOfTokens);
    }

    function mintReserved(address to, uint256 numberOfTokens) public onlyOwner {
        require(
            numberOfTokens <= _reservedCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(_totalSupply) <= MAX_SUPPLY,
            "Would exceed max supply"
        );

        _reservedCount = _reservedCount.sub(numberOfTokens);

        _mintTokens(to, numberOfTokens);
    }
}