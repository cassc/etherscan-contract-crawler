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

    event RegisteredRefererFailed(
        address referee,
        address referrer,
        string reason
    );
    event PaidReferral(address from, address to, uint amount, uint level);

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

    function TotalFundRaisedAdmin() external view returns (uint) {
        return TotalFundRaised;
    }

    function TotalRewardDistributedAdmin() external view returns (uint) {
        return TotalRewardDistributed;
    }

    function GetMaxLevelDepth() external view returns (uint8) {
        return MAX_REFER_DEPTH;
    }

    function GetMaxLevelBonusLevel() external view returns (uint8) {
        return MAX_REFEREE_BONUS_LEVEL;
    }

    function SetMaxLevelDepthBonus(uint8 _value) external {
        MAX_REFER_DEPTH = _value;
        MAX_REFEREE_BONUS_LEVEL = _value;
    }

    function GetLevelDecimals() external view returns (uint256) {
        return LevelDecimals;
    }

    function SetLevelDecimals(uint256 _value) external onlyOwner {
        LevelDecimals = _value;
    }

    function LevelRefferalBonus() external view returns (uint256) {
        return referralBonus;
    }

    function GetDefaultReferrer() public view returns (address) {
        return defaultReferrer;
    }

    // function SetDefaultReferrer(address payable _address) public onlyOwner {
    //     defaultReferrer = _address;
    // }

    function SetLevelRefferalBonus(uint256 _value) external onlyOwner {
        referralBonus = _value;
    }

    function SecondsUntilInactive() external view returns (uint256) {
        return secondsUntilInactive;
    }

    function SetSecondsUntilInactive(uint256 _value) external onlyOwner {
        secondsUntilInactive = _value;
    }

    function OnlyRewardActiveReferrers() external view returns (bool) {
        return onlyRewardActiveReferrers;
    }

    function SetOnlyRewardActiveReferrers(bool _value) external onlyOwner {
        onlyRewardActiveReferrers = _value;
    }

    function LevelRate() external view returns (uint256[] memory) {
        return levelRate;
    }

    function SetLevelRate(uint256[] calldata _value) external onlyOwner {
        levelRate = _value;
    }

    function RefereeBonusRateMap()
        external
        view
        returns (RefereeBonusRate[] memory)
    {
        return refereeBonusRateMap;
    }

    function SetRefereeBonusRateMap(
        uint256[] memory _refereeBonusRateMap
    ) external onlyOwner {
        if (_refereeBonusRateMap.length == 0) {
            refereeBonusRateMap.push(RefereeBonusRate(1, LevelDecimals));
            return;
        }

        for (uint i; i < _refereeBonusRateMap.length; i += 2) {
            if (_refereeBonusRateMap[i + 1] > LevelDecimals) {
                revert("One of referee bonus rate exceeds 100%");
            }
            // Cause we can't pass struct or nested array without enabling experimental ABIEncoderV2, use array to simulate it
            refereeBonusRateMap.push(
                RefereeBonusRate(
                    _refereeBonusRateMap[i],
                    _refereeBonusRateMap[i + 1]
                )
            );
        }
    }

    /**
     * @param _LevelDecimals The base LevelDecimals for float calc, for example 1000
     * @param _referralBonus The total referral bonus rate, which will divide by LevelDecimals. For example, If you will like to set as 5%, it can set as 50 when LevelDecimals is 1000.
     * @param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
     * @param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
     * @param _levelRate The bonus rate for each level, which will divide by LevelDecimals too. The max depth is MAX_REFER_DEPTH.
     * @param _refereeBonusRateMap The bonus rate mapping to each referree amount, which will divide by LevelDecimals too. The max depth is MAX_REFER_DEPTH.
     * The map should be pass as [<lower amount>, <rate>, ....]. For example, you should pass [1, 250, 5, 500, 10, 1000] when LevelDecimals is 1000 for the following case.
     *
     *  25%     50%     100%
     *   | ----- | ----- |----->
     *  1ppl    5ppl    10ppl
     *
     * @notice refereeBonusRateMap's lower amount should be ascending
     */
    function Referral_init(
        uint8 _MAX_REFER_DEPTH,
        uint8 _MAX_REFEREE_BONUS_LEVEL,
        uint _LevelDecimals,
        uint _referralBonus,
        uint _secondsUntilInactive,
        bool _onlyRewardActiveReferrers,
        uint256[] memory _levelRate,
        uint256[] memory _refereeBonusRateMap,
        address payable _defaultReferrer
    ) internal onlyInitializing {
        MAX_REFER_DEPTH = _MAX_REFER_DEPTH;
        MAX_REFEREE_BONUS_LEVEL = _MAX_REFEREE_BONUS_LEVEL;
        defaultReferrer = _defaultReferrer;

        require(_levelRate.length > 0, "Referral level should be at least one");
        require(
            _levelRate.length <= MAX_REFER_DEPTH,
            "Exceeded max referral level depth"
        );
        require(
            _refereeBonusRateMap.length % 2 == 0,
            "Referee Bonus Rate Map should be pass as [<lower amount>, <rate>, ....]"
        );
        require(
            _refereeBonusRateMap.length / 2 <= MAX_REFEREE_BONUS_LEVEL,
            "Exceeded max referree bonus level depth"
        );
        require(
            _referralBonus <= _LevelDecimals,
            "Referral bonus exceeds 100%"
        );
        require(
            sum(_levelRate) <= _LevelDecimals,
            "Total level rate exceeds 100%"
        );

        LevelDecimals = _LevelDecimals;
        referralBonus = _referralBonus;
        secondsUntilInactive = _secondsUntilInactive;
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
        levelRate = _levelRate;

        // Set default referee amount rate as 1ppl -> 100% if rate map is empty.
        if (_refereeBonusRateMap.length == 0) {
            refereeBonusRateMap.push(RefereeBonusRate(1, LevelDecimals));
            return;
        }

        for (uint i; i < _refereeBonusRateMap.length; i += 2) {
            if (_refereeBonusRateMap[i + 1] > LevelDecimals) {
                revert("One of referee bonus rate exceeds 100%");
            }
            // Cause we can't pass struct or nested array without enabling experimental ABIEncoderV2, use array to simulate it
            refereeBonusRateMap.push(
                RefereeBonusRate(
                    _refereeBonusRateMap[i],
                    _refereeBonusRateMap[i + 1]
                )
            );
        }
    }

    function sum(uint[] memory data) internal pure returns (uint) {
        uint S;
        for (uint i; i < data.length; i++) {
            S += data[i];
        }
        return S;
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function hasReferrer(address addr) public view returns (bool) {
        return accounts[addr].referrer != address(0);
    }

    function referees(address addr) external view returns (address[] memory) {
        return accounts[addr].referee;
    }

    function totalReward(address addr) external view returns (uint) {
        return accounts[addr].reward;
    }

    function totalBusiness(address addr) public view returns (uint) {
        return accounts[addr].totalBusiness;
    }

    function uplineAddress(address addr) external view returns (address) {
        return accounts[addr].referrer;
    }

    function referCount(address addr) external view returns (uint) {
        return accounts[addr].referredCount;
    }

    function AccountMap(address addr) external view returns (Account memory) {
        return accounts[addr];
    }

    /**
     * @dev Get block timestamp with function for testing mock
     */
    function getTime() public view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
     * @dev Given a user amount to calc in which rate period
     * @param amount The number of referrees
     */
    function getRefereeBonusRate(uint256 amount) public view returns (uint256) {
        uint rate = refereeBonusRateMap[0].rate;
        for (uint i = 1; i < refereeBonusRateMap.length; i++) {
            if (amount < refereeBonusRateMap[i].lowerBound) {
                break;
            }
            rate = refereeBonusRateMap[i].rate;
        }
        return rate;
    }

    function isCircularReference(
        address referrer,
        address referee
    ) internal view returns (bool) {
        address parent = referrer;

        for (uint i; i < levelRate.length; i++) {
            if (parent == address(0)) {
                break;
            }

            if (parent == referee) {
                return true;
            }

            parent = accounts[parent].referrer;
        }

        return false;
    }

    /**
     * @dev Add an address as referrer
     * @param referrer The address would set as referrer of msg.sender
     * @return whether success to add upline
     */
    function addReferrer(
        address _referee,
        address payable referrer
    ) internal returns (bool) {
        if (referrer == address(0)) {
            emit RegisteredRefererFailed(
                _referee,
                referrer,
                "Referrer cannot be 0x0 address"
            );
            return false;
        } else if (isCircularReference(referrer, _referee)) {
            emit RegisteredRefererFailed(
                _referee,
                referrer,
                "Referee cannot be one of referrer uplines"
            );
            return false;
        } else if (accounts[_referee].referrer != address(0)) {
            emit RegisteredRefererFailed(
                _referee,
                referrer,
                "Address have been registered upline"
            );
            return false;
        }

        Account storage userAccount = accounts[_referee];
        Account storage parentAccount = accounts[referrer];

        userAccount.referrer = referrer;
        userAccount.lastActiveTimestamp = getTime();
        parentAccount.referredCount = parentAccount.referredCount.add(1);
        parentAccount.referee.push(_referee);

        emit RegisteredReferer(_referee, referrer);
        return true;
    }

    /**
     * @dev Developers should define what kind of actions are seens active. By default, payReferral will active msg.sender.
     * @param user The address would like to update active time
     */
    function updateActiveTimestamp(address user) internal {
        uint timestamp = getTime();
        accounts[user].lastActiveTimestamp = timestamp;
        emit UpdatedUserLastActiveTime(user, timestamp);
    }

    function setSecondsUntilInactive(
        uint _secondsUntilInactive
    ) public onlyOwner {
        secondsUntilInactive = _secondsUntilInactive;
    }

    function setOnlyRewardAActiveReferrers(
        bool _onlyRewardActiveReferrers
    ) public onlyOwner {
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
    }
}

