// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Whitelist.sol";

contract PreSalePool is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public BUSDToken;
    IERC20 public preSaleToken;
    AggregatorV3Interface internal priceFeed;

    struct SalePhase {
        uint256 startTime;
        uint256 endTime;
        uint256[] claimTime;
        uint256[] claimRate;
        bool isNoBuyLimit;
        uint256 maxBUSDUserCanSpend;
        uint256 preSaleTokenPrice; // in BUSD
        uint256 maxPreSaleAmount;
        uint256 totalSoldAmount;
        uint256 totalClaimedAmount;
        address treasuryAddress;
        mapping(address => uint256) BUSDUserSpent;
        mapping(address => uint256) userPurchasedAmount;
        mapping(address => uint256) userClaimedAmount;
    }

    uint8 public totalSalePhase;
    uint8 public currentSalePhase;

    mapping(uint8 => SalePhase) public salePhaseStatistics;

    address public superAdmin;
    mapping(address => bool) public subAdmins;

    address public signer;
    mapping(address => uint256) public nonces;

    /*---------- CONSTANTS -----------*/
    uint256 public constant MULTIPLIER = 1e18;
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint256 public constant TAX = 225; // 2.25%

    /*---------- EVENTS -----------*/
    event PoolCreated(address _superAdmin, address _signer);
    event PreSaleTokenSet(IERC20 _preSaleToken);
    event BUSDTokenSet(IERC20 _BUSDToken);

    event NewSalePhaseDeployed(
        uint8 _salePhase,
        uint256 _startTime,
        uint256 _endTime,
        uint256[] _claimTime,
        uint256[] _claimRate,
        bool _isNoBuyLimit,
        uint256 _maxBUSDUserCanSpend,
        uint256 _maxPreSaleAmount,
        uint256 _preSaleTokenPrice,
        address _treasuryAddress
    );

    event SubAdminsAdded(address _subAdmin);
    event SubAdminsRemoved(address _subAdmin);
    event NewSignerSet(address _signer);
    event PriceFeedSet(address _priceFeed);
    event SuperAdminChanged(address _superAdmin);
    event BuyTokenWithExactlyBUSD(address indexed _candidate, uint256 _BUSDAmount);
    event BuyTokenWithExactlyBNB(address indexed _candidate, uint256 _BNBAmount);
    event BuyTokenWithoutFee(address indexed _candidate, uint256 _TokenAmount);
    event TokenClaimed(address indexed _candidate, uint256 _tokenAmount, uint8 _salePhase);
    event WithdrawPresaleToken(uint256 _tokenAmount);

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _signer,
        IERC20 _BUSDToken,
        IERC20 _GXZToken
    ) public initializer {
        require(_signer != address(0), "POOL: INVALID SIGNER");
        require(address(_BUSDToken) != address(0), "POOL: INVALID BUSD TOKEN");
        require(address(_GXZToken) != address(0), "POOL: INVALID GXZ TOKEN");

        __Pausable_init();
        __ReentrancyGuard_init();

        superAdmin = msg.sender;
        signer = _signer;
        BUSDToken = _BUSDToken;
        preSaleToken = _GXZToken;

        /**
         * Network: BSC Mainnet
         * Aggregator: BUSD/BNB
         * Address: 0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941
         */
        priceFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);

        emit PoolCreated(msg.sender, _signer);
    }

    /*---------- MODIFIERS -----------*/
    modifier onlyAdmin() {
        require(msg.sender == superAdmin || isSubAdmin(msg.sender), "POOL: UNAUTHORIZED");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "POOL: UNAUTHORIZED");
        _;
    }

    modifier inSalePhase() {
        require(block.timestamp <= salePhaseStatistics[currentSalePhase].endTime, "POOL: NOT IN SALE PHASE");
        require(block.timestamp >= salePhaseStatistics[currentSalePhase].startTime, "POOL: NOT IN SALE PHASE");
        _;
    }

    /*---------- CONFIG FUNCTIONS -----------*/
    function setPreSaleToken(IERC20 _preSaleToken) external onlyAdmin {
        require(address(_preSaleToken) != address(0), "POOL: INVALID PRESALE TOKEN");
        preSaleToken = _preSaleToken;
        emit PreSaleTokenSet(_preSaleToken);
    }

    function setBUSDToken(IERC20 _BUSDToken) external onlyAdmin {
        require(address(_BUSDToken) != address(0), "POOL: INVALID BUSD TOKEN");
        BUSDToken = _BUSDToken;
        emit BUSDTokenSet(_BUSDToken);
    }

    function deployNewSalePhase(
        uint8 _salePhase,
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _claimTime,
        uint256[] memory _claimRate,
        bool _isNoBuyLimit,
        uint256 _maxBUSDUserCanSpend,
        uint256 _preSaleTokenPrice, // in BUSD
        uint256 _maxPreSaleAmount,
        address _treasuryAddress
    ) external onlyAdmin {
        require(salePhaseStatistics[_salePhase].startTime == 0, "POOL: SALE PHASE ALREADY EXIST");
        require(
            _startTime >= block.timestamp && _startTime >= salePhaseStatistics[currentSalePhase].endTime,
            "POOL: INVALID START TIME"
        );
        require(block.timestamp >= salePhaseStatistics[currentSalePhase].endTime, "POOL: CURRENT SALE PHASE NOT ENDED");
        require(_endTime > _startTime, "POOL: INVALID END TIME");
        require(isClaimTimeValid(_claimTime, _claimRate, _endTime), "POOL: INVALID CLAIM TIME OR RATE");
        if (!_isNoBuyLimit) {
            require(_maxBUSDUserCanSpend > 0, "POOL: INVALID MAX BUSD USER CAN SPEND");
        }
        require(_maxPreSaleAmount > 0, "POOL: INVALID MAX PRESALE AMOUNT");
        require(_preSaleTokenPrice >= 0, "POOL: INVALID PRESALE TOKEN PRICE");
        require(_treasuryAddress != address(0), "POOL: INVALID TREASURY ADDRESS");

        SalePhase storage newSalePhase = salePhaseStatistics[_salePhase];
        newSalePhase.startTime = _startTime;
        newSalePhase.endTime = _endTime;

        newSalePhase.claimTime = _claimTime;
        newSalePhase.claimRate = _claimRate;

        newSalePhase.isNoBuyLimit = _isNoBuyLimit;
        newSalePhase.maxBUSDUserCanSpend = _maxBUSDUserCanSpend;

        newSalePhase.maxPreSaleAmount = _maxPreSaleAmount;
        newSalePhase.preSaleTokenPrice = _preSaleTokenPrice;
        newSalePhase.totalSoldAmount = 0;
        newSalePhase.totalClaimedAmount = 0;
        newSalePhase.treasuryAddress = _treasuryAddress;

        totalSalePhase++;
        currentSalePhase = _salePhase;
        emit NewSalePhaseDeployed(
            _salePhase,
            _startTime,
            _endTime,
            _claimTime,
            _claimRate,
            _isNoBuyLimit,
            _maxBUSDUserCanSpend,
            _maxPreSaleAmount,
            _preSaleTokenPrice,
            _treasuryAddress
        );
    }

    function addSubAdmin(address _subAdmin) external onlySuperAdmin {
        require(_subAdmin != address(0), "POOL: ZERO ADDRESS");
        require(!isSubAdmin(_subAdmin), "POOL: ALREADY SUB ADMIN");
        require(_subAdmin != superAdmin, "POOL: ALREADY SUPER ADMIN");
        subAdmins[_subAdmin] = true;

        emit SubAdminsAdded(_subAdmin);
    }

    function removeSubAdmin(address _subAdmin) external onlySuperAdmin {
        require(isSubAdmin(_subAdmin), "POOL: NOT SUB ADMIN");
        subAdmins[_subAdmin] = false;

        emit SubAdminsRemoved(_subAdmin);
    }

    function setSigner(address _signer) external onlyAdmin {
        require(_signer != address(0), "POOL: ZERO ADDRESS");
        signer = _signer;
        emit NewSignerSet(_signer);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function changeSuperAdmin(address _newSuperAdmin) external onlySuperAdmin {
        require(_newSuperAdmin != address(0), "POOL: INVALID NEW SUPER ADMIN");
        if (isSubAdmin(_newSuperAdmin)) {
            subAdmins[_newSuperAdmin] = false;
        }
        superAdmin = _newSuperAdmin;

        emit SuperAdminChanged(_newSuperAdmin);
    }

    function setPriceFeed(address _priceFeed) external onlyAdmin {
        require(_priceFeed != address(0), "POOL: INVALID PRICE FEED");
        priceFeed = AggregatorV3Interface(_priceFeed);
        emit PriceFeedSet(_priceFeed);
    }

    /*---------- HELPER FUNCTIONS -----------*/
    function getTokenAmountFromBUSD(uint256 _BUSDAmount, uint256 _tokenPriceInBUSD) public pure returns (uint256) {
        return (_BUSDAmount * MULTIPLIER) / _tokenPriceInBUSD;
    }

    function getBUSDAmountFromToken(uint256 _tokenAmount, uint256 _tokenPriceInBUSD) public pure returns (uint256) {
        return (_tokenAmount * _tokenPriceInBUSD) / MULTIPLIER;
    }

    function convertBUSDToBNB(uint256 _BUSDAmount) public view returns (uint256) {
        int256 BNBPerBUSD = getLatestPrice();
        require(BNBPerBUSD > 0, "POOL: INVALID BNB/BUSD PRICE");
        uint8 decimals = getPriceFeedDecimals();
        uint256 BNBPerBUSDInUint256 = uint256(BNBPerBUSD);
        return (_BUSDAmount * BNBPerBUSDInUint256) / (10**decimals);
    }

    function convertBNBToBUSD(uint256 _BNBAmount) public view returns (uint256) {
        int256 BNBPerBUSD = getLatestPrice();
        require(BNBPerBUSD > 0, "POOL: INVALID BNB/BUSD PRICE");
        uint8 decimals = getPriceFeedDecimals();
        uint256 BNBPerBUSDInUint256 = uint256(BNBPerBUSD);
        return (_BNBAmount * (10**decimals)) / BNBPerBUSDInUint256;
    }

    function isSubAdmin(address _address) private view returns (bool) {
        return subAdmins[_address];
    }

    function canBuyMoreToken(address _candidate, uint256 _BUSDAmount) private view returns (bool) {
        if (_BUSDAmount == 0) return false;

        uint256 maxPreSaleAmount = salePhaseStatistics[currentSalePhase].maxPreSaleAmount;
        uint256 totalSoldAmount = salePhaseStatistics[currentSalePhase].totalSoldAmount;

        uint256 tokenAmountUserCanBuy = getTokenAmountFromBUSD(
            _BUSDAmount,
            salePhaseStatistics[currentSalePhase].preSaleTokenPrice
        );
        if (tokenAmountUserCanBuy + totalSoldAmount > maxPreSaleAmount) return false;

        bool isNoBuyLimit = salePhaseStatistics[currentSalePhase].isNoBuyLimit;
        if (!isNoBuyLimit) {
            uint256 maxBUSDUserCanSpend = salePhaseStatistics[currentSalePhase].maxBUSDUserCanSpend;

            uint256 totalBUSDUserSpent = salePhaseStatistics[currentSalePhase].BUSDUserSpent[_candidate];
            return totalBUSDUserSpent + _BUSDAmount <= maxBUSDUserCanSpend;
        }

        return true;
    }

    function getClaimableAmount(address _candidate, uint8 _salePhase) private view returns (uint256) {
        require(block.timestamp >= salePhaseStatistics[_salePhase].claimTime[0], "POOL: CLAIM IS NOT AVAILABLE");

        uint256 totalPurchasedAmount = salePhaseStatistics[_salePhase].userPurchasedAmount[_candidate];
        uint256 totalClaimedAmount = salePhaseStatistics[_salePhase].userClaimedAmount[_candidate];

        uint256[] memory claimTime = salePhaseStatistics[_salePhase].claimTime;
        uint256[] memory claimRate = salePhaseStatistics[_salePhase].claimRate;
        uint256 claimableRate = 0;
        for (uint256 i = 0; i < claimTime.length; i++) {
            if (block.timestamp >= claimTime[i]) {
                claimableRate += claimRate[i];
            }
        }
        return ((totalPurchasedAmount * claimableRate) / ONE_HUNDRED_PERCENT) - totalClaimedAmount;
    }

    function verifyWhitelist(
        uint256 _nonce,
        uint8 _salePhase,
        address _candidate,
        uint256 _BUSDAmount,
        bytes memory _signature
    ) private view returns (bool) {
        require(msg.sender == _candidate, "POOL: WRONG CANDIDATE");
        return (Whitelist.verifySignature(_nonce, _salePhase, signer, _candidate, _BUSDAmount, _signature));
    }

    function getTaxAmount(uint256 _BUSDAmount) public pure returns (uint256) {
        return (_BUSDAmount * TAX) / ONE_HUNDRED_PERCENT;
    }

    function isClaimTimeValid(
        uint256[] memory _claimTime,
        uint256[] memory _claimRate,
        uint256 _endTime
    ) private pure returns (bool) {
        if (_claimTime.length == 0) return false;
        if (_claimTime.length != _claimRate.length) return false;
        // check if claim time is after end time
        if (_claimTime[0] < _endTime) return false;
        // check if claim time is in order
        for (uint256 i = 0; i < _claimTime.length - 1; i++) {
            if (_claimTime[i] >= _claimTime[i + 1]) return false;
        }
        // check if total claim rate is 100%
        uint256 totalClaimRate = 0;
        for (uint256 i = 0; i < _claimRate.length; i++) {
            totalClaimRate += _claimRate[i];
        }
        if (totalClaimRate != ONE_HUNDRED_PERCENT) return false;
        return true;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() private view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function getPriceFeedDecimals() private view returns (uint8) {
        return priceFeed.decimals();
    }

    /*---------- BUY FUNCTIONS -----------*/
    function buyTokenWithExactlyBUSD(
        uint8 _salePhase,
        address _candidate,
        uint256 _BUSDAmount,
        bytes memory _signature
    ) external inSalePhase whenNotPaused nonReentrant {
        require(_salePhase == currentSalePhase, "POOL: WRONG SALE PHASE");
        require(
            verifyWhitelist(nonces[_candidate], _salePhase, _candidate, _BUSDAmount, _signature),
            "POOL: NOT IN WHITELIST"
        );
        require(canBuyMoreToken(_candidate, _BUSDAmount), "POOL: CANNOT BUY MORE TOKEN");

        uint256 taxAmount = getTaxAmount(_BUSDAmount);
        require(BUSDToken.balanceOf(msg.sender) >= _BUSDAmount + taxAmount, "POOL: NOT ENOUGH BUSD");

        uint256 amountUserCanBuy = getTokenAmountFromBUSD(
            _BUSDAmount,
            salePhaseStatistics[currentSalePhase].preSaleTokenPrice
        );

        salePhaseStatistics[currentSalePhase].userPurchasedAmount[msg.sender] += amountUserCanBuy;
        salePhaseStatistics[currentSalePhase].totalSoldAmount += amountUserCanBuy;
        salePhaseStatistics[currentSalePhase].BUSDUserSpent[msg.sender] += _BUSDAmount;

        BUSDToken.safeTransferFrom(
            msg.sender,
            salePhaseStatistics[currentSalePhase].treasuryAddress,
            _BUSDAmount + taxAmount
        );
        nonces[_candidate]++;

        emit BuyTokenWithExactlyBUSD(msg.sender, _BUSDAmount);
    }

    function buyTokenWithExactlyBNB(
        uint8 _salePhase,
        address _candidate,
        bytes memory _signature
    ) external payable inSalePhase whenNotPaused nonReentrant {
        require(_salePhase == currentSalePhase, "POOL: WRONG SALE PHASE");
        uint256 BUSDAmount = convertBNBToBUSD(msg.value);
        require(
            verifyWhitelist(nonces[_candidate], _salePhase, _candidate, BUSDAmount, _signature),
            "POOL: NOT IN WHITELIST"
        );
        require(msg.value > 0, "POOL: INVALID BNB AMOUNT");

        require(canBuyMoreToken(_candidate, BUSDAmount), "POOL: CANNOT BUY MORE TOKEN");

        uint256 taxAmount = getTaxAmount(BUSDAmount);
        require(BUSDToken.balanceOf(msg.sender) >= taxAmount, "POOL: NOT ENOUGH BUSD");
        BUSDToken.safeTransferFrom(msg.sender, salePhaseStatistics[currentSalePhase].treasuryAddress, taxAmount);

        uint256 amountUserCanBuy = getTokenAmountFromBUSD(
            BUSDAmount,
            salePhaseStatistics[currentSalePhase].preSaleTokenPrice
        );

        salePhaseStatistics[currentSalePhase].userPurchasedAmount[msg.sender] += amountUserCanBuy;
        salePhaseStatistics[currentSalePhase].totalSoldAmount += amountUserCanBuy;
        salePhaseStatistics[currentSalePhase].BUSDUserSpent[msg.sender] += BUSDAmount;

        Address.sendValue(payable(salePhaseStatistics[currentSalePhase].treasuryAddress), msg.value);
        nonces[_candidate]++;

        emit BuyTokenWithExactlyBNB(msg.sender, msg.value);
    }

    function buyTokenWithoutFee(
        uint8 _salePhase,
        address _candidate,
        uint256 _numberOfCandidate,
        bytes memory _signature
    ) external inSalePhase whenNotPaused nonReentrant {
        require(salePhaseStatistics[currentSalePhase].preSaleTokenPrice == 0, "POOL: NOT IN FREE PHASE");
        require(_salePhase == currentSalePhase, "POOL: WRONG SALE PHASE");
        require(_numberOfCandidate > 0, "POOL: INVALID NUMBER OF CANDIDATE");
        require(
            verifyWhitelist(nonces[_candidate], _salePhase, _candidate, _numberOfCandidate, _signature),
            "POOL: NOT IN WHITELIST"
        );
        uint256 userPurchasedAmount = getUserClaimedAmount(msg.sender, _salePhase);
        uint256 maxTokenAmountUserCanBuy = salePhaseStatistics[currentSalePhase].maxPreSaleAmount / _numberOfCandidate;
        require(userPurchasedAmount <= maxTokenAmountUserCanBuy, "POOL: CANNOT BUY MORE TOKEN");

        salePhaseStatistics[currentSalePhase].userPurchasedAmount[msg.sender] += maxTokenAmountUserCanBuy;
        salePhaseStatistics[currentSalePhase].totalSoldAmount += maxTokenAmountUserCanBuy;
        nonces[_candidate]++;

        emit BuyTokenWithoutFee(msg.sender, maxTokenAmountUserCanBuy);
    }

    /*---------- CLAIM FUNCTIONS -----------*/
    function claimPurchasedToken(uint8 _salePhase) external whenNotPaused nonReentrant {
        uint256 claimableAmount = getClaimableAmount(msg.sender, _salePhase);
        require(claimableAmount > 0, "POOL: NOTHING TO CLAIM");
        salePhaseStatistics[_salePhase].userClaimedAmount[msg.sender] += claimableAmount;
        salePhaseStatistics[_salePhase].totalClaimedAmount += claimableAmount;

        preSaleToken.safeTransfer(msg.sender, claimableAmount);

        emit TokenClaimed(msg.sender, claimableAmount, _salePhase);
    }

    /*---------- WITHDRAW FUNCTIONS -----------*/
    function withdrawPresaleToken() external whenNotPaused nonReentrant onlySuperAdmin {
        preSaleToken.safeTransferFrom(address(this), msg.sender, preSaleToken.balanceOf(address(this)));
        emit WithdrawPresaleToken(preSaleToken.balanceOf(address(this)));
    }

    /*---------- GETTERS -----------*/
    function getUserPurchasedAmount(address _candidate, uint8 _salePhase) public view returns (uint256) {
        return salePhaseStatistics[_salePhase].userPurchasedAmount[_candidate];
    }

    function getUserClaimedAmount(address _candidate, uint8 _salePhase) public view returns (uint256) {
        return salePhaseStatistics[_salePhase].userClaimedAmount[_candidate];
    }

    function getUserTotalSpentBUSD(address _candidate, uint8 _salePhase) external view returns (uint256) {
        return salePhaseStatistics[_salePhase].BUSDUserSpent[_candidate];
    }

    function getRemainingClaimableAmount(address _candidate, uint8 _salePhase) external view returns (uint256) {
        return getUserPurchasedAmount(_candidate, _salePhase) - getUserClaimedAmount(_candidate, _salePhase);
    }

    function getClaimInfo(uint8 _salePhase) external view returns (uint256[] memory, uint256[] memory) {
        return (salePhaseStatistics[_salePhase].claimTime, salePhaseStatistics[_salePhase].claimRate);
    }
}