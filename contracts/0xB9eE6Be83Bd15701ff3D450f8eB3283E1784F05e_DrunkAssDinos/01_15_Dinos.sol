// SPDX-License-Identifier: MIT
/// @title: Drunk Ass Dinos
/// @author: DropHero LLC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DrunkAssDinos is ERC721, ERC721Burnable, Pausable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint16 public MAX_SUPPLY = 10000;
    uint256 _mintPrice = 0.0420 ether;
    uint8 _maxPerTx = 20;
    uint8 _reservedTokenCount = 250;
    uint16 _totalMinted = 0;
    uint256 _saleStart;
    uint256 _presaleStart;
    string _baseURIValue;
    mapping(address => uint8) _remainingFreeClaims;
    mapping(address => uint8) _remainingPresaleMints;

    constructor(
        uint256 saleStart_,
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("Drunk Ass Dinos", "DAD") PaymentSplitter(payees, paymentShares) {
        _baseURIValue = baseURIValue_;
        _saleStart = saleStart_;
        _presaleStart = _saleStart - 60 * 60 * 72;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSaleStart(uint256 saleStart_) public onlyOwner {
        _saleStart = saleStart_;
    }

    function setPresaleStart(uint256 presaleStart_) public onlyOwner {
        _presaleStart = presaleStart_;
    }

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint256) {
        return _presaleStart;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return _presaleStart <= block.timestamp;
    }

    function remainingPresaleMints(address addr)
        public
        view
        returns (uint8)
    {
        return _remainingPresaleMints[addr];
    }

    function remainingFreeClaims(address addr)
        public
        view
        returns (uint8)
    {
        return _remainingFreeClaims[addr];
    }

    function maxPerTransaction() public view returns (uint256) {
        return _maxPerTx;
    }

    function setMaxPerTransaction(uint8 count) external onlyOwner {
        _maxPerTx = count;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedTokenCount;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice * numberOfTokens;
    }

    function totalMinted() public view returns(uint16) {
        return _totalMinted;
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            _totalMinted + _reservedTokenCount + numberOfTokens <=
                MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPerTransaction(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPerTx,
            "Cannot mint more than 20 tokens at a time"
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

    modifier cannotMintFromContract() {
        require(
            _msgSender() == tx.origin,
            "Contracts cannot call mint functions"
        );
        _;
    }

    modifier presaleMustBeActive() {
        require(presaleHasStarted(), "Presale has not started yet");
        _;
    }

    function addFreeClaim(
        address[] calldata addresses,
        uint8[] calldata claimCount
    ) external onlyOwner {
        require(
            addresses.length == claimCount.length,
            "Address list and claim count list must be the same length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _remainingFreeClaims[addresses[i]] = claimCount[i];
            _remainingPresaleMints[addresses[i]] = 5;
        }
    }

    function addToPresaleAllowlist(
        address[] calldata addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _remainingPresaleMints[addresses[i]] = 5;
        }
    }

    function mintTokens(uint8 numberOfTokens)
        external
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPerTransaction(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
        cannotMintFromContract
    {
        require(saleHasStarted(), "Sale has not started yet");

        _mintTokens(numberOfTokens, _msgSender());
    }

    function mintPresale(uint8 numberOfTokens)
        external
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPerTransaction(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
        cannotMintFromContract
        presaleMustBeActive
    {
        require(
            numberOfTokens <= _remainingPresaleMints[_msgSender()],
            "Would exceed remaining presale mints for wallet"
        );

        _remainingPresaleMints[_msgSender()] -= numberOfTokens;
        _mintTokens(numberOfTokens, _msgSender());
    }

    function claimFreeMints(uint8 numberOfTokens)
        external
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPerTransaction(numberOfTokens)
        cannotMintFromContract
        presaleMustBeActive
    {
        require(
            remainingFreeClaims(_msgSender()) >= numberOfTokens,
            "Requested free token count exceeds available free claims"
        );
        _remainingFreeClaims[_msgSender()] -= numberOfTokens;

        _mintTokens(numberOfTokens, _msgSender());
    }

    function mintReserved(uint8 numberOfTokens, address to) external onlyOwner {
        require(
            numberOfTokens <= _reservedTokenCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens + _totalMinted <= MAX_SUPPLY,
            "Would exceed reserved supply"
        );

        _reservedTokenCount = _reservedTokenCount - numberOfTokens;

        _mintTokens(numberOfTokens, to);
    }

    function _mintTokens(uint8 numberOfTokens, address to) internal {
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            _safeMint(to, _totalMinted + i);
        }
        _totalMinted += numberOfTokens;
    }
}