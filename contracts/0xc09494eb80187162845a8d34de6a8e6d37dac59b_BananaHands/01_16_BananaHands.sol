// SPDX-License-Identifier: MIT
/// @title: Banana Hands
/// @author: DropHero LLC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract BonesAndBananas {
    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

abstract contract EightEightEight {
    function balanceOf(address owner, uint256 tokenId)
        external
        view
        virtual
        returns (uint256 balance);
}

contract BananaHands is ERC721Enumerable, Pausable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 public MAX_SUPPLY = 10888;
    uint256 _mintPrice = 0.042069 ether;
    uint16 _maxPurchaseCount = 6;
    uint16 _reservedTokenCount = 270;
    address _reservedTokenAddress;
    uint256 _saleStart;
    uint256 _presaleStart;
    string _baseURIValue;
    mapping(address => bool) _presalePurchased;
    mapping(address => uint16) _presaleClaimsRemaining;

    BonesAndBananas _bonesAndBananas;
    EightEightEight _genesis888;
    uint16 GENESIS_888_TOKEN_ID = 888;

    constructor(
        uint256 saleStart_,
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address reservedTokenAddress,
        address bonesAndBananasAddress,
        address genesis888Address
    ) ERC721("Banana Hands", "BH") PaymentSplitter(payees, paymentShares) {
        _baseURIValue = baseURIValue_;
        _saleStart = saleStart_;
        _presaleStart = _saleStart - 60 * 60 * 24;
        _reservedTokenAddress = reservedTokenAddress;
        _bonesAndBananas = BonesAndBananas(bonesAndBananasAddress);
        _genesis888 = EightEightEight(genesis888Address);

        for (uint256 i = 0; i < payees.length; i++) {
            _mintTokens(1, payees[i]);
        }
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

    function canAccessPresale() public view returns (bool) {
        return
            _bonesAndBananas.balanceOf(msg.sender) > 0 ||
            _genesis888.balanceOf(msg.sender, GENESIS_888_TOKEN_ID) > 0;
    }

    function hasPurchasedPresale() public view returns (bool) {
        return _presalePurchased[msg.sender];
    }

    function remaining888PresaleClaims() public view returns (uint16) {
        return _presaleClaimsRemaining[msg.sender];
    }

    function remaining888PresaleClaims(address addr)
        public
        view
        returns (uint16)
    {
        return _presaleClaimsRemaining[addr];
    }

    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint8 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedTokenCount;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(_reservedTokenCount).add(numberOfTokens) <=
                MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 6 tokens at a time"
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
            msg.sender == tx.origin,
            "Contracts cannot call mint functions"
        );
        _;
    }

    modifier presaleMustBeActive() {
        require(presaleHasStarted(), "Presale has not started yet");
        require(!saleHasStarted(), "Presale has ended");
        _;
    }

    function add888FreeClaim(
        address[] calldata addresses,
        uint8[] calldata claimCount
    ) external onlyOwner {
        require(
            addresses.length == claimCount.length,
            "Address list and claim count list must be the same length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleClaimsRemaining[addresses[i]] = claimCount[i];
        }
    }

    function mintTokens(uint16 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
        cannotMintFromContract
    {
        require(saleHasStarted(), "Sale has not started yet");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintPresale()
        public
        payable
        mintCountMeetsSupply(1)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(1)
        validatePurchasePrice(1)
        cannotMintFromContract
        presaleMustBeActive
    {
        require(
            canAccessPresale(),
            "Must own a Banana or be in the 888 Inner Circle to participate in presale"
        );
        require(
            !hasPurchasedPresale(),
            "You may only purchase 1 hand during the presale"
        );
        _presalePurchased[msg.sender] = true;

        _mintTokens(1, msg.sender);
    }

    function claimFreePresale(uint16 numberOfTokens)
        public
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        cannotMintFromContract
        presaleMustBeActive
    {
        require(
            remaining888PresaleClaims() >= numberOfTokens,
            "Requested free token count exceeds available free claims"
        );
        _presaleClaimsRemaining[msg.sender] -= numberOfTokens;

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintReserved(uint16 numberOfTokens) public {
        require(
            numberOfTokens <= _reservedTokenCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(totalSupply()) <= MAX_SUPPLY,
            "Would exceed reserved supply"
        );

        _reservedTokenCount = _reservedTokenCount - numberOfTokens;

        _mintTokens(numberOfTokens, _reservedTokenAddress);
    }

    function _mintTokens(uint16 numberOfTokens, address to) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }
}