// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

error ErrorOnlyAllowEOA();
error ErrorSaleNotStarted();
error ErrorInsufficientFund();
error ErrorExceedMaxAllowed();
error ErrorExceedTransactionLimit();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();
error ErrorExceedReserveSupply();
error ErrorInvalidSignature();
error ErrorInvalidMintAmount();
error ErrorPendingAuction();

contract Youtopia is ERC721A, EIP712, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 private constant MINT_FUNC_DIGEST = keccak256("mint(address minter,uint32 maxAllowed)");
    uint256 public constant PRICE_MULTIPLIER = 0.0000001 ether;

    address public immutable _vault;
    uint256 public immutable _publicMintPrice;
    uint256 public immutable _allowlistPrice;

    uint32 public immutable _maxSupply;
    uint32 public immutable _publicSupply;
    uint32 public immutable _auctionSupply;
    uint32 public immutable _reservedSupply;
    uint32 public immutable _mintTxLimit;
    uint32 public immutable _mintWalletLimit;

    enum SaleState {
        NotStarted,
        Auction,
        Allowlist,
        Public,
        End,
        Max
    }

    struct Bid {
        address bidder;
        uint32 price;
        uint32 amount;
    }

    struct AuctionConfig {
        uint32 startingPrice;
        uint32 endingPrice;
        uint32 startTime;
        uint32 duration;
        uint32 discountPerInterval;
        uint32 interval;
    }

    struct SaleConfig {
        uint32 auctionBids;
        uint32 reservedMinted;
        SaleState saleState;
    }

    Bid[] public _bids;
    SaleConfig public _config;
    AuctionConfig public _auctionConfig;
    uint256 public _processedBids;
    string public _metadataURI = "https://assets.youtopia.space/metadata/placeholder/json/";

    constructor(
        uint256 publicMintPrice,
        uint256 allowlistPrice,
        uint32 maxSupply,
        uint32 auctionSupply,
        uint32 reservedSupply,
        uint32 mintTxLimit,
        uint32 mintWalletLimit,
        address vault
    ) ERC721A("Youtopia", "YTPA") EIP712("Youtopia", "1") {
        require(maxSupply >= auctionSupply + reservedSupply);

        _publicMintPrice = publicMintPrice;
        _allowlistPrice = allowlistPrice;

        _maxSupply = maxSupply;
        _auctionSupply = auctionSupply;
        _reservedSupply = reservedSupply;
        _mintTxLimit = mintTxLimit;
        _mintWalletLimit = mintWalletLimit;
        _publicSupply = _maxSupply - _reservedSupply;

        _vault = vault;
    }

    // ===== Modifier

    modifier ensureEOA() {
        if (tx.origin != msg.sender) revert ErrorOnlyAllowEOA();
        _;
    }

    modifier ensureValidateAmount(uint32 amount) {
        if (amount == 0) revert ErrorInvalidMintAmount();
        _;
    }

    modifier verifyAndExtractMaxAmount(
        uint32 maxAllowed,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
        bytes32 funcCallDigest = keccak256(abi.encode(
            MINT_FUNC_DIGEST,
            msg.sender,
            maxAllowed
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _domainSeparatorV4().toTypedDataHash(funcCallDigest))
        );

        if (ecrecover(digest, v, r, s) != address(owner())) revert ErrorInvalidSignature();
        _;
    }

    function ensureSaleState(SaleState desired, SaleState actual) internal pure {
        if (desired != actual) revert ErrorSaleNotStarted();
    }

    // ===== Mint functions

    function youtopiaPlaceBid(uint16 amount) external payable ensureEOA ensureValidateAmount(amount) {
        SaleConfig memory config = _config;
        AuctionConfig memory auctionConfig = _auctionConfig;

        if (SaleState.Auction != config.saleState
            || auctionConfig.startTime == 0
            || block.timestamp < auctionConfig.startTime) {
            revert ErrorSaleNotStarted();
        }

        config.auctionBids += amount;
        if (config.auctionBids > _auctionSupply) revert ErrorExceedMaxSupply();
        if (amount > _mintTxLimit) revert ErrorExceedTransactionLimit();
        if (incrementAuctionBid(amount) > _mintWalletLimit) revert ErrorExceedWalletLimit();

        uint32 price = internalAuctionPrice(auctionConfig);
        uint256 requiredValue = price * PRICE_MULTIPLIER * amount;
        if (msg.value < requiredValue) revert ErrorInsufficientFund();

        _config = config;
        _bids.push(Bid(msg.sender, price, amount));

        _safeMint(msg.sender, amount);
        refundIfOver(requiredValue);
    }

    function youtopiaAllowlistMint(
        uint16 amount,
        uint32 maxAllowed,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable verifyAndExtractMaxAmount(maxAllowed, r, s, v) ensureValidateAmount(amount) {
        ensureSaleState(SaleState.Allowlist, _config.saleState);

        if (_totalMinted() + amount > _publicSupply) revert ErrorExceedMaxSupply();
        if (incrementAllowlistMinted(amount) > maxAllowed) revert ErrorExceedMaxAllowed();
        if (_allowlistPrice * amount != msg.value) revert ErrorInsufficientFund();

        _safeMint(msg.sender, amount);
    }

    function youtopiaPublicMint(uint16 amount) external payable ensureEOA ensureValidateAmount(amount) {
        ensureSaleState(SaleState.Public, _config.saleState);

        if (_totalMinted() + amount > _publicSupply) revert ErrorExceedMaxSupply();
        if (amount > _mintTxLimit) revert ErrorExceedTransactionLimit();
        if (incrementPublicMinted(amount) > _mintWalletLimit) revert ErrorExceedWalletLimit();

        uint256 requiredValue = _publicMintPrice * amount;
        if (msg.value < requiredValue) revert ErrorInsufficientFund();

        _safeMint(msg.sender, amount);
        refundIfOver(requiredValue);
    }

    function youtopiaReservedMint(address to, uint16 amount) external onlyOwner {
        _config.reservedMinted += amount;
        if (_config.reservedMinted > _reservedSupply) revert ErrorExceedReserveSupply();

        _safeMint(to, amount);
    }

    // ===== View functions

    function _minted() external view returns(uint256) {
        return ERC721A._totalMinted();
    }

    function internalAuctionPrice(AuctionConfig memory config) internal view returns (uint32) {
        // [startTime, endTime)
        uint32 price;

        if (block.timestamp < config.startTime) {
            price = config.startingPrice;
        } else if (block.timestamp > config.startTime + config.duration) {
            price = config.endingPrice;
        } else {
            uint32 elapsedInterval = (uint32(block.timestamp) - config.startTime) / config.interval;
            price = config.startingPrice - elapsedInterval * config.discountPerInterval;
        }

        return price;
    }

    function _auctionPrice() public view returns (uint256) {
        return internalAuctionPrice(_auctionConfig) * PRICE_MULTIPLIER;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // ===== Admin functions

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setSaleState(SaleState saleState) external onlyOwner {
        _config.saleState = saleState;
    }

    function setAuctionState(
        uint32 startingPrice,
        uint32 endingPrice,
        uint32 startTime,
        uint32 duration,
        uint32 interval
    ) external onlyOwner {
        require(startingPrice >= endingPrice, "Starting Price too low");
        require(duration % interval == 0, "Duration % Interval != 0");

        uint32 priceDifference = startingPrice - endingPrice;
        uint32 step = duration / interval;
        require(priceDifference % step == 0, "PriceDiff % Step != 0");

        _auctionConfig = AuctionConfig({
            startingPrice: startingPrice,
            endingPrice: endingPrice,
            startTime: startTime,
            duration: duration,
            interval: interval,
            discountPerInterval: priceDifference / step
        });
    }

    function finalizeAuction(uint256 count) external onlyOwner {
        if (_config.saleState == SaleState.Auction) revert ErrorPendingAuction();
        if (_bids.length == 0) return;

        uint256 processedBids = _processedBids;
        uint256 biddersLength = _bids.length;
        uint256 counter = 0;
        uint32 lowestBid = _bids[_bids.length - 1].price;

        for (; counter < count && counter + processedBids < biddersLength; ++counter) {
            Bid memory bid = _bids[counter + processedBids];

            uint32 delta = bid.price - lowestBid;
            if (delta > 0) {
                payable(bid.bidder).sendValue(delta * PRICE_MULTIPLIER * bid.amount);
            }
        }

        _processedBids += counter;
    }

    function _bidsLength() external view returns(uint256) {
        return _bids.length;
    }

    function withdraw() external onlyOwner {
        if (_processedBids != _bids.length) revert ErrorPendingAuction();
        payable(_vault).sendValue(address(this).balance);
    }

    // ===== Utility functions

    function refundIfOver(uint256 requiredValue) internal {
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function _aux(address minter) public view returns (uint64) {
        return _getAux(minter);
    }

    function getMintedNumberInAux(uint64 aux, uint8 index) internal pure returns (uint16) {
        return uint16((aux >> (index * 16)) & 0xFFFF);
    }

    function incrementMintedNumberInAux(uint8 index, uint16 amount) internal returns (uint16) {
        uint64 offset = index * 16;
        uint64 mask = ~(uint64(0xFFFFFFFF) << offset);
        uint64 aux = _getAux(msg.sender);
        uint16 newMintedAmount = getMintedNumberInAux(aux, index) + amount;
        _setAux(msg.sender, (aux & mask) | (uint64(newMintedAmount) << offset));
        return newMintedAmount;
    }

    function _allowlistMinted(address minter) public view returns (uint16) {
        return getMintedNumberInAux(_getAux(minter), 0);
    }

    function incrementAllowlistMinted(uint16 amount) internal returns (uint16) {
        return incrementMintedNumberInAux(0, amount);
    }

    function _auctionBid(address minter) public view returns (uint16) {
        return getMintedNumberInAux(_getAux(minter), 1);
    }

    function incrementAuctionBid(uint16 amount) internal returns (uint16) {
        return incrementMintedNumberInAux(1, amount);
    }

    function _publicSaleMinted(address minter) public view returns (uint16) {
        return getMintedNumberInAux(_getAux(minter), 2);
    }

    function incrementPublicMinted(uint16 amount) internal returns (uint16) {
        return incrementMintedNumberInAux(2, amount);
    }
}