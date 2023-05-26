// SPDX-License-Identifier: MIT
/// @title: Waifu Warriors
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MythDivisionExclusiveAccess.sol";

contract WaifuWarriors is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    PaymentSplitter,
    MythDivisionExclusiveAccess
{
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint256 public MAX_SUPPLY = 11111;
    uint256 _reservedCount = 111;
    uint16 _apeFreeClaimCount;
    uint16 _remainingMythDivisionFreeClaims = 500;
    uint16 _remainingPresaleMints = 2000;
    uint8 _maxPurchaseCount = 15;
    uint256 _mintPrice = 0.07 ether;
    string _baseURIValue;
    bool _saleHasStarted = false;
    bool _presaleHasStarted = false;
    bool _freeClaimsPaused = false;
    ERC721 private boredApesContract;

    bool _apeFreeClaimProcessed = false;
    address[] _apeFreeClaimAddresses;

    mapping(address => uint16) _freeClaimCount;

    constructor(
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address openseaStorefrontAddress,
        address boredApesAddress,
        uint256[] memory openseaMythDivisionTokens,
        address[] memory apeFreeClaimWallets
    )
        ERC721("Waifu Warriors", "WW")
        PaymentSplitter(payees, paymentShares)
        MythDivisionExclusiveAccess(openseaStorefrontAddress)
    {
        _baseURIValue = baseURIValue_;
        boredApesContract = ERC721(boredApesAddress);

        for (uint256 i = 0; i < openseaMythDivisionTokens.length; i++) {
            addMythDivisionOpenSeaToken(openseaMythDivisionTokens[i]);
        }

        addEligibleERC721Contract(boredApesAddress);

        _apeFreeClaimCount = uint16(apeFreeClaimWallets.length);
        _apeFreeClaimAddresses = apeFreeClaimWallets;

        _freeClaimsPaused = true;
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

    function pauseFreeClaims() public onlyOwner {
        _freeClaimsPaused = true;
    }

    function unpauseFreeClaims() public onlyOwner {
        _freeClaimsPaused = false;
    }

    function togglePresale() public onlyOwner {
        _presaleHasStarted = !_presaleHasStarted;
    }

    function toggleSale() public onlyOwner {
        _saleHasStarted = !_saleHasStarted;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleHasStarted;
    }

    function presaleHasStarted() public view returns (bool) {
        return _presaleHasStarted;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedCount;
    }

    function remainingMythDivisionFreeClaims() public view returns (uint16) {
        return _remainingMythDivisionFreeClaims;
    }

    function remainingPresaleMints() public view returns (uint16) {
        return _remainingPresaleMints;
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

    function setMaxPurchaseCount(uint8 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

    function canAccessPresale() public view returns (bool) {
        return hasMythDivisionExclusiveAccess(msg.sender);
    }

    function eligibleFreeClaimCount() public view returns (uint256) {
        uint256 totalClaimable = uniqueMythDivisionTokens(msg.sender);

        if (totalClaimable >= _freeClaimCount[msg.sender]) {
            return totalClaimable.sub(_freeClaimCount[msg.sender]);
        } else {
            return 0;
        }
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(_reservedCount).add(_apeFreeClaimCount).add(
                numberOfTokens
            ) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 15 tokens at a time"
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

    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function claimMythDivisionFreeMints(uint16 numberOfTokens)
        public
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
    {
        require(!_freeClaimsPaused, "Free claims are paused");
        require(
            _remainingMythDivisionFreeClaims > 0,
            "Free claim period has ended"
        );

        uint256 allowedClaimCount = eligibleFreeClaimCount();
        require(allowedClaimCount > 0, "Cannot free claim additional tokens");

        if (numberOfTokens >= _remainingMythDivisionFreeClaims) {
            numberOfTokens = _remainingMythDivisionFreeClaims;

            _presaleHasStarted = true;
            emit PresaleStart();
        }

        _freeClaimCount[msg.sender] += numberOfTokens;
        _remainingMythDivisionFreeClaims -= numberOfTokens;

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintPresale(uint16 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(presaleHasStarted(), "Presale has not started yet");
        require(canAccessPresale(), "Account does not own MythDivision tokens");

        _mintTokens(numberOfTokens, msg.sender);

        if (_remainingPresaleMints > numberOfTokens) {
            _remainingPresaleMints -= numberOfTokens;
        } else {
            _remainingPresaleMints = 0;

            if (!_saleHasStarted) {
                _saleHasStarted = true;
                emit SaleStart();
            }
        }
    }

    function mintTokens(uint256 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(saleHasStarted(), "Sale has not started yet");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintReserved(uint256 numberOfTokens, address to) public onlyOwner {
        require(
            numberOfTokens <= _reservedCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(totalSupply()) <= MAX_SUPPLY,
            "Would exceed reserved supply"
        );

        _reservedCount = _reservedCount.sub(numberOfTokens);

        _mintTokens(numberOfTokens, to);
    }

    function claimForReservedApes() public whenNotPaused onlyOwner {
        require(!_apeFreeClaimProcessed, "Free apes already distributed");
        _apeFreeClaimProcessed = true;
        _apeFreeClaimCount = 0;

        for (uint256 i = 0; i < _apeFreeClaimAddresses.length; i++) {
            _mintTokens(1, _apeFreeClaimAddresses[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Emitted when the presale is started after the final MD Waifu has been claimed.
     */
    event PresaleStart();
    /**
     * @dev Emitted when the sale is started after the final presale mint has happened.
     */
    event SaleStart();
}