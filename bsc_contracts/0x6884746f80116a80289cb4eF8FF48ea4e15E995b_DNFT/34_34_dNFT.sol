// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceFeed.sol";
import "./Whitelist.sol";
import "./MergeHelper.sol";
import "./Error.sol";
import "./MergeWorker.sol";

contract DNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721RoyaltyUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct SalePhase {
        uint256 startTime;
        uint256 endTime;
        uint256 priceInBUSD;
        uint256 priceAfter24Hours;
        uint256 maxAmountUserCanBuy;
        uint256 maxSaleAmount;
        uint256 totalSold;
        mapping(address => uint256) userBuyAmount;
    }

    uint8 public currentSalePhase;
    uint256 public claimableTime;
    uint256 public totalClaimed;
    uint256 public rescuePrice;
    uint256 public totalUserRescued;
    uint256 public totalAdminRescued;
    uint256 public launchPrice;
    mapping(address => uint256) public userClaimedAmount;
    mapping(uint8 => SalePhase) public salePhaseStatistics;

    IERC20 public BUSDToken;
    IERC20 public GalactixToken;
    IERC721 public DKEYNFTToken;
    address public priceFeed;
    MergeWorker private mergeWorker;

    string public baseURI;
    address public signer;
    address public treasuryAddress;
    uint256 public minimumGalactixTokenRequire;

    mapping(uint256 => uint256) public nextTimeUsingKey;
    mapping(address => uint256) public nonces;

    /*---------- CONSTANTS -----------*/
    uint256 private constant ONE_MONTH = 30 days;
    uint256 private constant SEVEN_DAYS = 7 days;
    uint256 private constant ONE_DAY = 1 days;
    uint256 private constant BUSD_DECIMALS = 1e18;
    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    uint256 private constant MINT_TAX_RATE = 800; // 8%
    uint256 private constant RESCUE_TAX_RATE = 1200; // 12%
    uint256 private constant MAX_SALE_AMOUNT = 2500;

    /*---------- EVENTS -----------*/
    event SalePhaseDeployed(
        uint8 indexed _salePhase,
        uint256 startTime,
        uint256 endTime,
        uint256 priceInBUSD,
        uint256 priceAfter24Hours,
        uint256 maxAmountUserCanBuy
    );
    event SignerChanged(address _signer);
    event RoyaltyChanged(uint256 _feeRate);
    event BaseURIChanged(string baseURI_);
    event ClaimableTimeChanged(uint256 _claimableTime);
    event PriceFeedChanged(address _priceFeed);
    event TreasuryAddressChanged(address _treasuryAddress);
    event DKEYNFTTokenChanged(address _DKEYNFTToken);
    event MinimumGalactixTokenRequireChanged(uint256 _minimumGalactixTokenRequire);
    event RescuePriceChanged(uint256 _rescuePrice);
    event LaunchPriceChanged(uint256 _launchPrice);
    event BUSDTokenChanged(address _BUSDToken);
    event GalactixTokenChanged(address _GalactixToken);
    event BuyWithBUSD(address _buyer);
    event BuyWithBNB(address _buyer);
    event RescueWithKey(address _buyer, uint256 indexed _dnftTokenId);
    event PurchasedTokenClaimed(address _buyer, uint256[] _tokenIds);
    event TemporaryMerged(address _to, uint256[] _tokenIds, string _sessionId);
    event TemporaryMergeCancelled(address _to, uint256[] _tokenIds, string _sessionId);
    event TemporaryMergeExecuted(address _to, uint256[] _tokenIds, uint256 indexed _newTokenId, string _sessionId);
    event PermanentMerged(address _to, uint256[] _tokenIds, uint256 indexed _newTokenId, string _sessionId);
    event AdminRescued(address _admin, uint256[] _tokenIds);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    function initialize(
        string memory baseURI_,
        address _signer,
        IERC20 _BUSDToken,
        IERC20 _GalactixToken,
        MergeWorker _mergeWorker
    ) external initializer {
        __ERC721_init("Galactix Zone Kalpa Avian", "GKA");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();

        // Token ID starts from 1
        _tokenIdCounter.increment();

        /**
         * Network: BSC Mainnet
         * Aggregator: BUSD/BNB
         * Address: 0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941
         */
        priceFeed = 0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941;

        if (_signer == address(0)) revert ZERO_ADDRESS();
        if (address(_BUSDToken) == address(0)) revert ZERO_ADDRESS();
        if (address(_GalactixToken) == address(0)) revert ZERO_ADDRESS();
        if (address(_mergeWorker) == address(0)) revert ZERO_ADDRESS();

        baseURI = baseURI_;
        signer = _signer;
        BUSDToken = _BUSDToken;
        GalactixToken = _GalactixToken;
        mergeWorker = _mergeWorker;
    }

    /*---------- MODIFIERS -----------*/
    modifier inSalePhase() {
        _inSalePhase();
        _;
    }

    modifier claimable() {
        _claimable();
        _;
    }

    modifier hasTreasuryAddress() {
        _hasTreasuryAddress();
        _;
    }

    /*---------- INIT FUNCTIONS -----------*/
    function deployNewSalePhase(
        uint8 _salePhase,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _priceInBUSD,
        uint256 _priceAfter24Hours,
        uint256 _maxAmountUserCanBuy
    ) external onlyOwner {
        if (_salePhase < 1 || _salePhase > 4 || _salePhase != currentSalePhase + 1) revert INVALID_SALE_PHASE();
        if (_startTime < block.timestamp || _startTime < salePhaseStatistics[currentSalePhase].endTime)
            revert INVALID_START_TIME();
        if (block.timestamp < salePhaseStatistics[currentSalePhase].endTime) revert CURRENT_SALE_PHASE_NOT_ENDED();
        if (_endTime < _startTime) revert INVALID_END_TIME();
        if (_priceInBUSD == 0) revert INVALID_PRICE();
        if (_priceAfter24Hours == 0) revert INVALID_PRICE_AFTER_24_HOURS();
        if (_maxAmountUserCanBuy == 0 || _maxAmountUserCanBuy > MAX_SALE_AMOUNT)
            revert INVALID_MAX_AMOUNT_USER_CAN_BUY();

        salePhaseStatistics[_salePhase].startTime = _startTime;
        // remove endTime of last sale phase, set the launch price
        if (_salePhase == 4) {
            salePhaseStatistics[_salePhase].endTime = 2**256 - 1;
            if (launchPrice == 0) revert LAUNCH_PRICE_NOT_SET();
            salePhaseStatistics[_salePhase].priceInBUSD = launchPrice;
            salePhaseStatistics[_salePhase].priceAfter24Hours = launchPrice;
        } else {
            salePhaseStatistics[_salePhase].endTime = _endTime;
            salePhaseStatistics[_salePhase].priceInBUSD = _priceInBUSD;
            salePhaseStatistics[_salePhase].priceAfter24Hours = _priceAfter24Hours;
        }
        salePhaseStatistics[_salePhase].maxAmountUserCanBuy = _maxAmountUserCanBuy;
        salePhaseStatistics[_salePhase].maxSaleAmount = MAX_SALE_AMOUNT;
        salePhaseStatistics[_salePhase].totalSold = 0;

        if (_salePhase == 3) {
            setClaimableTime(_endTime + SEVEN_DAYS);
        }

        currentSalePhase = _salePhase;

        emit SalePhaseDeployed(
            _salePhase,
            _startTime,
            salePhaseStatistics[_salePhase].endTime,
            salePhaseStatistics[_salePhase].priceInBUSD,
            salePhaseStatistics[_salePhase].priceAfter24Hours,
            _maxAmountUserCanBuy
        );
    }

    /*---------- CONFIG FUNCTIONS -----------*/
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert ZERO_ADDRESS();
        signer = _signer;
        emit SignerChanged(_signer);
    }

    function setRoyalty(uint96 _feeRate) external hasTreasuryAddress onlyOwner {
        if (_feeRate > ONE_HUNDRED_PERCENT) revert INVALID_ROYALTY_FEE_RATE();
        _setDefaultRoyalty(treasuryAddress, _feeRate);
        emit RoyaltyChanged(_feeRate);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function setDKEYNFTToken(IERC721 _DKEYNFTToken) external onlyOwner {
        if (address(_DKEYNFTToken) == address(0)) revert ZERO_ADDRESS();
        DKEYNFTToken = _DKEYNFTToken;
        emit DKEYNFTTokenChanged(address(_DKEYNFTToken));
    }

    function setMinimumGalactixTokenRequire(uint256 _minimumGalactixTokenRequire) external onlyOwner {
        minimumGalactixTokenRequire = _minimumGalactixTokenRequire;
        emit MinimumGalactixTokenRequireChanged(_minimumGalactixTokenRequire);
    }

    function setRescuePrice(uint256 _rescuePrice) external onlyOwner {
        rescuePrice = _rescuePrice;
        emit RescuePriceChanged(_rescuePrice);
    }

    function setLaunchPrice(uint256 _launchPrice) external onlyOwner {
        if (_launchPrice == 0) revert INVALID_LAUNCH_PRICE();
        launchPrice = _launchPrice;
        if (currentSalePhase == 4) {
            salePhaseStatistics[currentSalePhase].priceInBUSD = _launchPrice;
            salePhaseStatistics[currentSalePhase].priceAfter24Hours = _launchPrice;
        }
        emit LaunchPriceChanged(_launchPrice);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        if (_treasuryAddress == address(0)) revert ZERO_ADDRESS();
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressChanged(_treasuryAddress);
    }

    // todo: change to private when deploy mainnet
    function setClaimableTime(uint256 _claimableTime) public onlyOwner {
        claimableTime = _claimableTime;
        emit ClaimableTimeChanged(_claimableTime);
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        if (_priceFeed == address(0)) revert ZERO_ADDRESS();
        priceFeed = _priceFeed;
        emit PriceFeedChanged(_priceFeed);
    }

    /*---------- BUY FUNCTIONS -----------*/
    function buyUsingBUSD(
        uint8 _salePhase,
        address _to,
        bytes memory _signature
    ) external whenNotPaused inSalePhase hasTreasuryAddress nonReentrant {
        if (_salePhase != currentSalePhase) revert INVALID_SALE_PHASE();
        if (!verifyBuySignature(_salePhase, _to, _signature)) revert INVALID_SIGNATURE();
        if (!canBuy(_to)) revert CANNOT_BUY();

        uint256 busdBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
        uint256 priceInBUSD = salePhaseStatistics[currentSalePhase].priceInBUSD;
        if (block.timestamp > salePhaseStatistics[currentSalePhase].startTime + ONE_DAY) {
            priceInBUSD = salePhaseStatistics[currentSalePhase].priceAfter24Hours;
        }
        uint256 taxAmount = getMintTaxAmount(priceInBUSD);
        if (busdBalanceOfBuyer < priceInBUSD + taxAmount) revert INSUFFICIENT_BUSD();

        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, priceInBUSD + taxAmount);

        salePhaseStatistics[currentSalePhase].totalSold++;
        salePhaseStatistics[currentSalePhase].userBuyAmount[msg.sender]++;
        nonces[msg.sender]++;

        emit BuyWithBUSD(msg.sender);
    }

    function buyUsingBNB(
        uint8 _salePhase,
        address _to,
        bytes memory _signature
    ) external payable whenNotPaused inSalePhase hasTreasuryAddress nonReentrant {
        if (_salePhase != currentSalePhase) revert INVALID_SALE_PHASE();
        if (!verifyBuySignature(_salePhase, _to, _signature)) revert INVALID_SIGNATURE();
        if (!canBuy(_to)) revert CANNOT_BUY();

        uint256 priceInBUSD = salePhaseStatistics[currentSalePhase].priceInBUSD;
        if (block.timestamp > salePhaseStatistics[currentSalePhase].startTime + ONE_DAY) {
            priceInBUSD = salePhaseStatistics[currentSalePhase].priceAfter24Hours;
        }
        uint256 priceInBNB = PriceFeed.convertBUSDToBNB(priceInBUSD, priceFeed);
        if (msg.value < priceInBNB) revert INSUFFICIENT_BNB();
        uint256 taxAmount = getMintTaxAmount(priceInBUSD);

        uint256 busdBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
        if (busdBalanceOfBuyer < taxAmount) revert INSUFFICIENT_BUSD();

        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        salePhaseStatistics[currentSalePhase].totalSold++;
        salePhaseStatistics[currentSalePhase].userBuyAmount[msg.sender]++;
        nonces[msg.sender]++;

        if (msg.value > priceInBNB) {
            Address.sendValue(payable(msg.sender), msg.value - priceInBNB);
            Address.sendValue(payable(treasuryAddress), priceInBNB);
        } else {
            Address.sendValue(payable(treasuryAddress), msg.value);
        }

        emit BuyWithBNB(msg.sender);
    }

    function rescueUsingKey(uint256 _keyTokenId, bool _isUsingBNB)
        external
        payable
        whenNotPaused
        hasTreasuryAddress
        nonReentrant
    {
        uint256 cosmicVoid = getNumberOfTokenInCosmicVoid() / 2;
        if (totalUserRescued >= cosmicVoid) revert ALL_TOKENS_ARE_SOLD_OR_RESCUED();
        if (currentSalePhase < 3 || block.timestamp < salePhaseStatistics[3].endTime) revert NOT_YET_RESCUE_TIME();
        if (DKEYNFTToken.ownerOf(_keyTokenId) != msg.sender) revert NOT_OWNER_OF_KEY();
        if (nextTimeUsingKey[_keyTokenId] > block.timestamp) revert KEY_IS_USED_THIS_MONTH();

        uint256 taxAmount = getRescueTaxAmount();
        uint256 rescuePriceInBNB = PriceFeed.convertBUSDToBNB(rescuePrice, priceFeed);

        if (_isUsingBNB) {
            if (msg.value < rescuePriceInBNB) revert INSUFFICIENT_BNB();

            uint256 busdBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
            if (busdBalanceOfBuyer < taxAmount) revert INSUFFICIENT_BUSD();
            BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);
        } else {
            uint256 BUSDBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
            if (BUSDBalanceOfBuyer < rescuePrice + taxAmount) revert INSUFFICIENT_BUSD();
            BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, rescuePrice + taxAmount);
        }

        nextTimeUsingKey[_keyTokenId] = block.timestamp + ONE_MONTH;
        totalUserRescued++;
        uint256 newTokenId = safeMint(msg.sender);

        // refund
        if (_isUsingBNB) {
            if (msg.value > rescuePriceInBNB) {
                Address.sendValue(payable(msg.sender), msg.value - rescuePriceInBNB);
                Address.sendValue(payable(treasuryAddress), rescuePriceInBNB);
            } else {
                Address.sendValue(payable(treasuryAddress), msg.value);
            }
        } else {
            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
        }

        emit RescueWithKey(msg.sender, newTokenId);
    }

    function restrictedRescue(uint256 _numberOfNfts) external whenNotPaused onlyOwner {
        if (_numberOfNfts < 1 || _numberOfNfts > 50) revert INVALID_NUMBER_OF_NFTS();
        if (currentSalePhase < 3 || block.timestamp < salePhaseStatistics[3].endTime) revert NOT_YET_RESCUE_TIME();
        uint256 maxAvailableRescueNumber = getNumberOfTokenInCosmicVoid() / 2;
        if (totalAdminRescued >= maxAvailableRescueNumber) revert ALL_TOKENS_ARE_SOLD_OR_RESCUED();

        uint256[] memory tokenIds = new uint256[](_numberOfNfts);
        for (uint256 i = 0; i < _numberOfNfts; i++) {
            uint256 newTokenId = safeMint(msg.sender);
            totalAdminRescued++;
            tokenIds[i] = newTokenId;
        }
        emit AdminRescued(msg.sender, tokenIds);
    }

    /*---------- CLAIM FUNCTIONS -----------*/
    function claimPurchasedToken(uint256 _amountOfToken) external whenNotPaused claimable nonReentrant {
        uint256 claimableAmount = getClaimableAmountOfBuyer(msg.sender);
        if (claimableAmount < _amountOfToken) revert INSUFFICIENT_CLAIMABLE_AMOUNT();
        uint256[] memory tokenIds = new uint256[](_amountOfToken);
        for (uint256 i = 0; i < _amountOfToken; i++) {
            uint256 tokenId = safeMint(msg.sender);
            tokenIds[i] = tokenId;
        }
        userClaimedAmount[msg.sender] += _amountOfToken;
        totalClaimed += _amountOfToken;

        emit PurchasedTokenClaimed(msg.sender, tokenIds);
    }

    /*---------- MERGE FUNCTIONS -----------*/
    function temporaryMerge(
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        uint256 mergeTax = getMergeTax();
        uint256 BUSDBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
        if (BUSDBalanceOfBuyer < mergeTax) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, mergeTax);
        mergeWorker.temporaryMerge(
            nonces[msg.sender],
            msg.sender,
            signer,
            _tokenIds,
            _timestamp,
            _sessionId,
            _signature
        );
        nonces[msg.sender]++;

        emit TemporaryMerged(msg.sender, _tokenIds, _sessionId);
    }

    function cancelTemporaryMerge(
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        mergeWorker.cancelTemporaryMerge(
            nonces[msg.sender],
            msg.sender,
            signer,
            _tokenIds,
            _timestamp,
            _sessionId,
            _signature
        );
        nonces[msg.sender]++;

        emit TemporaryMergeCancelled(msg.sender, _tokenIds, _sessionId);
    }

    function executeTemporaryMerge(uint256[] memory _tokenIds, string memory _sessionId)
        external
        whenNotPaused
        nonReentrant
    {
        bool success = mergeWorker.executeTemporaryMerge(_tokenIds, msg.sender, _sessionId);
        if (!success) revert NOT_OWNER_OF_TOKEN_OR_TOKEN_IS_LOCKED();

        // burn tokens
        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            _burn(_tokenIds[i]);
        }
        uint256 newTokenId = safeMint(msg.sender);

        emit TemporaryMergeExecuted(msg.sender, _tokenIds, newTokenId, _sessionId);
    }

    function permanentMerge(
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        uint256 mergeTax = getMergeTax();
        uint256 BUSDBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
        if (BUSDBalanceOfBuyer < mergeTax) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, mergeTax);

        bool success = mergeWorker.permanentMerge(
            nonces[msg.sender],
            msg.sender,
            signer,
            _tokenIds,
            _timestamp,
            _sessionId,
            _signature
        );
        if (!success) revert NOT_OWNER_OF_TOKEN_OR_TOKEN_IS_LOCKED();

        // burn tokens
        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            _burn(_tokenIds[i]);
        }
        uint256 newTokenId = safeMint(msg.sender);
        nonces[msg.sender]++;

        emit PermanentMerged(msg.sender, _tokenIds, newTokenId, _sessionId);
    }

    /*---------- MODIFIER HELPERS -----------*/
    function _inSalePhase() private view {
        if (
            block.timestamp < salePhaseStatistics[currentSalePhase].startTime ||
            block.timestamp > salePhaseStatistics[currentSalePhase].endTime
        ) revert NOT_IN_SALE_PHASE();
    }

    function _claimable() private view {
        if (currentSalePhase < 3 || block.timestamp < claimableTime) revert NOT_CLAIMABLE_TIME();
    }

    function _hasTreasuryAddress() private view {
        if (treasuryAddress == address(0)) revert TREASURY_ADDRESS_NOT_SET();
    }

    /*---------- HELPER FUNCTIONS -----------*/
    function safeMint(address _to) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        return tokenId;
    }

    function verifyBuySignature(
        uint8 _salePhase,
        address _to,
        bytes memory _signature
    ) private view returns (bool) {
        if (msg.sender != _to) revert WRONG_CANDIDATE();
        return (Whitelist.verifySignatureWhenBuyDNFT(nonces[_to], _salePhase, signer, _to, _signature));
    }

    function canBuy(address _to) private view returns (bool) {
        if (GalactixToken.balanceOf(_to) < minimumGalactixTokenRequire && currentSalePhase != 4) return false;
        if (salePhaseStatistics[currentSalePhase].totalSold == salePhaseStatistics[currentSalePhase].maxSaleAmount)
            return false;
        if (
            salePhaseStatistics[currentSalePhase].userBuyAmount[_to] ==
            salePhaseStatistics[currentSalePhase].maxAmountUserCanBuy
        ) return false;
        return true;
    }

    function getRescueTaxAmount() public view returns (uint256) {
        if (launchPrice == 0) revert LAUNCH_PRICE_NOT_SET();
        return (launchPrice * RESCUE_TAX_RATE) / ONE_HUNDRED_PERCENT;
    }

    function getMintTaxAmount(uint256 _priceInBUSD) public pure returns (uint256) {
        return (_priceInBUSD * MINT_TAX_RATE) / ONE_HUNDRED_PERCENT;
    }

    function getClaimableAmountOfBuyer(address _buyer) public view returns (uint256) {
        uint256 totalPurchasedAmount = 0;
        for (uint8 i = 1; i <= 4; i++) {
            totalPurchasedAmount += salePhaseStatistics[i].userBuyAmount[_buyer];
        }
        return totalPurchasedAmount - userClaimedAmount[_buyer];
    }

    /*---------- OVERRIDE FUNCTIONS -----------*/
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) whenNotPaused {
        if (mergeWorker.isTokenLocked(tokenId)) revert TOKEN_IS_LOCKED();
        uint256 taxAmount = getMintTaxAmount(launchPrice);
        if (BUSDToken.balanceOf(msg.sender) < taxAmount) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) whenNotPaused {
        if (mergeWorker.isTokenLocked(tokenId)) revert TOKEN_IS_LOCKED();
        uint256 taxAmount = getMintTaxAmount(launchPrice);
        if (BUSDToken.balanceOf(msg.sender) < taxAmount) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        super.transferFrom(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*---------- HOOKS -----------*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*---------- GETTERS -----------*/
    function getNumberOfTokenInCosmicVoid() public view returns (uint256) {
        uint256 unSoldToken = 0;
        for (uint8 i = 1; i <= 3; i++) {
            unSoldToken += salePhaseStatistics[i].maxSaleAmount - salePhaseStatistics[i].totalSold;
        }
        return unSoldToken;
    }

    function getUserBuyAmount(uint8 _salePhase, address _buyer) external view returns (uint256) {
        return salePhaseStatistics[_salePhase].userBuyAmount[_buyer];
    }

    function getMergeTax() public view returns (uint256) {
        return (MINT_TAX_RATE * launchPrice) / ONE_HUNDRED_PERCENT;
    }
}