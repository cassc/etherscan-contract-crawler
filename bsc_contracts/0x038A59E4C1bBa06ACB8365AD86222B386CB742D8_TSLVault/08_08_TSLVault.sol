// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ITSLVIPRegistery.sol";
import "./router/uniswapV2Router.sol";

contract TSLVault is Initializable, OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;
    bool public paused;
    address public usdt;
    IUniswapV2Router02 public uniswapV2Router;
    address private feeReceiver;
    address public TSLRegistry;
    address public TSL;
    address public YZS;
    address[] tokenList;
    uint256 public pubLevel;
    uint256 public totalDeposit;
    struct PoolConfig {
        uint256 rewardPerSecond; // 115740740740
        uint256 stakePeriod; //default 200days
    }

    event Deposit(
        address indexed user,
        uint256 indexed amount,
        address token,
        address firstInviter
    );
    event Claim(address indexed user, uint256 indexed amount);

    PoolConfig public poolConfig;
    struct ReferralConfig {
        uint256 first;
        uint256 second;
        uint256 team;
        uint256 threshold; //default 5000
        uint256 num; //default 12
    }

    ReferralConfig public referralConfig;
    mapping(address => address[]) private tokenPath;
    mapping(uint256 => uint256) public LevelBalance;
    mapping(uint256 => uint256) public LevelNum;
    // user info
    mapping(address => uint256) private userLevel;
    mapping(address => mapping(uint256 => uint256)) private userLevelNum;

    struct UserDepositInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 rewardPerSecond;
        uint256 value;
        uint256 claimedValue;
        bool claimed;
    }

    struct Invitation {
        address user;
        uint256 time;
        uint256 value;
    }

    struct RefClaimInfo {
        uint256 time;
        uint256 value;
    }

    mapping(address => UserDepositInfo[]) private userDepositInfo;
    //inviter info
    mapping(address => uint256) private userInvitedValue;
    mapping(address => uint256) private userSecondValue;
    mapping(address => uint256) private userTeamValue;
    mapping(address => uint256) public userInvest;
    mapping(address => Invitation[]) private directInvitation;
    mapping(address => Invitation[]) private indirectInvitation;
    mapping(address => Invitation[]) private teamInvitation;
    //inviter Referral reward
    mapping(address => uint256) private referralReward;
    mapping(address => uint256) private userRefClaimed;
    mapping(address => RefClaimInfo[]) private refClaimInfo;
    mapping(address => bool) private isOperator;

    modifier onlyOperator() {
        require(isOperator[msg.sender], "not operator");
        _;
    }

    function initialize(address usdt_, address ITSLVIPRegistery_)
        public
        initializer
    {
        __Ownable_init();
        usdt = usdt_;
        TSLRegistry = ITSLVIPRegistery_;
        feeReceiver = 0x72532411a9EB5fc35c024C3e4f4cefc9627B1354;
        TSL = 0x1f49b66d82e55eB2e02cC2b1FddBC70978469238;
        YZS = 0xd37D8DBF6f15973F6f1F261e18E10A2a86edF3F7;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
    }

    function deposit(
        address token,
        uint256 level_,
        uint256 num_
    ) public nonReentrant {
        require(!paused, "pool paused");
        require(tokenExist(token), "invalid token");
        require(level_ > 0 && num_ > 0, "invalid level");
        require(LevelBalance[level_] > 0, "invalid balance");
        require(
            userLevel[msg.sender] >= level_ || level_ <= pubLevel,
            "unauthorized user level"
        );
        require(
            userLevelNum[msg.sender][level_] + num_ <= LevelNum[level_],
            "exceed max level number"
        );
        uint256 depositAmount = LevelBalance[level_].mul(num_);
        IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            depositAmount.mul(110).div(100)
        );
        _burnToken(depositAmount);
        //deal Referral Reward
        uint256 am;
        address[] memory userInviters = ITSLVIPRegistery(TSLRegistry)
            .getInviters(msg.sender);
        require(userInviters.length > 0, "no inviter");
        address firstInviter = userInviters[0];
        am = userInvest[firstInviter] > depositAmount
            ? depositAmount
            : userInvest[firstInviter];
        referralReward[firstInviter] += am.mul(referralConfig.first).div(1000);
        userInvitedValue[firstInviter] += depositAmount;
        Invitation[] storage dInv = directInvitation[firstInviter];
        Invitation memory invitation;
        invitation.time = block.timestamp;
        invitation.user = msg.sender;
        invitation.value = depositAmount;
        dInv.push(invitation);

        if (userInviters.length > 1) {
            address secondInviter = userInviters[1];
            am = userInvest[secondInviter] > depositAmount
                ? depositAmount
                : userInvest[secondInviter];
            referralReward[secondInviter] += am.mul(referralConfig.second).div(
                1000
            );
            userSecondValue[secondInviter] += depositAmount;
            Invitation[] storage inDinv = indirectInvitation[secondInviter];
            inDinv.push(invitation);
        }
        if (userInviters.length > 2) {
            for (uint256 i = 2; i < userInviters.length; i++) {
                // invited value must >= 5000u or invited people >= 12;
                address[] memory userInvited = ITSLVIPRegistery(TSLRegistry)
                    .getInvited(userInviters[i]);
                if (
                    userInvitedValue[userInviters[i]] >=
                    referralConfig.threshold * 1e18 &&
                    userInvited.length >= referralConfig.num
                ) {
                    am = userInvest[userInviters[i]] > depositAmount
                        ? depositAmount
                        : userInvest[userInviters[i]];
                    referralReward[userInviters[i]] += am
                        .mul(referralConfig.team)
                        .div(1000);
                    userTeamValue[userInviters[i]] += depositAmount;
                    Invitation[] storage teamInv = teamInvitation[
                        userInviters[i]
                    ];
                    teamInv.push(invitation);
                }
            }
        }

        //deal userInfo
        userLevelNum[msg.sender][level_] += num_;
        UserDepositInfo memory userInfo;
        userInfo.startTimestamp = block.timestamp;
        userInfo.endTimestamp = block.timestamp + poolConfig.stakePeriod;
        userInfo.rewardPerSecond = poolConfig.rewardPerSecond;
        userInfo.value = depositAmount;
        UserDepositInfo[] storage Info = userDepositInfo[msg.sender];
        Info.push(userInfo);
        totalDeposit += depositAmount;
        userInvest[msg.sender] += depositAmount;

        emit Deposit(msg.sender, depositAmount, token, firstInviter);
    }

    function claimRefReward() public nonReentrant {
        require(!paused, "pool paused");
        require(referralReward[msg.sender] > 0, "no reward");
        uint256 amount = referralReward[msg.sender];
        referralReward[msg.sender] = 0;
        IERC20(usdt).transfer(msg.sender, amount.mul(98).div(100));
        IERC20(usdt).transfer(feeReceiver, amount.mul(2).div(100));
        userRefClaimed[msg.sender] += amount;
        RefClaimInfo memory info;
        info.time = block.timestamp;
        info.value = amount;
        RefClaimInfo[] storage refInfo = refClaimInfo[msg.sender];
        refInfo.push(info);
    }

    function getUserRefCanClaim(address user) public view returns (uint256) {
        return referralReward[user];
    }

    function getUserRefClaimed(address user) public view returns (uint256) {
        return userRefClaimed[user];
    }

    function claim() public nonReentrant {
        require(!paused, "pool paused");
        UserDepositInfo[] storage userInfo = userDepositInfo[msg.sender];
        uint256 amount;
        for (uint256 i = 0; i < userInfo.length; i++) {
            if (
                userInfo[i].endTimestamp <= block.timestamp &&
                !userInfo[i].claimed
            ) {
                uint256 cal_ = userInfo[i]
                    .value
                    .mul(
                        userInfo[i].endTimestamp.sub(userInfo[i].startTimestamp)
                    )
                    .mul(userInfo[i].rewardPerSecond)
                    .div(1e18)
                    .sub(userInfo[i].claimedValue);
                amount += cal_;
                userInfo[i].claimed = true;
                userInfo[i].claimedValue += cal_;
            }
            if (
                userInfo[i].endTimestamp > block.timestamp &&
                !userInfo[i].claimed
            ) {
                uint256 cal_ = userInfo[i]
                    .value
                    .mul(block.timestamp.sub(userInfo[i].startTimestamp))
                    .mul(userInfo[i].rewardPerSecond)
                    .div(1e18)
                    .sub(userInfo[i].claimedValue);
                amount += cal_;
                userInfo[i].claimedValue += cal_;
            }
        }
        require(amount > 0, "invalid amount");
        IERC20(usdt).transfer(msg.sender, amount.mul(98).div(100));
        IERC20(usdt).transfer(feeReceiver, amount.mul(2).div(100));
        emit Claim(msg.sender, amount);
    }

    function emergencyClaim() public nonReentrant {
        require(!paused, "pool paused");
        UserDepositInfo[] storage userInfo = userDepositInfo[msg.sender];
        uint256 amount;
        for (uint256 i = 0; i < userInfo.length; i++) {
            if (userInfo[i].claimedValue < userInfo[i].value) {
                amount += userInfo[i].value.sub(userInfo[i].claimedValue);
                userInfo[i].claimed = true;
                userInfo[i].claimedValue = userInfo[i].value;
            }
        }
        require(amount > 0, "invalid amount");
        IERC20(usdt).transfer(msg.sender, amount.mul(70).div(100));
        IERC20(usdt).transfer(feeReceiver, amount.mul(2).div(100));
        emit Claim(msg.sender, amount);
    }

    function getUserDeposited(address user) public view returns (uint256) {
        UserDepositInfo[] memory userInfo = userDepositInfo[user];
        uint256 amount;
        for (uint256 i = 0; i < userInfo.length; i++) {
            if (!userInfo[i].claimed) {
                amount += userInfo[i].value;
            }
        }
        return amount;
    }

    function getUserClaimed(address user) public view returns (uint256) {
        UserDepositInfo[] memory userInfo = userDepositInfo[user];
        uint256 amount;
        for (uint256 i = 0; i < userInfo.length; i++) {
            amount += userInfo[i].claimedValue;
        }
        return amount;
    }

    function getUserCanClaim(address user) public view returns (uint256) {
        UserDepositInfo[] memory userInfo = userDepositInfo[user];
        uint256 amount;
        for (uint256 i = 0; i < userInfo.length; i++) {
            uint256 timeStamp = userInfo[i].endTimestamp > block.timestamp
                ? block.timestamp
                : userInfo[i].endTimestamp;
            if (!userInfo[i].claimed) {
                amount += userInfo[i]
                    .value
                    .mul(timeStamp.sub(userInfo[i].startTimestamp))
                    .mul(userInfo[i].rewardPerSecond)
                    .div(1e18)
                    .sub(userInfo[i].claimedValue);
            }
        }
        return amount;
    }

    function addToken(address token, address[] memory tokenPath_)
        public
        onlyOwner
    {
        tokenList.push(token);
        tokenPath[token] = tokenPath_;
    }

    function setUserDeposit(address user, uint256 amount_) public onlyOperator {
        UserDepositInfo[] storage Info = userDepositInfo[user];
        UserDepositInfo memory userInfo;
        userInfo.startTimestamp = block.timestamp;
        userInfo.endTimestamp = block.timestamp + poolConfig.stakePeriod;
        userInfo.rewardPerSecond = poolConfig.rewardPerSecond;
        userInfo.value = amount_;
        Info.push(userInfo);
    }

    function setOperator(address user, bool b) public onlyOwner {
        isOperator[user] = b;
    }

    function tokenExist(address token) public view returns (bool) {
        bool b;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (token == tokenList[i]) {
                return true;
            }
        }
        return b;
    }

    function configLevel(
        uint256[] memory num_,
        uint256[] memory bal_,
        uint256 pubLevel_
    ) public onlyOwner {
        require(num_.length == bal_.length, "mismatch length");
        for (uint256 i = 0; i < bal_.length; i++) {
            LevelBalance[i + 1] = bal_[i];
            LevelNum[i + 1] = num_[i];
        }
        pubLevel = pubLevel_;
    }

    function _burnToken(uint256 amount_) internal {
        uint256 amount = amount_.mul(5).div(100);
        uint256[] memory amountsAOut = uniswapV2Router.getAmountsOut(
            amount,
            tokenPath[TSL]
        );
        uniswapV2Router.swapExactTokensForTokens(
            amount,
            amountsAOut[amountsAOut.length - 1].mul(95).div(100),
            tokenPath[TSL],
            0x000000000000000000000000000000000000dEaD,
            block.timestamp + 1800
        );

        uint256[] memory amountsBOut = uniswapV2Router.getAmountsOut(
            amount,
            tokenPath[YZS]
        );
        uniswapV2Router.swapExactTokensForTokens(
            amount,
            amountsBOut[amountsBOut.length - 1].mul(95).div(100),
            tokenPath[YZS],
            0x000000000000000000000000000000000000dEaD,
            block.timestamp + 1800
        );
    }

    function getUserLevelNum(address user, uint256 level_)
        public
        view
        returns (uint256)
    {
        return userLevelNum[user][level_];
    }

    function setReferralConfig(ReferralConfig memory ref_) public onlyOwner {
        referralConfig = ref_;
    }

    function setFeeReceiver(address user) public onlyOwner {
        feeReceiver = user;
    }

    function setPoolConfig(PoolConfig memory poolConfig_) public onlyOwner {
        poolConfig = poolConfig_;
    }

    function flipPool() public onlyOwner {
        paused = !paused;
    }

    function setRegistry(address registry_) public onlyOwner {
        TSLRegistry = registry_;
    }

    function getTokenList() public view returns (address[] memory) {
        return tokenList;
    }

    function setUserLevel(address user, uint256 num_) public onlyOwner {
        userLevel[user] = num_;
    }

    function withDraw(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function getUserDepositInfo(address user)
        public
        view
        returns (UserDepositInfo[] memory)
    {
        return userDepositInfo[user];
    }

    function getUserLevel(address user) public view returns (uint256) {
        return userLevel[user];
    }

    function getUserInvitedValue(address user) public view returns (uint256) {
        return userInvitedValue[user];
    }

    function getUserSecondValue(address user) public view returns (uint256) {
        return userSecondValue[user];
    }

    function getUserTeamValue(address user) public view returns (uint256) {
        return userTeamValue[user];
    }

    function getDirectInvitation(address user)
        public
        view
        returns (Invitation[] memory)
    {
        return directInvitation[user];
    }

    function getIndirectInvitation(address user)
        public
        view
        returns (Invitation[] memory)
    {
        return indirectInvitation[user];
    }

    function getTeamInvitation(address user)
        public
        view
        returns (Invitation[] memory)
    {
        return teamInvitation[user];
    }

    function getRefClaimInfo(address user)
        public
        view
        returns (RefClaimInfo[] memory)
    {
        return refClaimInfo[user];
    }

    function approveToken() public onlyOwner {
        IERC20(usdt).approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E), type(uint256).max);
    }
}