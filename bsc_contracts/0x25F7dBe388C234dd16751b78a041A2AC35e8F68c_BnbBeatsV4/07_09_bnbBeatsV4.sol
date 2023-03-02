/**
 *Submitted for verification at BscScan.com on 2022-11-17
 */

/** 
██████╗ ███╗   ██╗██████╗ ███████╗ █████╗ ████████╗███████╗   4
██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝ 
██████╔╝██╔██╗ ██║██████╔╝█████╗  ███████║   ██║   ███████╗    
██╔══██╗██║╚██╗██║██╔══██╗██╔══╝  ██╔══██║   ██║   ╚════██║    
██████╔╝██║ ╚████║██████╔╝███████╗██║  ██║   ██║   ███████║   
╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    

BNBeast Farm | earn money until 4% daily | Metaversing 
SPDX-License-Identifier: MIT
*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IContractsLibrary.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.14;

contract BnbBeatsV4 is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    IERC20 TOKEN;
    IContractsLibrary public contractsLibrary;

    uint256 private BEATS_TO_HATCH_1MINERS = 1080000; //for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private balanceLimit = 100;

    uint256 private constant REFERRER_PERCENTS_LENGTH = 6;
    uint256[REFERRER_PERCENTS_LENGTH] private REFERRER_PERCENTS = [
        900, //1 level
        300, // 2 level
        200, // 3 level
        150,// 4 level
        100,// 5 level
        50 // 6 level
    ];

    // price whitelist = 30$
    uint256 private constant nWhitelistFee = 10000; // 100%

    uint256 private constant priceWhiteList = 30 ether;

    uint256 private constant secureToNwallet = 8000; // 80%
    uint256 private constant secureToJwallet = 1000; // 10%
    uint256 private constant secureToDev = 1000; // 10%
    uint256 public constant priceSecure = 100 ether;
    EnumerableSet.AddressSet internal secureUsers;

    uint256 public marketBeats;
    uint256 private players;

    struct User {
        uint256 invest;
        uint256 withdraw;
        uint256 reinvest;
        uint256 hatcheryMiners;
        uint256 claimedBeats;
        uint256 lastHatch;
        uint256 checkpoint;
        bool originDone;
        address referrals;
        uint256[REFERRER_PERCENTS_LENGTH] referrer;
        uint256 amountBNBReferrer;
        uint256 amountBEATSReferrer;
        uint256 totalRefDeposits;
        bool isFirstUser;
        uint premiumBonus;
    }

    uint256 public initDate;

    mapping(address => User) public users;
    mapping(address => bool) public whiteList;

    struct UserWithdrawData {
        address user;
        uint256 amount;
        uint256[REFERRER_PERCENTS_LENGTH] referrer;
    }

    mapping(address => UserWithdrawData) public userWithdrawData;
    mapping(uint256 => address) public userWithdrawDataIndex;
    uint256 public userWithdrawDataLength;

    uint256 public totalInvested;
    uint256 internal constant TIME_STEP = 1 days;
    uint256 internal constant FIRST_USER_THERSHOLD = 1;

    address payable public pWallet;

    address payable public constant nWallet =
        payable(0xAbecB4CB5c8Cfaa5a4a1fEe3172357778722589e);

    address payable public constant nWallet2 =
        payable(0x810331938e27aE4A0aD5d7D88696E347312232Fc);

    // mWallet = marketing wallet
    address payable public constant mWallet =
        payable(0x1e4679A5ba393970bC08333de15637487Ac5ec7F);

    address payable public jWallet;
    address payable public devWallet;

    uint256 internal constant PERCENTS_DIVIDER = 10000; // 100% = 10000, 10% = 1000, 1% = 100
    // 2% NWallet:
    uint256 internal constant NWALLET_FEE = 200;
    // 1.1% JWallet:
    uint256 internal constant JWALLET_FEE = 110;
    // 1.4% Dev:
    uint256 internal constant DEV_FEE = 140;
    // 1% mWallet:
    uint256 internal constant MWALLET_FEE = 200; //marketing
    // 1.5% pWallet:
    uint256 internal constant PWALLET_FEE = 250; //partner

    uint constant internal BNB_TO_PREMIUM1 = 1000 ether;
    uint constant internal BNB_TO_PREMIUM2 = 2500 ether;
    uint constant internal BNB_TO_PREMIUM3 = 10000 ether;
    uint constant internal BNB_TO_PREMIUM4 = 20000 ether;
    uint constant internal BNB_TO_PREMIUM5 = 100000 ether;

    EnumerableSet.AddressSet internal premiumUsers1;
    EnumerableSet.AddressSet internal premiumUsers2;
    EnumerableSet.AddressSet internal premiumUsers3;
    EnumerableSet.AddressSet internal premiumUsers4;
    EnumerableSet.AddressSet internal premiumUsers5;

    uint constant internal premium1Bonus = 50;
    uint constant internal premium2Bonus = 100;
    uint constant internal premium3Bonus = 150;
    uint constant internal premium4Bonus = 200;
    uint constant internal premium5Bonus = 250;

    struct FeeStruct {
        address wallet;
        uint256 amount;
    }

    EnumerableSet.AddressSet internal whiteListAdmin;

    uint internal constant penalization1day = 10;
    uint internal constant penalization2day = 15;
    uint internal constant penalization3day = 20;

    uint internal constant penalization1dayPercent = 62;
    uint internal constant penalization2dayPercent = 125;
    uint internal constant penalization3dayPercent = 250;

    event WhiteListSet(address indexed user, bool indexed status);
    event TotalWithdraw(address indexed user, uint256 amount);

    // pausable
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    //
    constructor(
        address _token,
        address _library,
        address _dev,
        address _jWallet,
        address _pWallet
    ) {
        TOKEN = IERC20(_token);
        contractsLibrary = IContractsLibrary(_library);
        devWallet = payable(_dev);
        jWallet = payable(_jWallet);
        pWallet = payable(_pWallet);
        marketBeats = 108000000000;
        whiteListAdmin.add(pWallet);
        whiteListAdmin.add(nWallet);
        whiteListAdmin.add(nWallet2);
        whiteListAdmin.add(mWallet);
        whiteListAdmin.add(jWallet);
        whiteListAdmin.add(devWallet);

        _pause();
    }

    function unpause() public checkOwner_ {
        _unpause();
        initDate = block.timestamp;
    }

    function secondsFromInit() public view returns (uint256) {
        if (initDate == 0) {
            return 0;
        }
        return block.timestamp.sub(initDate);
    }

    function daysFromInit() public view returns (uint256) {
        return secondsFromInit().div(TIME_STEP);
    }

    modifier checkUser_() {
        require(checkUser(), "try again later 1");
        _;
    }

    modifier checkReinvest_() {
        require(checkReinvest(), "try again later 2 ");
        _;
    }

    modifier checkOwner_() {
        require(checkOwner(), "try again later 3");
        _;
    }

    function checkOwner() public view returns (bool) {
        return msg.sender == devWallet;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return whiteListAdmin.contains(account);
    }

    function getWhitelistAdminis() external view returns (address[] memory) {
        return whiteListAdmin.values();
    }

    modifier onlyWhitelistAdmin() {
        require(
            isWhitelistAdmin(msg.sender),
            "WhitelistAdminRole: caller does not have the WhitelistAdmin role"
        );
        _;
    }

    function checkUser() public view returns (bool) {
        uint256 check = block.timestamp.sub(users[msg.sender].checkpoint);
        if (check > TIME_STEP) {
            return true;
        }
        return false;
    }

    function checkReinvest() public view returns (bool) {
        uint256 check = block.timestamp.sub(users[msg.sender].checkpoint);
        if (check > TIME_STEP) {
            return true;
        }
        return false;
    }

    function getDateForSelling(address adr) public view returns (uint256) {
        return SafeMath.add(users[adr].checkpoint, TIME_STEP);
    }

    function reInvest() external checkReinvest_ nonReentrant whenNotPaused {
        calculateReinvest();
    }

    function hatchBeats(uint256 beatsUsed, User storage user) private {
        uint256 newMiners = SafeMath.div(beatsUsed, BEATS_TO_HATCH_1MINERS);
        user.hatcheryMiners = SafeMath.add(user.hatcheryMiners, newMiners);
        user.claimedBeats = 0;
        user.lastHatch = block.timestamp;
        user.checkpoint = block.timestamp;
        //boost market to nerf miners hoarding
        marketBeats = SafeMath.add(marketBeats, SafeMath.div(beatsUsed, 5));
    }

    

    function calculateMyBeats(address adr, bool isReinvest)
        public
        view
        returns (
            uint256 hasBeats,
            uint256 beatValue,
            uint256 beats
        )
    {
        uint256 beats_ = getMyBeats(adr);
        uint256 hasBeats_ = beats_; // beats for reinvest
        uint256 beatValue_; // beat value for withdraw
        (uint256 multiplier, uint256 divider) = getMyBonus(adr, isReinvest);
        beatValue_ = calculateBeatSell(
            SafeMath.div(SafeMath.mul(hasBeats_, multiplier), divider)
        );
        hasBeats_ -= SafeMath.div(SafeMath.mul(hasBeats_, multiplier), divider);

        hasBeats = hasBeats_;
        beatValue = beatValue_;
        beats = calculateBeatSell(beats_); // beats total value
    }

    function sell() external checkUser_ nonReentrant whenNotPaused {
        (uint256 hasBeats, uint256 beatValue, ) = calculateMyBeats(
            msg.sender,
            false
        );
        (uint256 fee, FeeStruct[5] memory feeStruct) = withdrawFee(beatValue);
        require(
            SafeMath.sub(beatValue, fee) > SafeMath.div(1, 10),
            "Amount don't allowed"
        );
        User storage user = users[msg.sender];
        uint256 beatsUsed = hasBeats;
        uint256 newMiners = SafeMath.div(beatsUsed, BEATS_TO_HATCH_1MINERS);
        user.hatcheryMiners = SafeMath.add(user.hatcheryMiners, newMiners);
        user.claimedBeats = 0;
        user.lastHatch = block.timestamp;
        user.checkpoint = block.timestamp;

        marketBeats = SafeMath.add(marketBeats, hasBeats);
        user.withdraw += beatValue;
        uint256 userWithdraw = beatValue;
        if (userWithdrawData[msg.sender].user == address(0)) {
            userWithdrawDataIndex[userWithdrawDataLength] = msg.sender;
            userWithdrawDataLength += 1;
            userWithdrawData[msg.sender].user = msg.sender;
        }
        userWithdrawData[msg.sender].amount += userWithdraw;
        userWithdrawData[msg.sender].referrer = user.referrer;
        // premiumUsersHandle(user, getInvestSumReinvest(msg.sender));
        payFees(feeStruct);
        // payable(msg.sender).transfer(SafeMath.sub(beatValue, fee));
        transferHandler(payable(msg.sender), SafeMath.sub(beatValue, fee));
        emit TotalWithdraw(msg.sender, user.withdraw);
    }

 function premiumUsersHandle(User storage user, uint userWithdraw) private {
              if(userWithdraw >= BNB_TO_PREMIUM5 && !premiumUsers5.contains(msg.sender)) {
            premiumUsers5.add(msg.sender);
            if(user.premiumBonus < premium5Bonus) {
                user.premiumBonus = premium5Bonus;
            }
        } else if(userWithdraw >= BNB_TO_PREMIUM4 && !premiumUsers4.contains(msg.sender)) {
            premiumUsers4.add(msg.sender);
            if(user.premiumBonus < premium4Bonus) {
                user.premiumBonus = premium4Bonus;
            }
        } else if(userWithdraw >= BNB_TO_PREMIUM3 && !premiumUsers3.contains(msg.sender)) {
            premiumUsers3.add(msg.sender);
            if(user.premiumBonus < premium3Bonus) {
                user.premiumBonus = premium3Bonus;
            }
        } else if(userWithdraw >= BNB_TO_PREMIUM2 && !premiumUsers2.contains(msg.sender)) {
            premiumUsers2.add(msg.sender);
            if(user.premiumBonus < premium2Bonus) {
                user.premiumBonus = premium2Bonus;
            }
        } else if(userWithdraw >= BNB_TO_PREMIUM1 && !premiumUsers1.contains(msg.sender)) {
            premiumUsers1.add(msg.sender);
            if(user.premiumBonus < premium1Bonus) {
                user.premiumBonus = premium1Bonus;
            }
        }
    }
    function calculateReinvest() private {
        (uint256 hasBeats, uint256 beatValue, ) = calculateMyBeats(
            msg.sender,
            true
        );
        (uint256 fee, ) = withdrawFee(beatValue);
        require(
            SafeMath.sub(beatValue, fee) > SafeMath.div(1, 10),
            "Amount don't allowed"
        );
        User storage user = users[msg.sender];
        uint256 beatsUsed = hasBeats;
        uint256 newMiners = SafeMath.div(beatsUsed, BEATS_TO_HATCH_1MINERS);
        user.hatcheryMiners = SafeMath.add(user.hatcheryMiners, newMiners);
        user.claimedBeats = 0;
        user.lastHatch = block.timestamp;
        user.checkpoint = block.timestamp;

        marketBeats = SafeMath.add(marketBeats, hasBeats);
        user.reinvest += beatValue;
        uint userWithdraw = beatValue;
        premiumUsersHandle(user,userWithdraw);
        // payFees(feeStruct);
        // payable(msg.sender).transfer(SafeMath.sub(beatValue, fee));
        // transferHandler(payable(msg.sender), SafeMath.sub(beatValue, fee));
        buyHandler(
            users[msg.sender].referrals,
            SafeMath.sub(beatValue, fee),
            false
        );
    }

    function beatsRewards(address adr) external view returns (uint256) {
        uint256 hasBeats = getMyBeats(adr);
        uint256 beatValue = calculateBeatSell(hasBeats);
        return beatValue;
    }

    function referrerCommission(uint256 _amount, uint256 level)
        private
        view
        returns (uint256)
    {
        //return SafeMath.div(SafeMath.mul(_amount, referrerCommissionVal), 100);
        return
            SafeMath.div(
                SafeMath.mul(_amount, REFERRER_PERCENTS[level]),
                PERCENTS_DIVIDER
            );
    }

    function buy(address ref, uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        TOKEN.transferFrom(msg.sender, address(this), amount);
        buyHandler(ref, amount, true);
    }

    function buyHandler(
        address ref,
        uint256 investAmout,
        bool payFee
    ) private {
        User storage user = users[msg.sender];
        if (user.referrals == address(0) && msg.sender != nWallet) {
            if (
                ref == msg.sender ||
                users[ref].referrals == msg.sender ||
                msg.sender == users[ref].referrals
            ) {
                user.referrals = nWallet;
            } else {
                user.referrals = ref;
            }
            if (user.referrals != msg.sender && user.referrals != address(0)) {
                address upline = user.referrals;
                address old = msg.sender;
                for (uint256 i = 0; i < REFERRER_PERCENTS_LENGTH; i++) {
                    if (
                        upline != address(0) &&
                        upline != old &&
                        users[upline].referrals != old
                    ) {
                        users[upline].referrer[i] += 1;
                        old = upline;
                        upline = users[upline].referrals;
                    } else break;
                }
            }
        }

        uint256 beatsBought = calculateBeatBuy(
            investAmout,
            SafeMath.sub(getBalance(), investAmout)
        );
        (uint256 beatsFee, ) = devFee(beatsBought);
        beatsBought = SafeMath.sub(beatsBought, beatsFee);
        if (payFee) {
            (, FeeStruct[5] memory feeStruct) = devFee(investAmout);
            payFees(feeStruct);
        }

        if (user.invest == 0) {
            user.checkpoint = block.timestamp;
            players = SafeMath.add(players, 1);
            if (daysFromInit() < FIRST_USER_THERSHOLD) {
                user.isFirstUser = true;
            }
        }
        user.invest += investAmout;
        user.claimedBeats = SafeMath.add(user.claimedBeats, beatsBought);
        hatchBeats(getMyBeats(msg.sender), user);
        payCommision(user, investAmout);
        totalInvested += investAmout;
    }

    function payCommision(User storage user, uint256 investAmout) private {
        if (user.referrals != msg.sender && user.referrals != address(0)) {
            address upline = user.referrals;
            address old = msg.sender;
            if (upline == address(0)) {
                upline = nWallet;
            }
            for (uint256 i = 0; i < REFERRER_PERCENTS_LENGTH; i++) {
                if (
                    (upline != address(0) &&
                        upline != old &&
                        users[upline].referrals != old) || upline == nWallet
                ) {
                    uint256 amountReferrer = referrerCommission(investAmout, i);
                    users[upline].amountBNBReferrer = SafeMath.add(
                        users[upline].amountBNBReferrer,
                        amountReferrer
                    );

                    users[upline].totalRefDeposits = SafeMath.add(
                        users[upline].totalRefDeposits,
                        investAmout
                    );
                    // payable(upline).transfer(amountReferrer);
                    transferHandler(payable(upline), amountReferrer);
                    upline = users[upline].referrals;
                    old = user.referrals;
                    if (upline == address(0)) {
                        upline = nWallet;
                    }
                } else break;
            }
        }
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        uint256 a = PSN.mul(bs);
        uint256 b = PSNH;

        uint256 c = PSN.mul(rs);
        uint256 d = PSNH.mul(rt);

        uint256 h = c.add(d).div(rt);
        return a.div(b.add(h));
    }

    function calculateBeatSell(uint256 beats) private view returns (uint256) {
        uint256 _cal = calculateTrade(beats, marketBeats, getBalance());
        return _cal;
    }

    function calculateBeatBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketBeats);
    }

    function calculateBeatBuySimple(uint256 eth)
        external
        view
        returns (uint256)
    {
        return calculateBeatBuy(eth, getBalance());
    }

    function devFee(uint256 _amount)
        private
        view
        returns (uint256 _totalFee, FeeStruct[5] memory _feeStruct)
    {
        // return SafeMath.div(SafeMath.mul(_amount, devFeeVal), 100);
        uint256 aFee = SafeMath.div(
            SafeMath.mul(_amount, PWALLET_FEE),
            PERCENTS_DIVIDER
        );
        uint256 nFee = SafeMath.div(
            SafeMath.mul(_amount, NWALLET_FEE),
            PERCENTS_DIVIDER
        );
        uint256 jFee = SafeMath.div(
            SafeMath.mul(_amount, JWALLET_FEE),
            PERCENTS_DIVIDER
        );
        uint256 dFee = SafeMath.div(
            SafeMath.mul(_amount, DEV_FEE),
            PERCENTS_DIVIDER
        );
        uint256 gFee = SafeMath.div(
            SafeMath.mul(_amount, MWALLET_FEE),
            PERCENTS_DIVIDER
        );

        _feeStruct[0] = FeeStruct(pWallet, aFee);
        _feeStruct[1] = FeeStruct(nWallet, nFee);
        _feeStruct[2] = FeeStruct(jWallet, jFee);
        _feeStruct[3] = FeeStruct(devWallet, dFee);
        _feeStruct[4] = FeeStruct(mWallet, gFee);

        _totalFee = aFee;
        _totalFee = SafeMath.add(_totalFee, nFee);
        _totalFee = SafeMath.add(_totalFee, jFee);
        _totalFee = SafeMath.add(_totalFee, dFee);
        _totalFee = SafeMath.add(_totalFee, gFee);

        return (_totalFee, _feeStruct);
    }

    function withdrawFee(uint256 _amount)
        private
        view
        returns (uint256 _totalFee, FeeStruct[5] memory _feeStruct)
    {
        return devFee(_amount);
    }

    function getBalance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function getMyMiners(address adr) external view returns (uint256) {
        User memory user = users[adr];
        return user.hatcheryMiners;
    }

    function getPlayers() external view returns (uint256) {
        return players;
    }

    function getMyBeats(address adr) public view returns (uint256) {
        User memory user = users[adr];
        return SafeMath.add(user.claimedBeats, getBeatsSinceLastHatch(adr));
    }

    function getBeatsSinceLastHatch(address adr) public view returns (uint256) {
        User memory user = users[adr];
        uint256 secondsPassed = min(
            BEATS_TO_HATCH_1MINERS,
            SafeMath.sub(block.timestamp, user.lastHatch)
        );
        return SafeMath.mul(secondsPassed, user.hatcheryMiners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getSellStars(address user_)
        external
        view
        returns (uint256 beatValue)
    {
        uint256 hasBeats = getMyBeats(user_);
        beatValue = calculateBeatSell(hasBeats);
    }

    function getPublicData()
        external
        view
        returns (uint256 _totalInvest, uint256 _balance)
    {
        _totalInvest = totalInvested;
        _balance = getBalance();
    }

    function userData(address user_)
        external
        view
        returns (
            uint256 lastHatch_,
            uint256 rewards_,
            uint256 amountAvailableReinvest_,
            uint256 availableWithdraw_,
            uint256 beatsMiners_,
            address referrals_,
            uint256[REFERRER_PERCENTS_LENGTH] memory referrer,
            uint256 checkpoint,
            uint256 referrerBNB,
            uint256 referrerBEATS,
            uint256 totalRefDeposits
        )
    {
        User memory user = users[user_];
        (, uint256 beatValue, uint256 beats) = calculateMyBeats(user_, false);
        (, amountAvailableReinvest_,) = calculateMyBeats(user_, true);
        lastHatch_ = user.lastHatch;
        referrals_ = user.referrals;
        rewards_ = beats;
        // amountAvailableReinvest_ = beatValue; // SafeMath.sub(beats, beatValue);
        availableWithdraw_ = beatValue;
        beatsMiners_ = getBeatsSinceLastHatch(user_);
        referrer = user.referrer;
        checkpoint = user.checkpoint;
        referrerBNB = user.amountBNBReferrer;
        referrerBEATS = user.amountBEATSReferrer;
        totalRefDeposits = user.totalRefDeposits;
    }

     function premiumUsers(uint level) external view returns (address[] memory) {
        if(level == 1) {
            return premiumUsers1.values();
        } else if(level == 2) {
            return premiumUsers2.values();
        } else if(level == 3) {
            return premiumUsers3.values();
        } else if(level == 4) {
            return premiumUsers4.values();
        } else if(level == 5) {
            return premiumUsers5.values();
        } else {
            return new address[](0);
        }
    }

    function getPremiumUsersLength(uint level) external view returns(uint) {
        if(level == 1) {
            return premiumUsers1.length();
        } else if(level == 2) {
            return premiumUsers2.length();
        } else if(level == 3) {
            return premiumUsers3.length();
        } else if(level == 4) {
            return premiumUsers4.length();
        } else if(level == 5) {
            return premiumUsers5.length();
        } else {
            return 0;
        }
    }

    function getPremiumUsersAt(uint level, uint index) external view returns(address) {
        if(level == 1) {
            return premiumUsers1.at(index);
        } else if(level == 2) {
            return premiumUsers2.at(index);
        } else if(level == 3) {
            return premiumUsers3.at(index);
        } else if(level == 4) {
            return premiumUsers4.at(index);
        } else if(level == 5) {
            return premiumUsers5.at(index);
        }
        else {
            return address(0);
        }
    }


    function payFees(FeeStruct[5] memory _fees) internal {
        for (uint256 i = 0; i < _fees.length; i++) {
            if (_fees[i].amount > 0) {
                // payable(_fees[i].wallet).transfer(_fees[i].amount);
                transferHandler(payable(_fees[i].wallet), _fees[i].amount);
            }
        }
    }

    function buyWhiteList() external payable nonReentrant {
        require(!whiteList[msg.sender], "You already have a whitelist");
        uint256 amount = contractsLibrary.getBusdToBNBToToken(
            address(TOKEN),
            priceWhiteList
        );
        TOKEN.transferFrom(msg.sender, address(this), amount);
        transferHandler(nWallet2, amount);
        addWhiteList(msg.sender);
    }

    function addToWhiteList(address adr) external onlyWhitelistAdmin {
        addWhiteList(adr);
    }

    function setWhitelist(address[] memory _whitelist, bool _value)
        external
        onlyWhitelistAdmin
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whiteList[_whitelist[i]] = _value;
            emit WhiteListSet(_whitelist[i], _value);
        }
    }

    function addWhiteList(address adr) private {
        whiteList[adr] = true;
        emit WhiteListSet(adr, true);
    }

    function removeToWhiteList(address adr) external onlyWhitelistAdmin {
        whiteList[adr] = false;
        emit WhiteListSet(adr, false);
    }

    function getDate() external view returns (uint256) {
        return block.timestamp;
    }

    function buySecure() external payable nonReentrant {
        require(!secureUsers.contains(msg.sender), "You already have a secure");
        uint256 amount = contractsLibrary.getBusdToBNBToToken(
            address(TOKEN),
            priceSecure
        );
        TOKEN.transferFrom(msg.sender, address(this), amount);
        secureUsers.add(msg.sender);
        uint256 feeToNwallet = amount.mul(secureToNwallet).div(
            PERCENTS_DIVIDER
        );
        uint256 feeToJwallet = amount.mul(secureToJwallet).div(
            PERCENTS_DIVIDER
        );
        uint256 feeToDev = amount.mul(secureToDev).div(PERCENTS_DIVIDER);
        transferHandler(nWallet2, feeToNwallet);
        transferHandler(jWallet, feeToJwallet);
        transferHandler(devWallet, feeToDev);
    }

    function secureUsersLegth() external view returns (uint256) {
        return secureUsers.length();
    }

    function secureUsersArray() external view returns (address[] memory) {
        return secureUsers.values();
    }

    function hasBuySecure(address adr) external view returns (bool) {
        return secureUsers.contains(adr);
    }

    function secureUsersInterval(uint256 from, uint256 to)
        external
        view
        returns (address[] memory)
    {
        uint256 length = to - from;
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = secureUsers.at(from + i);
        }
        return result;
    }

    function getMyBonus(address adr, bool isReinvest)
        public
        view
        returns (uint256 multiplier, uint256 divider)
    {
        divider = 1000;
        multiplier = 250;

        if (!isReinvest) {
            User memory user = users[adr];
            if (user.isFirstUser) {
                uint256 _daysFromInit = daysFromInit();
                if (_daysFromInit < penalization1day) {
                    multiplier = penalization1dayPercent;
                } else if (_daysFromInit < penalization2day) {
                    multiplier = penalization2dayPercent;
                } else if (_daysFromInit < penalization3day) {
                    multiplier = penalization3dayPercent;
                }
            }
        }

        if (whiteList[adr]) {
            multiplier *= 2;
        } else if (getBalance() < balanceLimit) {
            multiplier /= 2;
        }
        
        uint256 beats_ = getMyBeats(adr);
        uint beatValue_ = calculateBeatSell(SafeMath.div(SafeMath.mul(beats_, multiplier), divider));
        uint userWithdraw = getInvestSumReinvest(adr);
        beatValue_ += userWithdraw;

        uint bonusPercent = 0;
        if(beatValue_ >= BNB_TO_PREMIUM5) {
            bonusPercent = premium5Bonus;
        } else if(beatValue_ >= BNB_TO_PREMIUM4) {
            bonusPercent = premium4Bonus;
        } else if(beatValue_ >= BNB_TO_PREMIUM3) {
            bonusPercent = premium3Bonus;
        } else if(beatValue_ >= BNB_TO_PREMIUM2) {
            bonusPercent = premium2Bonus;
        } else if(beatValue_ >= BNB_TO_PREMIUM1) {
            bonusPercent = premium1Bonus;
        }

        if(users[adr].premiumBonus > bonusPercent) {
            bonusPercent = users[adr].premiumBonus;
         }

        multiplier = SafeMath.add(multiplier, bonusPercent);


        if (multiplier > divider) {
            multiplier = divider;
        }
    }

    function setWhitelistAdmin(address[] memory adr, bool _add)
        external
        checkOwner_
    {
        if (_add) {
            for (uint256 i = 0; i < adr.length; i++) {
                whiteListAdmin.add(adr[i]);
            }
        } else {
            for (uint256 i = 0; i < adr.length; i++) {
                whiteListAdmin.remove(adr[i]);
            }
        }
    }

    function transferHandler(address adr, uint256 amount) private {
        if (amount > getBalance()) {
            amount = getBalance();
        }
        TOKEN.transfer(adr, amount);
    }

    function getUserWithdrawData()
        external
        view
        returns (UserWithdrawData[] memory)
    {
        UserWithdrawData[] memory result = new UserWithdrawData[](
            userWithdrawDataLength
        );
        for (uint256 i = 0; i < userWithdrawDataLength; i++) {
            result[i] = userWithdrawData[userWithdrawDataIndex[i]];
        }
        return result;
    }

    function UserWithdrawDataRange(uint256 limit, uint256 offset)
        external
        view
        returns (UserWithdrawData[] memory)
    {
        UserWithdrawData[] memory result = new UserWithdrawData[](limit);
        for (uint256 i = 0; i < limit; i++) {
            result[i] = userWithdrawData[userWithdrawDataIndex[i + offset]];
        }
        return result;
    }

    function getInvestSumReinvest(address adr) public view returns (uint256) {
        return users[adr].withdraw + users[adr].reinvest;
    }
}