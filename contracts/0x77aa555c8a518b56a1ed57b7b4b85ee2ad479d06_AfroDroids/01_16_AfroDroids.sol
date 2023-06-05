// SPDX-License-Identifier: MIT
/// @title: Afro Droids
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AfroDroids is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    PaymentSplitter
{
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 public MAX_SUPPLY = 12117;
    uint256 public presaleAccessCount = 0;
    uint16 _reservedCount = 111;
    address _reservedTokensAddress;
    uint16 _maxPurchaseCount = 20;
    uint256 _mintPrice = 0.07 ether;
    uint256 _saleStart;
    uint256 _presaleStart;
    string _baseURIValue;
    mapping(address => bool) _presaleAccess;
    mapping(address => bool) _canAddToPresale;

    constructor(
        uint256 saleStart_,
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address reservedTokensAddress
    ) ERC721("Afro Droids", "AD") PaymentSplitter(payees, paymentShares) {
        _baseURIValue = baseURIValue_;
        _saleStart = saleStart_;
        _presaleStart = _saleStart - (60 * 60 * 6);
        _reservedTokensAddress = reservedTokensAddress;
        _canAddToPresale[reservedTokensAddress] = true;
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

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function setPresaleStart(uint256 start) public onlyOwner {
        _presaleStart = start;
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

    function reservedCount() public view returns (uint256) {
        return _reservedCount;
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

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

    function canAccessPresale() public view returns (bool) {
        return _presaleAccess[msg.sender];
    }

    function canAccessPresale(address addr) public view returns (bool) {
        return _presaleAccess[addr];
    }

    function addPresaleAddresses(address[] calldata addresses) external {
        require(
            owner() == msg.sender || _canAddToPresale[msg.sender],
            "Not authorized for that action"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleAccess[addresses[i]] = true;
        }
        presaleAccessCount += addresses.length;
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(_reservedCount).add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
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

    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
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
        require(canAccessPresale(), "You do not have access to the presale");

        _mintTokens(numberOfTokens, msg.sender);
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

    function mintReserved(uint16 numberOfTokens) public {
        require(
            numberOfTokens <= _reservedCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(totalSupply()) <= MAX_SUPPLY,
            "Would exceed reserved supply"
        );

        _reservedCount = _reservedCount - numberOfTokens;

        _mintTokens(numberOfTokens, _reservedTokensAddress);
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
}