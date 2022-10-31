// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/INichoNFTRewards.sol";
import "./utils/DateTimeLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NichoNFTRewards is INichoNFTRewards, Ownable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    IERC20 public rewardsToken;
    uint256 public rewardsTokenDecimal;

    bytes32 public constant REWARDS_ROLE = keccak256("REWARDS_ROLE");
    
    uint256 public userTradeRewardsLimit = 20;
    uint256 public tokenTradeRewardsRate = 50;

    uint256 public userMintRewardsLimit = 20;
    uint256 public tokenMintRewardsRate = 50;

    bool public claimMintEnabled = false;
    bool public claimTradeEnabled = false;

    struct UserRewards {
        uint256 mintNumber;
        uint256 tradeNumber;
        bool mintClaimStatus;
        bool tradeClaimStatus;
        uint256 mintLastUpdateTime;
        uint256 tradeLastUpdateTime;
    }

    struct DailyData {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 tradeNumber;
        uint256 mintNumber;
    }

    struct UserRewardsLog {
        string  rewardsNo;
        uint256 userNumber;
        uint256 totalNumber;
        address userAddress;
        uint256 rewardsAmount;       
        uint256 lastUpdateTime;
    }

    // dateTimeNo -> DailyData;
    mapping(string => DailyData) public dailyData;
    // rewardsNo -> userAddress -> user rewards info
    mapping(string => mapping(address => UserRewards)) public userRewardsMap;
    // rewardsNo -> total trade number
    mapping(string => uint256) public totalTradeNumber;
    // rewardsNo -> total mint number
    mapping(string => uint256) public totalMintNumber;
    // rewardsNo -> trade user set
    mapping(string => EnumerableSet.AddressSet) private tradeUserSet;
    // rewardsNo -> mint user set
    mapping(string => EnumerableSet.AddressSet) private mintUserSet;
    // rewardsNo -> plans reward
    mapping(string => uint256) public plansTradeRewards;
    mapping(string => uint256) public plansMintRewards;

    event MintRewardsAdded(address tokenAddress, string tokenURI, uint256 tokenId, address userAddress, uint256 price, uint256 timestamp);
    event TradeRewardsAdded(address tokenAddress, uint256 tokenId, address userAddress, uint256 timestamp);
    event Claim(string rewardsNo, string operate, address user, uint256 amount, uint256 timestamp);
    event Transfer(address erc20Address, address to, uint256 amount, uint256 timestamp);

    constructor(address _rewardsToken, uint256 _rewardsTokenDecimal) {
        rewardsToken = IERC20(_rewardsToken);
        rewardsTokenDecimal = _rewardsTokenDecimal;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function rewardsMetaData(string memory rewardsNo) 
        public 
        view 
        returns (
            uint256 totalMints,
            uint256 totalTrades,
            uint256 plansMintAmount,
            uint256 plansTradeAmount,
            uint256 tradeRate,
            uint256 mintRate,
            uint256 userTradeLimit,
            uint256 userMintLimit,
            uint256 tokenBalance,
            uint256 availableMintBalance,
            uint256 availableTradeBalance
        ) 
    {
        require(bytes(rewardsNo).length > 0, "NichoNFTRewards: invalid rewardsNo");
        totalMints = totalMintNumber[rewardsNo];
        totalTrades = totalTradeNumber[rewardsNo];
        plansMintAmount = plansMintRewards[rewardsNo];
        plansTradeAmount = plansTradeRewards[rewardsNo];
        tradeRate = tokenTradeRewardsRate;
        mintRate = tokenMintRewardsRate;
        userTradeLimit = userTradeRewardsLimit;
        userMintLimit = userMintRewardsLimit;
        tokenBalance = rewardsTokenBalance();
        availableMintBalance = availableTokenBalance(tokenBalance, tokenMintRewardsRate);
        availableTradeBalance = availableTokenBalance(tokenBalance, tokenTradeRewardsRate);
    }

    function getTradeLog(string memory rewardsNo) public view returns(UserRewardsLog[] memory) {
        EnumerableSet.AddressSet storage set = tradeUserSet[rewardsNo];
        uint256 length = tradeUserSet[rewardsNo].length();
        UserRewardsLog[] memory userRecords = new UserRewardsLog[](length);
        for (uint256 i = 0; i < length; i++) {
            address userAddress = set.at(i);
            UserRewards memory userRewards = userRewardsMap[rewardsNo][userAddress];
            uint256 userTradeRewardsNumber = userRewards.tradeNumber;
            uint256 totalNumber = totalTradeNumber[rewardsNo];
            uint256 plansRewardsAmount = plansTradeRewards[rewardsNo];
            (uint256 userRewardsAmount, ) = calculateRewardsAmount(plansRewardsAmount, tokenTradeRewardsRate, userTradeRewardsNumber, userTradeRewardsLimit, totalNumber);
            
            UserRewardsLog memory log = UserRewardsLog
            ({
                rewardsNo:  rewardsNo,
                userNumber: userTradeRewardsNumber,
                totalNumber: totalNumber,
                userAddress: userAddress,
                rewardsAmount: userRewardsAmount,
                lastUpdateTime: userRewards.tradeLastUpdateTime
            });
            userRecords[i] = log;
        }
        return userRecords;
    }

    function getMintLog(string memory rewardsNo) public view returns(UserRewardsLog[] memory) {
        EnumerableSet.AddressSet storage set = mintUserSet[rewardsNo];
        uint256 length = mintUserSet[rewardsNo].length();
        UserRewardsLog[] memory userRecords = new UserRewardsLog[](length);
        for (uint256 i = 0; i < length; i++) {
            address userAddress = set.at(i);
            UserRewards memory userRewards = userRewardsMap[rewardsNo][userAddress];
            uint256 userMintRewardsNumber = userRewards.mintNumber;
            uint256 totalNumber = totalMintNumber[rewardsNo];
            uint256 plansRewardsAmount = plansMintRewards[rewardsNo];
            (uint256 userRewardsAmount, ) = calculateRewardsAmount(plansRewardsAmount, tokenMintRewardsRate, userMintRewardsNumber, userMintRewardsLimit, totalNumber);
            
            UserRewardsLog memory log = UserRewardsLog
            ({
                rewardsNo:  rewardsNo,
                userNumber: userMintRewardsNumber,
                totalNumber: totalNumber,
                userAddress: userAddress,
                rewardsAmount: userRewardsAmount,
                lastUpdateTime: userRewards.mintLastUpdateTime
            });
            userRecords[i] = log;
        }
        return userRecords;
    }    

    function tradeRewards(
        address tokenAddress,
        uint256 tokenId,
        address userAddress,
        uint256 timestamp
    ) external onlyRole(REWARDS_ROLE) override returns (bool) {
        require(tokenAddress != address(0) && userAddress != address(0), "NichoNFTRewards: user can't be zero address");
        (, , , string memory rewardsNo, , ,) = getCurrentRewardsInfo(timestamp);
        // Get current user reward information
        UserRewards storage userRewards = userRewardsMap[rewardsNo][userAddress];
        // Add 1 for each trade
        userRewards.tradeNumber = userRewards.tradeNumber.add(1);
        // update timestamp
        userRewards.tradeLastUpdateTime = block.timestamp;
        // add uesr set
        tradeUserSet[rewardsNo].add(userAddress);
        // Check user trade limit
        if (userRewards.tradeNumber > userTradeRewardsLimit) {
            return false;
        }
        // Add total trade number
        totalTradeNumber[rewardsNo] = totalTradeNumber[rewardsNo].add(1);
        // Add daily trade number
        updateDailyData(1, 0);

        emit TradeRewardsAdded(tokenAddress, tokenId, userAddress, timestamp);

        return true;
    }

    function mintRewards(
        address tokenAddress,
        string memory tokenURI,
        uint256 tokenId,
        address userAddress,
        uint256 price,
        uint256 timestamp
    ) external onlyRole(REWARDS_ROLE) override returns (bool) {
        require(tokenAddress != address(0) && userAddress != address(0), "NichoNFTRewards: user can't be zero address");
        // Current rewardsNo
        (, , , string memory rewardsNo, , ,) = getCurrentRewardsInfo(timestamp);
        // Get current user reward information
        UserRewards storage userRewards = userRewardsMap[rewardsNo][userAddress];
        // Add 1 for each trade
        userRewards.mintNumber = userRewards.mintNumber.add(1);
        // update timestamp
        userRewards.mintLastUpdateTime = block.timestamp;
        // add uesr set
        mintUserSet[rewardsNo].add(userAddress);
        // Check user mint limit
        if (userRewards.mintNumber > userMintRewardsLimit) {
            return false;
        }
        // Add total mint number
        totalMintNumber[rewardsNo] = totalMintNumber[rewardsNo].add(1);
        // Add daily mint number
        updateDailyData(0, 1);

        emit MintRewardsAdded(tokenAddress, tokenURI, tokenId, userAddress, price, timestamp);

        return true;
    }

    function calculateRewardsAmount(
        uint256 plansRewardsAmount,
        uint256 tokenRewardsRate,
        uint256 userRewardsNumber,
        uint256 userRewardsLimit,
        uint256 totalNumber
    ) private view returns (uint256 userRewardsAmount, uint256 tokenRewardsBalance) {
        // proportion
        (, uint256 proportion) = SafeMath.tryDiv(plansRewardsAmount, totalNumber);
        userRewardsNumber = userRewardsNumber > userRewardsLimit ? userRewardsLimit : userRewardsNumber;
        // User rewards amount
        userRewardsAmount = SafeMath.mul(proportion, userRewardsNumber);
        // reward token balance
        uint256 tokenBalance = rewardsTokenBalance();
        // Available balance
        tokenRewardsBalance = availableTokenBalance(tokenBalance, tokenRewardsRate);
    }

    function availableTokenBalance(uint256 amount, uint256 tokenRewardsRate) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, tokenRewardsRate), 100);
    }

    function plansRewardsAmounts(string memory rewardsNo) private view returns (uint256 plansTradeRewardsAmount, uint256 plansMintRewardsAmount) {
        plansTradeRewardsAmount = plansTradeRewards[rewardsNo];
        plansMintRewardsAmount = plansMintRewards[rewardsNo];
    }

    function rewardsTokenBalance() public view returns (uint256) {
        return rewardsToken.balanceOf(address(this));
    }

    /**
     * @dev Users can only claim last week's reward
     */
    function claimTradeRewards() public nonReentrant {
        require(claimTradeEnabled, "NichoNFTRewards: claim unavailable");
        address currentUser = _msgSender();
        // get rewardsNo
        (, string memory lastRewardsNo, string memory currentRewardsNo) = getLastRewardsNo();
        UserRewards storage userRewards = userRewardsMap[lastRewardsNo][currentUser];
        // check rewardsNo
        require(!DateTimeLibrary.compareStrings(lastRewardsNo, currentRewardsNo), "NichoNFTRewards: invalid rewardsNo");
        // check claim status
        require(!userRewards.tradeClaimStatus, "NichoNFTRewards: Already claims");    
        uint256 userTradeRewardsNumber = userRewards.tradeNumber;
        uint256 totalNumber = totalTradeNumber[lastRewardsNo];
        uint256 plansRewardsAmount = plansTradeRewards[lastRewardsNo];
        (uint256 userRewardsAmount, uint256 tokenRewardsBalance) = calculateRewardsAmount(plansRewardsAmount, tokenTradeRewardsRate, userTradeRewardsNumber, userTradeRewardsLimit, totalNumber);
        // check amount
        require(userRewardsAmount > 0 && tokenRewardsBalance >= userRewardsAmount, "NichoNFTRewards: invalid amount");
        // set trade claims status
        userRewards.tradeClaimStatus = true;
        // update timestamp
        userRewards.tradeLastUpdateTime = block.timestamp;        
        // transfer rewardsToken
        rewardsToken.safeTransfer(currentUser, userRewardsAmount);

        emit Claim(lastRewardsNo, "trade", currentUser, userRewardsAmount, block.timestamp);
    }

    /**
     * @dev Users can only claim last week's reward
     */
    function claimMintRewards() public nonReentrant {
        require(claimMintEnabled, "NichoNFTRewards: claim unavailable");
        address currentUser = _msgSender();
        // get rewardsNo
        (, string memory lastRewardsNo, string memory currentRewardsNo) = getLastRewardsNo();
        UserRewards storage userRewards = userRewardsMap[lastRewardsNo][currentUser];
        // check rewardsNo
        require(!DateTimeLibrary.compareStrings(lastRewardsNo, currentRewardsNo), "NichoNFTRewards: invalid rewardsNo");
        // check claim status
        require(!userRewards.mintClaimStatus, "NichoNFTRewards: Already claims");
        uint256 userMintRewardsNumber = userRewards.mintNumber;
        uint256 totalNumber = totalMintNumber[lastRewardsNo];
        uint256 plansRewardsAmount = plansMintRewards[lastRewardsNo];
        (uint256 userRewardsAmount, uint256 tokenRewardsBalance) = calculateRewardsAmount(plansRewardsAmount, tokenMintRewardsRate, userMintRewardsNumber, userMintRewardsLimit, totalNumber);
        // check amount
        require(userRewardsAmount > 0 && tokenRewardsBalance >= userRewardsAmount, "NichoNFTRewards: invalid amount");
        // set mint claims status
        userRewards.mintClaimStatus = true;
        // update timestamp
        userRewards.mintLastUpdateTime = block.timestamp;            
        // transfer rewardsToken
        rewardsToken.safeTransfer(currentUser, userRewardsAmount);

        emit Claim(lastRewardsNo, "mint", currentUser, userRewardsAmount, block.timestamp);
    }

    function transferToken(
        address _erc20Address,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20 erc20 = IERC20(_erc20Address);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance >= _amount, "NichoNFTRewards: invalid amount");
        erc20.safeTransfer(_to, _amount);

        emit Transfer(_erc20Address, _to, _amount, block.timestamp);
    }

    function userCurrentTradeRewardsData(address userAddress) 
        public 
        view 
        returns (
            uint256 plansRewardsAmount, 
            uint256 tokenRewardsBalance, 
            uint256 userTokenBalance, 
            uint256 userRewardsAmount, 
            uint256 lastWeekOfYear, 
            bool tradeClaimStatus, 
            uint256 tradeLastUpdateTime
        ) 
    {
        userTokenBalance = rewardsToken.balanceOf(userAddress);
        (uint256 _lastWeekOfYear, string memory lastRewardsNo, ) = getLastRewardsNo();
        UserRewards memory userRewards = userRewardsMap[lastRewardsNo][userAddress];
        tradeClaimStatus = userRewards.tradeClaimStatus;
        tradeLastUpdateTime = userRewards.tradeLastUpdateTime;
        uint256 userTradeRewardsNumber = userRewards.tradeNumber;
        uint256 totalNumber = totalTradeNumber[lastRewardsNo];
        lastWeekOfYear = _lastWeekOfYear;
        plansRewardsAmount = plansTradeRewards[lastRewardsNo];
        (userRewardsAmount, tokenRewardsBalance) = calculateRewardsAmount(plansRewardsAmount, tokenTradeRewardsRate, userTradeRewardsNumber, userTradeRewardsLimit, totalNumber);
    }

    function userCurrentMintRewardsData(address userAddress)   
        public 
        view
        returns (
            uint256 plansRewardsAmount, 
            uint256 tokenRewardsBalance, 
            uint256 userTokenBalance,
            uint256 userMints, 
            uint256 userRewardsAmount, 
            bool mintClaimStatus,
            uint256 mintLastUpdateTime
        ) 
    {   
        userTokenBalance = rewardsToken.balanceOf(userAddress);
        (, string memory lastRewardsNo, ) = getLastRewardsNo();
        UserRewards memory userRewards = userRewardsMap[lastRewardsNo][userAddress];
        userMints = userRewards.mintNumber;
        mintClaimStatus = userRewards.mintClaimStatus;
        mintLastUpdateTime = userRewards.mintLastUpdateTime;
        uint256 userMintRewardsNumber = userRewards.mintNumber;
        uint256 totalNumber = totalMintNumber[lastRewardsNo];
        plansRewardsAmount = plansMintRewards[lastRewardsNo];
        (userRewardsAmount, tokenRewardsBalance) = calculateRewardsAmount(plansRewardsAmount, tokenTradeRewardsRate, userMintRewardsNumber, userMintRewardsLimit, totalNumber);
    }

    function getRewardsNoByDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) public pure returns (string memory) {
        uint256 time = DateTimeLibrary.timestampFromDate(year, month, day);
        (, uint256 weekOfYear, uint256 yearOfPeriod) = DateTimeLibrary.weekOfYear(time);
        string memory _weekOfYear = fillZero(weekOfYear);
        return DateTimeLibrary.addLine(yearOfPeriod.toString(), _weekOfYear, "");
    }

    function getLastRewardsNoByDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) public pure returns (string memory) {
        uint256 time = DateTimeLibrary.timestampFromDate(year, month, day);
        (, uint256 weekOfYear, uint256 yearOfPeriod) = DateTimeLibrary.weekOfYear(time);
        if (weekOfYear == 1) {
            weekOfYear = 52;
            yearOfPeriod = yearOfPeriod - 1;
        } else {
            weekOfYear = weekOfYear - 1;
        }
        string memory _lastWeekOfYear = fillZero(weekOfYear);
        return DateTimeLibrary.addLine(yearOfPeriod.toString(), _lastWeekOfYear, "");
    }

    function getRecentDailyData(uint256 _days) public view returns (DailyData[] memory) {
        uint256 currentDateTime = block.timestamp;
        uint256 startDateTime = DateTimeLibrary.subDays(currentDateTime, _days);
        DailyData[] memory daily = new DailyData[](_days + 1);
        for (uint256 i = 0; i <= _days; i++) {
            (string memory dateNo, uint256 year, uint256 month, uint256 day) = getDateNo(startDateTime);
            DailyData memory _data = dailyData[dateNo];
            _data.year = year;
            _data.month = month;
            _data.day = day;
            daily[i] = _data;
            startDateTime = DateTimeLibrary.addDays(startDateTime, 1);
        }
        return daily;
    }    

    function getDateNo(uint timestamp) public pure returns(string memory dateNo, uint256 year, uint256 month, uint256 day) {
        (year, month, day) = DateTimeLibrary.timestampToDate(timestamp);
        dateNo = DateTimeLibrary.addLine(year.toString(), month.toString(), day.toString());
    }

    function updateDailyData(uint256 tradeNumber, uint256 mintNumber) private {
        (string memory dateNo, uint256 year, uint256 month, uint256 day) = getDateNo(block.timestamp);
        DailyData storage _dailyData = dailyData[dateNo];
        _dailyData.year = year;
        _dailyData.month = month;
        _dailyData.day = day;
        if (tradeNumber > 0) {  
            _dailyData.tradeNumber = _dailyData.tradeNumber.add(1);
        }
        if (mintNumber > 0) {
            _dailyData.mintNumber = _dailyData.mintNumber.add(1);
        }
    }

    function getCurrentRewardsNo() public view returns (string memory) {
        uint256 currentDateTime = DateTimeLibrary.currentDateTime();
        (, , , string memory rewardsNo, , ,) = getCurrentRewardsInfo(currentDateTime);
        return rewardsNo;
    }

    function getLastRewardsNo()
        public
        view
        returns (uint256 lastWeekOfYear, string memory lastRewardsNo, string memory currentRewardsNo)
    {
        uint256 currentDateTime = DateTimeLibrary.currentDateTime();
        (, , , currentRewardsNo, lastWeekOfYear, , lastRewardsNo) = getCurrentRewardsInfo(currentDateTime);
    }

    function getCurrentRewardsInfo(uint256 timestamp)
        public
        pure
        returns (
            uint256 dayOfWeek,
            uint256 weekOfYear,
            uint256 yearOfPeriod,
            string memory currentRewardsNo,
            uint256 lastWeekOfYear,
            uint256 lastYearOfPeriod,
            string memory lastRewardsNo
        )
    {
        (dayOfWeek, weekOfYear, yearOfPeriod) = DateTimeLibrary.weekOfYear(timestamp);
        string memory _weekOfYear = fillZero(weekOfYear);
        currentRewardsNo = DateTimeLibrary.addLine(yearOfPeriod.toString(), _weekOfYear, "");
        if (weekOfYear == 1) {
            lastWeekOfYear = 52;
            lastYearOfPeriod = yearOfPeriod - 1;
        } else {
            lastWeekOfYear = weekOfYear - 1;
            lastYearOfPeriod = yearOfPeriod;
        }
        string memory _lastWeekOfYear = fillZero(lastWeekOfYear);
        lastRewardsNo = DateTimeLibrary.addLine(lastYearOfPeriod.toString(), _lastWeekOfYear, "");
    }

    function fillZero(uint256 weekOfYear) private pure returns (string memory) {
        return
            weekOfYear < 10
                ? DateTimeLibrary.addLine("0", weekOfYear.toString(), "")
                : weekOfYear.toString();
    }

    function setRewardsToken(address _rewardsToken, uint256 _rewardsTokenDecimal) public onlyOwner {
        rewardsToken = IERC20(_rewardsToken);
        rewardsTokenDecimal = _rewardsTokenDecimal;
    }

    function setClaimEnabled(bool _claimMintEnabled, bool _claimTradeEnabled) public onlyOwner {
        claimMintEnabled = _claimMintEnabled;
        claimTradeEnabled = _claimTradeEnabled;
    }

    function updateUserRewardsLimit(uint256 newUserMintRewardsLimit, uint256 newUserTradeRewardsLimit) public onlyOwner {
        require(newUserMintRewardsLimit > 0 && newUserTradeRewardsLimit > 0, "NichoNFTRewards: invalid rewards limit");
        require(userMintRewardsLimit != newUserMintRewardsLimit || userTradeRewardsLimit != newUserTradeRewardsLimit, "NichoNFTRewards: Already exists");
        userTradeRewardsLimit = newUserTradeRewardsLimit;
        userMintRewardsLimit = newUserMintRewardsLimit;
    }

    function updateTokenRewardsRate(uint256 newTokenTradeRewardsRate, uint256 newTokenMintRewardsRate) public onlyOwner {
        require(newTokenTradeRewardsRate > 0 && newTokenMintRewardsRate > 0, "NichoNFTRewards: invalid rewards rate");
        require(newTokenTradeRewardsRate + newTokenMintRewardsRate <= 100, "NichoNFTRewards: parameter error");
        tokenTradeRewardsRate = newTokenTradeRewardsRate;
        tokenMintRewardsRate = newTokenMintRewardsRate;
    }

    function updatePlansRewardAmount(string memory rewardsNo, uint256 tradeAmount, uint256 mintAmount) public onlyOwner {
        require(bytes(rewardsNo).length > 0 && tradeAmount > 0 && mintAmount > 0, "NichoNFTRewards: invalid rewards amount");
        plansTradeRewards[rewardsNo] = tradeAmount * 10 ** rewardsTokenDecimal;
        plansMintRewards[rewardsNo] = mintAmount * 10 ** rewardsTokenDecimal;
    }

}