interface IERC20_EXTENDED {
    function name() external view returns (string memory);

    function decimals() external view returns (uint);
}

contract PresaleUpgradable is Referral, UUPSUpgradeable, PausableUpgradeable {
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

    receive() external payable {
        BuyWithBNB(payable(GetDefaultReferrer()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function initialize() public initializer {
        //BSC Mainnet

        // priceFeedOracleAddress = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        // TokenContractAddress = 0x534743c5Ed9E11a95bE72C8190ae627067cc33b7;
        // TokenOwnerAddress = 0x49827482BdeB954EF760D6e25e7Bee0b9a422994;
        // StakingContractAddress = 0x7f3955EC4A3AA6845ae60f6b733dca146a268aBB;

        // BSC Testnet

        priceFeedOracleAddress = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        TokenContractAddress = 0x0F0EC170DEAF700CAf78aA12806A22E3c8f7621a;
        TokenOwnerAddress = 0x7a0DeC713157f4289E112f5B8785C4Ae8B298F7F;
        StakingContractAddress = 0xD021F0c34C02Ec2Bf6D80905c23bafad0482d1ea;
        USDContract = 0xbfA0e2F4b2676c62885B1033670C71cdefd975fB;

        isBuyAndStake = true;
        PricePerUSDT = 1000000000000000000;
        MinContributionInUSDT = 1;

        levelRateNew = [30, 20, 10, 7, 5, 3, 4, 5, 7, 9];
        levelMapNew = [1, 100];

        Referral_init(
            10,
            10,
            100,
            5,
            0,
            false,
            levelRateNew,
            levelMapNew,
            payable(0xc7538C9d4afA40d9A888e89381B53e791E4F7721)
        );

        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function GetBNB_USDPrice() public view returns (uint256 BNB_USD) {
        (
            ,
            /*uint80 roundID*/
            int BnbPrice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = AggregatorV3Interface(priceFeedOracleAddress).latestRoundData();
        BNB_USD = uint256(BnbPrice) * (10 ** 10);
    }

    function MinContributionInBNB()
        public
        view
        returns (uint256 minBNBRequired)
    {
        uint256 bnbPrice = GetBNB_USDPrice();
        uint256 ratio = bnbPrice / MinContributionInUSDT;
        minBNBRequired =
            ((1 * 10 ** _getTokenDecimals(TokenContractAddress)) *
                (10 ** _getTokenDecimals(TokenContractAddress))) /
            ratio;
    }

    function _getTokensValueETH(
        uint256 _ethValue,
        uint256 _price
    ) private view returns (uint256 tokenValue) {
        uint256 ethPrice = GetBNB_USDPrice();
        uint256 ethValue = (_ethValue * ethPrice) /
            (10 ** _getTokenDecimals(TokenContractAddress));
        tokenValue = ethValue * _price;
        tokenValue =
            tokenValue /
            (10 ** _getTokenDecimals(TokenContractAddress));
    }

    function _getTokensValueUSD(
        uint256 _USDValue,
        uint256 _price,
        address _USDContractAddress
    ) private view returns (uint256 tokenValue) {
        tokenValue =
            (_USDValue * _price) /
            10 ** _getTokenDecimals(_USDContractAddress);
    }

    function getTokenValueUSD(
        uint256 _USDValue,
        address _USDContractAddress
    ) external view returns (uint256) {
        return
            (_USDValue * PricePerUSDT) /
            10 ** _getTokenDecimals(_USDContractAddress);
    }

    function payReferral(uint256 value, address _referee) private {
        Account memory userAccount = accounts[_referee];
        uint totalReferal;

        for (uint i; i < levelRate.length; i++) {
            address payable parent = userAccount.referrer;
            Account storage parentAccount = accounts[userAccount.referrer];

            if (parent == address(0)) {
                break;
            }
            uint256 c = value.mul(referralBonus).div(LevelDecimals);
            c = c.mul(levelRate[i]).div(LevelDecimals);

            totalReferal = totalReferal.add(c);

            parentAccount.reward = parentAccount.reward.add(c);
            parentAccount.totalBusiness += value;
            parent.transfer(c);
            emit PaidReferral(_referee, parent, c, i + 1);

            userAccount = parentAccount;
        }

        TotalFundRaised += value;
        TotalRewardDistributed += totalReferal;
    }

    function BuyWithBNB(
        address payable _referrer
    ) public payable whenNotPaused {
        uint256 _msgValue = msg.value;
        address _msgSender = msg.sender;

        require(
            _msgValue >= MinContributionInBNB(),
            "You need atleast $100 value of BNB"
        );

        if (!hasReferrer(_msgSender) && (_referrer != address(0))) {
            addReferrer(_msgSender, _referrer);
        }

        if (!hasReferrer(_referrer) && (_referrer != address(0))) {
            addReferrer(_referrer, defaultReferrer);
        }

        uint256 tokenValue = _getTokensValueETH(_msgValue, PricePerUSDT);

        if (isBuyAndStake == true) {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                tokenValue
            );

            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                tokenValue
            );
        } else {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                _msgSender,
                tokenValue
            );
        }

        if (hasReferrer(_msgSender)) {
            payReferral(_msgValue, _msgSender);
        }

        payable(TokenOwnerAddress).transfer(address(this).balance);

        totalTokenSold = totalTokenSold + tokenValue;
    }

    function _payReferralInUSD(
        uint256 value,
        address _referee,
        address contractAddress
    ) private {
        Account memory userAccount = accounts[_referee];
        uint totalReferal;

        for (uint i; i < levelRate.length; i++) {
            address payable parent = userAccount.referrer;
            Account storage parentAccount = accounts[userAccount.referrer];

            if (parent == address(0)) {
                break;
            }

            uint256 c = value.mul(referralBonus).div(LevelDecimals);
            c = c.mul(levelRate[i]).div(LevelDecimals);

            totalReferal += c;

            parentAccount.reward += c;
            parentAccount.totalBusiness += value;
            IERC20Upgradeable(contractAddress).transfer(parent, c);

            emit PaidReferral(_referee, parent, c, i + 1);

            userAccount = parentAccount;
        }
        TotalRewardDistributed += totalReferal;
        TotalFundRaised += value;
    }

    function BuyWithUSD(
        address payable _referrer,
        uint256 _value
    ) external whenNotPaused {
        uint256 _msgValue = _value;
        address _msgSender = msg.sender;

        require(
            _msgValue >= MinContributionInUSDT,
            "Value must be >= to MinContributionInUSDT"
        );

        if (!hasReferrer(_msgSender) && (_referrer != address(0))) {
            addReferrer(_msgSender, _referrer);
        }

        if (!hasReferrer(_referrer) && (_referrer != address(0))) {
            addReferrer(_referrer, defaultReferrer);
        }

        uint256 tokenValue = _getTokensValueUSD(
            _msgValue,
            PricePerUSDT,
            USDContract
        );

        IERC20Upgradeable(USDContract).transferFrom(
            _msgSender,
            address(this),
            _msgValue
        );

        if (isBuyAndStake == true) {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                tokenValue
            );

            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                tokenValue
            );
        } else {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                _msgSender,
                tokenValue
            );
        }

        if (hasReferrer(_msgSender)) {
            _payReferralInUSD(_msgValue, _msgSender, USDContract);
        }

        totalTokenSold = totalTokenSold + tokenValue;
    }

    function BuyWithBUSD(
        address payable _referrer,
        uint256 _value
    ) external whenNotPaused {
        uint256 _msgValue = _value;
        address _msgSender = msg.sender;

        require(
            _msgValue >= MinContributionInUSDT,
            "Value must be >= to MinContributionInUSDT"
        );

        if (!hasReferrer(_msgSender) && (_referrer != address(0))) {
            addReferrer(_msgSender, _referrer);
        }

        if (!hasReferrer(_referrer) && (_referrer != address(0))) {
            addReferrer(_referrer, defaultReferrer);
        }

        uint256 tokenValue = _getTokensValueUSD(
            _msgValue,
            PricePerUSDT,
            BUSDContract
        );

        IERC20Upgradeable(BUSDContract).transferFrom(
            _msgSender,
            address(this),
            _msgValue
        );

        if (isBuyAndStake == true) {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                StakingContractAddress,
                tokenValue
            );

            StakingContract(StakingContractAddress).StakeToAddress(
                _msgSender,
                tokenValue
            );
        } else {
            IERC20Upgradeable(TokenContractAddress).transferFrom(
                TokenOwnerAddress,
                _msgSender,
                tokenValue
            );
        }

        if (hasReferrer(_msgSender)) {
            _payReferralInUSD(_msgValue, _msgSender, BUSDContract);
        }

        totalTokenSold = totalTokenSold + tokenValue;
    }

    function AddReferrerAdmin(
        address _referree,
        address payable referrer
    ) external onlyOwner returns (bool) {
        addReferrer(_referree, referrer);
        return true;
    }

    function SetStakingContractAddressAdmin(
        address _address
    ) external onlyOwner {
        StakingContractAddress = _address;
    }

    function getStakingContractAddress() external view returns (address) {
        return StakingContractAddress;
    }

    function getUSDContract()
        external
        view
        returns (
            address contractAddress,
            string memory name,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = USDContract;
        name = IERC20_EXTENDED(USDContract).name();
        decimals = IERC20_EXTENDED(USDContract).decimals();
        totalSupply = IERC20Upgradeable(USDContract).totalSupply();
    }

    function setUSDContract(address _address) external onlyOwner {
        USDContract = _address;
    }

    function getBUSDContract()
        external
        view
        returns (
            address contractAddress,
            string memory name,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = BUSDContract;
        name = IERC20_EXTENDED(BUSDContract).name();
        decimals = IERC20_EXTENDED(BUSDContract).decimals();
        totalSupply = IERC20Upgradeable(BUSDContract).totalSupply();
    }

    function setBUSDContract(address _address) external onlyOwner {
        BUSDContract = _address;
    }

    function GetIsBuyAndStakeEnbaled() external view returns (bool) {
        return isBuyAndStake;
    }

    function SetIsBuyAndStakeEnbaledAdmin(bool _value) external onlyOwner {
        isBuyAndStake = _value;
    }

    function getTokenContract()
        external
        view
        returns (
            address contractAddress,
            string memory name,
            uint256 decimals,
            uint256 totalSupply
        )
    {
        contractAddress = TokenContractAddress;
        name = IERC20_EXTENDED(TokenContractAddress).name();
        decimals = IERC20_EXTENDED(TokenContractAddress).decimals();
        totalSupply = IERC20Upgradeable(TokenContractAddress).totalSupply();
    }

    function _getTokenDecimals(
        address _tokenAddress
    ) private view returns (uint256) {
        return IERC20_EXTENDED(_tokenAddress).decimals();
    }

    function getPricePerUSD() external view returns (uint256) {
        return PricePerUSDT;
    }

    function ChangeTokenPriceAdmin(uint256 _price) external onlyOwner {
        PricePerUSDT = _price;
    }

    function ChangeTokenContractAdmin(address _address) external onlyOwner {
        TokenContractAddress = _address;
    }

    function PriceFeedOracleAddress() external view returns (address) {
        return priceFeedOracleAddress;
    }

    function SetPriceFeedOracleAddAdmin(address _address) external onlyOwner {
        priceFeedOracleAddress = _address;
    }

    function GetTokenOwnerAddress() external view returns (address) {
        return TokenOwnerAddress;
    }

    function SetTokenOwnerAdmin(address _address) external onlyOwner {
        TokenOwnerAddress = _address;
    }

    function SetMinContributionAdmin(uint256 _value) external onlyOwner {
        MinContributionInUSDT = _value;
    }

    function SendNativeFundsAdmin(
        address _address,
        uint256 _value
    ) external onlyOwner {
        payable(_address).transfer(_value);
    }

    function WithdrawAdmin() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function WithdrawTokenAdmin(
        address _tokenAddress,
        uint256 _value
    ) external onlyOwner {
        IERC20Upgradeable(_tokenAddress).transfer(msg.sender, _value);
    }
}