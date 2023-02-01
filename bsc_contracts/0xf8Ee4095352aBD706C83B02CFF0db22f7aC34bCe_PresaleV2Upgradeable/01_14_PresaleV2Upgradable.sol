//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface StakingContract {
    function StakeToAddress(address _address, uint _value) external;
}

abstract contract Referral is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint;

    /**
     * @dev Max referral level depth
     */
    uint8 internal MAX_REFER_DEPTH;

    /**
     * @dev Max referee amount to bonus rate depth
     */
    uint8 internal MAX_REFEREE_BONUS_LEVEL;

    /**
     * @dev The struct of account information
     * @param referrer The referrer addresss
     * @param reward The total referral reward of an address
     * @param referredCount The total referral amount of an address
     * @param lastActiveTimestamp The last active timestamp of an address
     */
    struct Account {
        address payable referrer;
        uint reward;
        uint referredCount;
        uint lastActiveTimestamp;
        address[] referee;
        uint totalBusiness;
    }

    /**
     * @dev The struct of referee amount to bonus rate
     * @param lowerBound The minial referee amount
     * @param rate The bonus rate for each referee amount
     */
    struct RefereeBonusRate {
        uint lowerBound;
        uint rate;
    }

    event RegisteredReferer(address referee, address referrer);

    event RegisterRefererFailed(
        address referee,
        address referrer,
        string reason
    );
    event PaidReferral(
        address from,
        address to,
        uint amount,
        uint level,
        string currency
    );

    event UpdatedUserLastActiveTime(address user, uint timestamp);

    mapping(address => Account) internal accounts;

    uint internal TotalFundRaised;
    uint internal TotalRewardDistributed;

    uint256[] internal levelRate;
    uint256 internal referralBonus;
    uint256 internal LevelDecimals;
    uint256 internal secondsUntilInactive;
    bool internal onlyRewardActiveReferrers;
    address payable internal defaultReferrer;
    RefereeBonusRate[] internal refereeBonusRateMap;
}

interface IERC20_EXTENDED {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint);
}

