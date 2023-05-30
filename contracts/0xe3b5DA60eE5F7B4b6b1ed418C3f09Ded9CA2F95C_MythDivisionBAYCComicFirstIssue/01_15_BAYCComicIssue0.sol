// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MythDivisionExclusiveAccess.sol";

contract MythDivisionBAYCComicFirstIssue is
    ERC721,
    Pausable,
    Ownable,
    PaymentSplitter,
    MythDivisionExclusiveAccess
{
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 5636;
    uint256 public MAX_PRESALE_COUNT = 1500;
    uint256 _startingReservedCount = 136;
    uint256 _reservedCount = _startingReservedCount;
    uint8 _maxPurchaseCount = 15;
    uint256 _totalSupply = 0;
    uint256 _mintPrice = 0.01 ether;
    string _baseURIValue =
        "ipfs://QmccVkoBJkxxz2ZcJjWZQk8azDzWPh8xpbVesSFVPgWZCh/";
    uint256 _saleStart;
    ERC721 private boredApesContract;

    mapping(uint256 => uint256) _tokenVariantMap;

    constructor(
        uint256 saleStart_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address openseaStorefrontAddress,
        address boredApesAddress,
        uint256[] memory openseaMythDivisionTokens
    )
        ERC721("Bored Ape Seeking Yacht Club Issue #0", "BASYC-0")
        PaymentSplitter(payees, paymentShares)
        MythDivisionExclusiveAccess(openseaStorefrontAddress)
    {
        _saleStart = saleStart_;
        boredApesContract = ERC721(boredApesAddress);

        for (uint256 i = 0; i < openseaMythDivisionTokens.length; i++) {
            addMythDivisionOpenSeaToken(openseaMythDivisionTokens[i]);
        }

        addEligibleERC721Contract(boredApesAddress);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint256) {
        return _saleStart - 3600;
    }

    function setSaleStart(uint256 saleStart_) public onlyOwner {
        _saleStart = saleStart_;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return presaleStart() <= block.timestamp;
    }

    function reservedCount() public view returns (uint256) {
        return _reservedCount;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();

        return
            string(
                abi.encodePacked(base, _tokenVariantMap[tokenId].toString())
            );
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

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            _totalSupply.add(_reservedCount).add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier mintCountMeetsPresaleSupply(uint256 numberOfTokens) {
        require(
            _totalSupply.add(numberOfTokens).add(_reservedCount) <=
                MAX_PRESALE_COUNT.add(_startingReservedCount),
            "Presale has sold out. Please wait for primary sale to begin."
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 10 tokens at a time"
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

    function _mintTokens(
        uint256 numberOfTokens,
        address to,
        bool forReserves
    ) internal {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    block.number,
                    msg.sender
                )
            )
        );

        bool ownsBoredApes = !forReserves &&
            boredApesContract.balanceOf(to) > 0;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _totalSupply += 1;
            uint256 tokenId = _totalSupply;

            uint256 rand = _randomVariantIndex(seed, tokenId);
            uint8 variant;

            if (ownsBoredApes) {
                if (rand < 10) {
                    variant = 3;
                } else if (rand < 20) {
                    variant = 2;
                } else {
                    variant = 1;
                }
            } else {
                if (rand < 5) {
                    variant = 3;
                } else if (rand < 10) {
                    variant = 2;
                } else {
                    variant = 1;
                }
            }

            _tokenVariantMap[tokenId] = variant;

            _safeMint(to, tokenId);
        }
    }

    function _randomVariantIndex(uint256 seed, uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed, tokenId))) % 200;
    }

    function mintPresale(uint16 numberOfTokens)
        public
        payable
        mintCountMeetsPresaleSupply(numberOfTokens)
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(presaleHasStarted(), "Presale has not started yet");
        require(canAccessPresale(), "Account does not own MythDivision tokens");

        _mintTokens(numberOfTokens, msg.sender, false);
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

        _mintTokens(numberOfTokens, msg.sender, false);
    }

    function mintReserved(uint256 numberOfTokens, address to) public onlyOwner {
        uint256 initialSupply = _totalSupply;
        require(
            numberOfTokens <= _reservedCount,
            "Would exceed reserved supply"
        );
        require(
            numberOfTokens.add(initialSupply) <= MAX_SUPPLY,
            "Would exceed reserved supply"
        );

        _reservedCount = _reservedCount.sub(numberOfTokens);

        _mintTokens(numberOfTokens, to, true);
    }
}