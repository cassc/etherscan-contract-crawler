// SPDX-License-Identifier: MIT
/// @title: Fatales
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Fatales is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    PaymentSplitter
{
    event StartingIndexSet(uint256 startingIndex);

    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 public MAX_SUPPLY = 10000;
    uint16 _maxPurchaseCount = 20;
    uint256 _mintPrice = 0.03 ether;
    uint256 _saleStart;
    string _baseURIValue;

    uint256 public startingIndexBlock;
    uint256 public startingIndex = 0;

    mapping(address => uint256) _reservedTokens;
    uint256 _reservedCount = 0;

    constructor(
        uint256 saleStart_,
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares,
        uint256[] memory reservedTokens
    ) ERC721("Fatales", "FTL") PaymentSplitter(payees, paymentShares) {
        require(
            payees.length == reservedTokens.length,
            "PaymentSplitter: payees and reservedTokens length mismatch"
        );
        _baseURIValue = baseURIValue_;
        _saleStart = saleStart_;

        for (uint256 i = 0; i < reservedTokens.length; i++) {
            _reservedTokens[payees[i]] = reservedTokens[i];
            _reservedCount += reservedTokens[i];
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

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedCount;
    }

    function reservedCount(address to) public view returns (uint256) {
        return _reservedTokens[to];
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

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        uint256 targetBlock = startingIndexBlock;

        if (block.number.sub(startingIndexBlock) > 255) {
            targetBlock = block.number - 1;
        }

        startingIndex = uint256(blockhash(targetBlock)).mod(MAX_SUPPLY);

        if (startingIndex == 0) {
            startingIndex = 1;
        }

        emit StartingIndexSet(startingIndex);
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

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    function mintReserved(uint16 numberOfTokens, address to) public {
        require(_reservedTokens[to] > 0, "No tokens reserved for this address");
        require(
            numberOfTokens <= _reservedTokens[to],
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(totalSupply()) <= MAX_SUPPLY,
            "Would exceed total supply"
        );

        _reservedTokens[to] -= numberOfTokens;
        _reservedCount -= numberOfTokens;

        _mintTokens(numberOfTokens, to);
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