contract PresaleV2Upgradeable is
    Referral,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    string private TokenName;
    uint256 private TokenDecimals;
    uint256 private TokenTotalSupply;
    address private TokenContractAddress;
    address private TokenOwnerAddress;
    address private StakingContractAddress;
    uint256 private PricePerUSDT;
    uint256 private MinContributionInUSDT;
    uint256 private totalTokenSold;
    bool private isBuyAndStake;

    uint256[] private levelRateNew;
    uint256[] private levelMapNew;

    AggregatorV3Interface private priceFeed;
    address private priceFeedOracleAddress;

    address private USDContract;
    address private BUSDContract;

    bool private isPayReferral;

    uint256 private USDTRaised;
    uint256 private BUSDRaised;
    uint256 private RewardDistributedUSDT;
    uint256 private RewardDistributedBUSD;

    struct AccountExtended {
        uint256 totalBusinessUSDT;
        uint256 totalBusinessBUSD;
        uint256 totalIncomeUSDT;
        uint256 totalIncomeBUSD;
        uint256[] blockNumber;
    }

    mapping(address => AccountExtended) private accountsExtended;

    event TokenPurchased(
        address indexed from,
        uint256 indexed tokenValue,
        uint256 indexed ethValue,
        string currency
    );

    // function initialize() public initializer {
    //     //BSC Mainnet

    //     // priceFeedOracleAddress = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    //     // TokenContractAddress = 0x534743c5Ed9E11a95bE72C8190ae627067cc33b7;
    //     // TokenOwnerAddress = 0x49827482BdeB954EF760D6e25e7Bee0b9a422994;
    //     // StakingContractAddress = 0x7f3955EC4A3AA6845ae60f6b733dca146a268aBB;

    //     // BSC Testnet

    //     priceFeedOracleAddress = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    //     TokenContractAddress = 0x0F0EC170DEAF700CAf78aA12806A22E3c8f7621a;
    //     TokenOwnerAddress = 0x7a0DeC713157f4289E112f5B8785C4Ae8B298F7F;
    //     StakingContractAddress = 0xD021F0c34C02Ec2Bf6D80905c23bafad0482d1ea;
    //     USDContract = 0xbfA0e2F4b2676c62885B1033670C71cdefd975fB;

    //     isBuyAndStake = true;
    //     PricePerUSDT = 1000000000000000000;
    //     MinContributionInUSDT = 1;

    //     levelRateNew = [30, 20, 10, 7, 5, 3, 4, 5, 7, 9];
    //     levelMapNew = [1, 100];

    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    //     __Pausable_init();
    // }

    function getLevelRates()
        external
        view
        returns (uint256[] memory levelRates, uint256 levelDecimals)
    {
        levelRates = levelRate;
        levelDecimals = LevelDecimals;
    }

    //setLevelRates

    function setLevelRate(
        uint256[] calldata _value1000BasePoints,
        uint256 _levelDecimals
    ) external onlyOwner returns (bool) {
        levelRate = _value1000BasePoints;
        LevelDecimals = _levelDecimals;
        return true;
    }

    //getTotalReferralRate

    function getTotalReferralBonus() external view returns (uint256) {
        uint8 levelLength = uint8(levelRate.length);
        uint8 totalReferralBonus;

        for (uint8 i; i < levelLength; i++) {
            totalReferralBonus += uint8(levelRate[i]);
        }
        return totalReferralBonus;
    }

    //getDefaultReferrer

    function getDefaultReferrer() external view returns (address) {
        return defaultReferrer;
    }

    //setDefaultReferrer

    function setDefaultReferrer(
        address _address
    ) external onlyOwner returns (bool) {
        defaultReferrer = payable(_address);
        return defaultReferrer == payable(_address) ? true : false;
    }

    //totalTokenSold

    function getTotalTokenSold() external view returns (uint256) {
        return totalTokenSold;
    }

    //totalFundRaised

    function getTotalFundRaised()
        external
        view
        returns (uint256 ethRaised, uint256 usdtRaised, uint256 busdRaised)
    {
        ethRaised = TotalFundRaised;
        usdtRaised = USDTRaised;
        busdRaised = BUSDRaised;
    }

    //totalRewardDistributed

    function getTotalRewardDistributed()
        external
        view
        returns (
            uint256 ethDistributed,
            uint256 usdtDistributed,
            uint256 busdDistributed
        )
    {
        ethDistributed = TotalRewardDistributed;
        usdtDistributed = RewardDistributedUSDT;
        busdDistributed = RewardDistributedBUSD;
    }

    //AccountMap

    function getAccountMap(
        address _address
    )
        external
        view
        returns (
            Account memory accountsMap,
            AccountExtended memory accountsMapExtended
        )
    {
        accountsMap = accounts[_address];
        accountsMapExtended = accountsExtended[_address];
    }

    //getUserRefereeAddress

    function getUserReferees(
        address _address
    )
        external
        view
        returns (address[] memory userRefereeAddress, uint256 refereeCount)
    {
        Account storage userAccount = accounts[_address];
        userRefereeAddress = userAccount.referee;
        refereeCount = userAccount.referee.length;
    }

    //getUserTotalBusiness

    function getUserTotalBusiness(
        address _address
    )
        external
        view
        returns (
            uint256 businessETH,
            uint256 businessUSDT,
            uint256 businessBUSD
        )
    {
        Account storage userAccount = accounts[_address];
        AccountExtended storage userAccountExt = accountsExtended[_address];

        businessETH = userAccount.totalBusiness;
        businessUSDT = userAccountExt.totalBusinessUSDT;
        businessBUSD = userAccountExt.totalBusinessBUSD;
    }

    //getUserTotalIncome

    function getUserTotalIncome(
        address _address
    )
        external
        view
        returns (uint256 incomeETH, uint256 incomeUSDT, uint256 incomeBUSD)
    {
        Account storage userAccount = accounts[_address];
        AccountExtended storage userAccountExt = accountsExtended[_address];
        incomeETH = userAccount.reward;
        incomeUSDT = userAccountExt.totalIncomeUSDT;
        incomeBUSD = userAccountExt.totalIncomeBUSD;
    }

    //hasReferrer

    function _hasReferrer(address _address) private view returns (bool) {
        Account storage userAccount = accounts[_address];
        return userAccount.referrer != address(0);
    }

    function hasReferrer(
        address _address
    ) external view returns (bool isValidUpline, address uplineAddress) {
        Account storage userAccount = accounts[_address];
        isValidUpline = _hasReferrer(_address);
        uplineAddress = userAccount.referrer;
    }

    //isCircularReference

    function _isCircularReference(
        address _referrer,
        address _referee
    ) private view returns (bool) {
        require(_referrer != address(0), "Address cannot be 0x0.");
        address parent = _referrer;

        for (uint256 i; i < levelRate.length; i++) {
            if (parent == _referee) {
                return true;
            }
            parent = accounts[parent].referrer;
        }

        return false;
    }

    //addReferrer

    function _addReferrer(
        address _address,
        address _referrer
    ) private returns (bool) {
        if (_isCircularReference(_referrer, _address)) {
            emit RegisterRefererFailed(
                _address,
                _referrer,
                "Referee cannot be one of referrer uplines."
            );
            return false;
        } else if (accounts[_address].referrer != address(0)) {
            emit RegisterRefererFailed(
                _address,
                _referrer,
                "Address already have referrer."
            );
            return false;
        }

        Account storage userAccount = accounts[_address];
        Account storage referrerAccount = accounts[_referrer];
        userAccount.referrer = payable(_referrer);
        referrerAccount.referee.push(_address);
        emit RegisteredReferer(_referrer, _address);

        for (uint256 i; i < levelRate.length; i++) {
            Account storage referrerParentAddress = accounts[
                referrerAccount.referrer
            ];

            if (referrerAccount.referrer == address(0)) {
                break;
            }

            referrerAccount = referrerParentAddress;
        }
        return true;
    }

    function addReferrerAdmin(
        address _referee,
        address _referer
    ) external onlyOwner {
        _addReferrer(_referee, _referer);
    }

    //payReferralETH

    function _payReferralInETH(uint256 value, address _referee) private {
        Account memory userAccount = accounts[_referee];
        uint256 totalReferal;

        for (uint256 i; i < levelRate.length; i++) {
            address payable referrer = userAccount.referrer;
            Account storage referrerAccount = accounts[referrer];
            AccountExtended storage referrerAccountExt = accountsExtended[
                referrer
            ];

            if (referrer == address(0)) {
                break;
            }

            uint256 c = value.mul(levelRate[i]).div(LevelDecimals);
            referrerAccount.totalBusiness += value;
            referrerAccount.reward += c;
            totalReferal += c;

            referrer.transfer(c);

            emit PaidReferral(_referee, referrer, c, i + 1, "ETH");

            referrerAccountExt.blockNumber.push(block.number);

            userAccount = referrerAccount;
        }

        TotalRewardDistributed += totalReferal;
    }

    //payReferralUSDT

    function _payReferralInUSD(uint256 value, address _referee) private {
        Account memory userAccount = accounts[_referee];
        uint256 totalReferal;

        for (uint256 i; i < levelRate.length; i++) {
            address payable referrer = userAccount.referrer;
            Account storage referrerAccount = accounts[referrer];
            AccountExtended storage referrerAccountExt = accountsExtended[
                referrer
            ];

            if (referrer == address(0)) {
                break;
            }

            uint256 c = value.mul(levelRate[i]).div(LevelDecimals);

            referrerAccountExt.totalBusinessUSDT += value;
            referrerAccountExt.totalIncomeUSDT += c;
            totalReferal += c;

            _transferTokensFrom(TokenOwnerAddress, referrer, c, USDContract);

            emit PaidReferral(_referee, referrer, c, i + 1, "USDT");
            referrerAccountExt.blockNumber.push(block.number);
            userAccount = referrerAccount;
        }

        RewardDistributedUSDT += totalReferal;
    }

    //payReferralBUSD

    function _payReferralInBUSD(uint256 value, address _referee) private {
        Account memory userAccount = accounts[_referee];
        uint256 totalReferal;

        for (uint256 i; i < levelRate.length; i++) {
            address payable referrer = userAccount.referrer;
            Account storage referrerAccount = accounts[referrer];
            AccountExtended storage referrerAccountExt = accountsExtended[
                referrer
            ];

            if (referrer == address(0)) {
                break;
            }

            uint256 c = value.mul(levelRate[i]).div(LevelDecimals);

            referrerAccountExt.totalBusinessBUSD += value;
            referrerAccountExt.totalIncomeBUSD += c;
            totalReferal += c;

            _transferTokensFrom(TokenOwnerAddress, referrer, c, BUSDContract);

            emit PaidReferral(_referee, referrer, c, i + 1, "BUSD");
            referrerAccountExt.blockNumber.push(block.number);
            userAccount = referrerAccount;
        }

        RewardDistributedBUSD += totalReferal;
    }

    //Presale Functions

    //getETHPrice
    function getETH_USDPrice() public view returns (uint256 ETH_USD) {
        (, int ethPrice, , , ) = AggregatorV3Interface(priceFeedOracleAddress)
            .latestRoundData();
        ETH_USD = uint256(ethPrice) * (10 ** 10);
    }

    //getMinContributionETH
    function _getMinContributionETH()
        private
        view
        returns (uint256 minETHRequired)
    {
        if (MinContributionInUSDT == 0) {
            minETHRequired = 0;
        } else {
            uint256 ethPrice = getETH_USDPrice();
            uint256 ratio = ethPrice / MinContributionInUSDT;
            minETHRequired =
                (1 * 10 ** _getTokenDecimals(TokenContractAddress)) /
                ratio;
        }
    }

    function getMinContributionETH() external view returns (uint256) {
        return _getMinContributionETH();
    }

    //getTokensValueETH

    function _getTokensValueETH(
        uint256 _ethValue,
        uint256 _price
    ) private view returns (uint256 tokenValue) {
        uint256 ethPrice = getETH_USDPrice();
        uint256 ethValue = (_ethValue * ethPrice) /
            (10 ** _getTokenDecimals(TokenContractAddress));
        tokenValue =
            (ethValue * _price) /
            (10 ** _getTokenDecimals(TokenContractAddress));
    }

    function _transferTokens(
        address _receiver,
        uint256 _tokenValue,
        address _tokenContract
    ) private {
        IERC20Upgradeable(_tokenContract).transfer(_receiver, _tokenValue);
    }

    function _transferTokensFrom(
        address _spender,
        address _receiver,
        uint256 _tokenValue,
        address _tokenContract
    ) private {
        IERC20Upgradeable(_tokenContract).transferFrom(
            _spender,
            _receiver,
            _tokenValue
        );
    }

    //getTokensValueUSD

    function _getTokensValueUSD(
        uint256 _USDValue,
        uint256 _price,
        address _usdContract
    ) private view returns (uint256 tokenValue) {
        tokenValue =
            (_USDValue * _price) /
            10 ** _getTokenDecimals(_usdContract);
    }

    function BuyWithETH(address _referrer) external payable whenNotPaused {
        address _msgSender = msg.sender;
        uint256 _msgValue = msg.value;
        uint256 _tokenValue = _getTokensValueETH(_msgValue, PricePerUSDT);

        require(
            _msgValue >= _getMinContributionETH(),
            "ETH value less then min buy value."
        );

        if (!_hasReferrer(_msgSender) && _referrer != address(0)) {
            _addReferrer(_msgSender, _referrer);
        }

        if (isBuyAndStake == true) {
            _transferTokensFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                _tokenValue,
                TokenContractAddress
            );
            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                _tokenValue
            );
        } else {
            _transferTokensFrom(
                TokenOwnerAddress,
                _msgSender,
                _tokenValue,
                TokenContractAddress
            );
        }

        if (isPayReferral) {
            _payReferralInETH(_msgValue, _msgSender);
        }

        payable(TokenOwnerAddress).transfer(address(this).balance);

        totalTokenSold += _tokenValue;
        TotalFundRaised += _msgValue;
        emit TokenPurchased(_msgSender, _tokenValue, _msgValue, "ETH");
    }

    function BuyWithUSDT(
        address _referrer,
        uint256 _msgValueInWei
    ) external whenNotPaused {
        require(
            _msgValueInWei >=
                MinContributionInUSDT * 10 ** _getTokenDecimals(USDContract),
            "USDTs value less then min buy value."
        );

        address _msgSender = msg.sender;
        uint256 _msgValue = _msgValueInWei;
        uint256 _tokenValue = _getTokensValueUSD(
            _msgValue,
            PricePerUSDT,
            USDContract
        );

        if (!_hasReferrer(_msgSender) && _referrer != address(0)) {
            _addReferrer(_msgSender, _referrer);
        }

        _transferTokensFrom(
            _msgSender,
            TokenOwnerAddress,
            _msgValue,
            USDContract
        );

        if (isBuyAndStake == true) {
            _transferTokensFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                _tokenValue,
                TokenContractAddress
            );
            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                _tokenValue
            );
        } else {
            _transferTokensFrom(
                TokenOwnerAddress,
                _msgSender,
                _tokenValue,
                TokenContractAddress
            );
        }

        if (isPayReferral) {
            _payReferralInUSD(_msgValue, _msgSender);
        }

        totalTokenSold += _tokenValue;
        USDTRaised += _msgValue;
        emit TokenPurchased(_msgSender, _tokenValue, _msgValue, "USDT");
    }

    function BuyWithBUSD(
        address _referrer,
        uint256 _msgValueInWei
    ) external whenNotPaused {
        require(
            _msgValueInWei >=
                MinContributionInUSDT * 10 ** _getTokenDecimals(BUSDContract),
            "USDTs value less then min buy value."
        );
        address _msgSender = msg.sender;
        uint256 _msgValue = _msgValueInWei;
        uint256 _tokenValue = _getTokensValueUSD(
            _msgValue,
            PricePerUSDT,
            BUSDContract
        );

        if (!_hasReferrer(_msgSender) && _referrer != address(0)) {
            _addReferrer(_msgSender, _referrer);
        }

        _transferTokensFrom(
            _msgSender,
            TokenOwnerAddress,
            _msgValue,
            BUSDContract
        );

        if (isBuyAndStake == true) {
            _transferTokensFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                _tokenValue,
                TokenContractAddress
            );
            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                _tokenValue
            );
        } else {
            _transferTokensFrom(
                TokenOwnerAddress,
                _msgSender,
                _tokenValue,
                TokenContractAddress
            );
        }

        if (isPayReferral) {
            _payReferralInBUSD(_msgValue, _msgSender);
        }

        totalTokenSold += _tokenValue;
        BUSDRaised += _msgValue;
        emit TokenPurchased(_msgSender, _tokenValue, _msgValue, "BUSD");
    }

    //getContractAddress

    function getContractAddress()
        external
        view
        returns (
            address tokenContract,
            address presaleContract,
            address stakingContract,
            address usdtContract,
            address busdContract
        )
    {
        tokenContract = TokenContractAddress;
        presaleContract = address(this);
        stakingContract = StakingContractAddress;
        usdtContract = USDContract;
        busdContract = BUSDContract;
    }

    //getTokenContractInfo
    function getTokenContractInfo()
        external
        view
        returns (
            address contractAddress,
            address tokenOwner,
            string memory name,
            string memory symbol,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = TokenContractAddress;
        tokenOwner = TokenOwnerAddress;
        name = IERC20_EXTENDED(TokenContractAddress).name();
        symbol = IERC20_EXTENDED(TokenContractAddress).symbol();
        decimals = IERC20_EXTENDED(TokenContractAddress).decimals();
        totalSupply = IERC20Upgradeable(TokenContractAddress).totalSupply();
    }

    //getUSDTContractInfo

    function getUSDTContractInfo()
        external
        view
        returns (
            address contractAddress,
            string memory name,
            string memory symbol,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = USDContract;
        name = IERC20_EXTENDED(USDContract).name();
        symbol = IERC20_EXTENDED(USDContract).symbol();
        decimals = IERC20_EXTENDED(USDContract).decimals();
        totalSupply = IERC20Upgradeable(USDContract).totalSupply();
    }

    //getBUSDContractInfo

    function getBUSDContractInfo()
        external
        view
        returns (
            address contractAddress,
            string memory name,
            string memory symbol,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = BUSDContract;
        name = IERC20_EXTENDED(BUSDContract).name();
        symbol = IERC20_EXTENDED(BUSDContract).symbol();
        decimals = IERC20_EXTENDED(BUSDContract).decimals();
        totalSupply = IERC20Upgradeable(BUSDContract).totalSupply();
    }

    function setContractToken(
        address _tokenContractAddress
    ) external onlyOwner returns (address) {
        TokenContractAddress = _tokenContractAddress;
        return TokenContractAddress;
    }

    function setContractStaking(
        address _stakingContractAddress
    ) external onlyOwner returns (address) {
        StakingContractAddress = _stakingContractAddress;
        return StakingContractAddress;
    }

    function setContractUSDT(
        address _usdtContractAddress
    ) external onlyOwner returns (address) {
        USDContract = _usdtContractAddress;
        return USDContract;
    }

    function setContractBUSD(
        address _busdContractAddress
    ) external onlyOwner returns (address) {
        BUSDContract = _busdContractAddress;
        return BUSDContract;
    }

    function getPricePerUSD() external view returns (uint256) {
        return PricePerUSDT;
    }

    function setPricePerUSD(
        uint256 _priceInWei
    ) external onlyOwner returns (uint256) {
        PricePerUSDT = _priceInWei;
        return PricePerUSDT;
    }

    function getMinContributionUSD() external view returns (uint256) {
        return MinContributionInUSDT;
    }

    function setMinContributionUSD(
        uint256 _valueInWholeNumber
    ) external onlyOwner returns (uint256) {
        MinContributionInUSDT = _valueInWholeNumber;
        return MinContributionInUSDT;
    }

    function isBuyAnStakeEnable() external view returns (bool) {
        return isBuyAndStake;
    }

    function setIsBuyAndStake(
        bool _trueOrFalse
    ) external onlyOwner returns (bool) {
        isBuyAndStake = _trueOrFalse;
        return isBuyAndStake;
    }

    function getIsPayReferral() external view returns (bool) {
        return isPayReferral;
    }

    function setIsPayReferral(
        bool _trueOrFalse
    ) external onlyOwner returns (bool) {
        isPayReferral = _trueOrFalse;
        return isPayReferral;
    }

    function _getTokenDecimals(
        address _tokenAddress
    ) private view returns (uint256) {
        return IERC20_EXTENDED(_tokenAddress).decimals();
    }

    function getTokenOwnerAddress() external view returns (address) {
        return TokenOwnerAddress;
    }

    function setTokenOwnerAddress(
        address _address
    ) external onlyOwner returns (address) {
        TokenOwnerAddress = _address;
        return TokenOwnerAddress;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function sendNativeFundsAdmin(
        address _address,
        uint256 _value
    ) external onlyOwner {
        payable(_address).transfer(_value);
    }

    function withdrawAdmin() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokenAdmin(
        address _tokenAddress,
        uint256 _value
    ) external onlyOwner {
        _transferTokens(msg.sender, _value, _tokenAddress);
    }
}