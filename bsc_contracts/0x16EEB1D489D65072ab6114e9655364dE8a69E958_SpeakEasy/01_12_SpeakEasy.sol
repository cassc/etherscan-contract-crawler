///@dev SPDX-License-Identifier: MIT

library Math {
    function add8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0 && a != 0);
        return a ** b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ICocktailNFT is IERC721 {
    function minted() external view returns (uint256);

    function safeMint(address to) external;
}

interface IFounderNFT is IERC721 {}

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpeakEasy is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        SILVER_ADDRESS = 0xaC256FB4e7D7D2a882A4c2BE327a031b9cE78FEE;
        EMP_SILVER_ADDRESS = 0xc78BB9c34CdF873FcCF787AF8d84DE42af45c540;
        GOLD_ADDRESS = 0x284744e6D901e5aB25d918dD1dF3Eb0C2f1dF0a4;
        PLATINUM_ADDRESS = address(0);
        GT_ADDRESS = 0x77Fe17f2DFBBE22F40F017F104AfecE49bCCF006;
        MARGARITA_ADDRESS = 0x62755Fec3c20ed2CbC1f4DcE19dBc13fc4492e60;
        BLOODYMARY_ADDRESS = 0x40551fF067bB72266Cfc4f00c95b243d98cA3483;
        PINACOLADA_ADDRESS = 0x0Ce0fFFB109255cD610eF53d4f8Ec0AC7131028D;
        IRISHCOFFEE_ADDRESS = 0xEd35aC3c7f2DfAD24DF217A153F3609e20110fd6;
        OLDFASHIONED_ADDRESS = 0x7Ab0424183fc12585D44Bee81429819473Bbf026;
        FOUNDER_ADDRESS = 0x7baB11C737Aea754E23aefaBeA0213c931b4DE6b;
        MINTING_CONTRACT_ADDRESS = 0x26749cd89671b289F225Bc917A971E11553333f3;

        DEV_ADDRESS = 0xbab5B268bBa1E1ED488e5C91b6df3966bC8d8EeE;
        STAFF_ADDRESS = 0x266ad1b5BC8A484Be97B20632A1fAf36c09b6EE7;
        OPERATION_ADDRESS = 0x90849d08168D8D665cb45ae4BD3f9E6037C6E365;
        BANK_ADDRESS = 0xce238AddA1C558f213469d442128739a876fBB3d;
        OWNER_ADDRESS = _msgSender();
        _dev = payable(DEV_ADDRESS);
        _staff = payable(STAFF_ADDRESS);
        _bank = payable(BANK_ADDRESS);
        _owner = payable(OWNER_ADDRESS);
        SECONDS_PER_DAY = 86400;
        COMMON_POT_FEE = 5;
        REINVEST_POT_FEE = 3;
        STAFF_FEE = 2;
        DEV_FEE = 10;
        REF_BONUS = 5;
        MIN_DEPOSIT = 100000000000000000; ///@dev 0.1 BNB
        MAX_WEEKLY_REWARDS_IN_BNB = 2000000000000000000; ///@dev 2 BNB
        MAX_TOTAL_DEPOSIT_SIZE = 20000000000000000000; ///@dev 20 BNB
        MAX_REFS = 25;

        _EMPsilverMKCNFT = ICocktailNFT(EMP_SILVER_ADDRESS);
        _silverMKCNFT = ICocktailNFT(SILVER_ADDRESS);
        _goldMKCNFT = ICocktailNFT(GOLD_ADDRESS);
        _platinumMKCNFT = ICocktailNFT(PLATINUM_ADDRESS);
        _bloodyMaryNft = ICocktailNFT(BLOODYMARY_ADDRESS);
        _ginAndTonicNft = ICocktailNFT(GT_ADDRESS);
        _irishCoffeeNft = ICocktailNFT(IRISHCOFFEE_ADDRESS);
        _margaritaNft = ICocktailNFT(MARGARITA_ADDRESS);
        _oldFashionedNft = ICocktailNFT(OLDFASHIONED_ADDRESS);
        _pinaColadaNft = ICocktailNFT(PINACOLADA_ADDRESS);
        _founderNft = IFounderNFT(FOUNDER_ADDRESS);

        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;

        investorsCapEnabled = false;
        investorsCap = 1000;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    using Math for uint256;

    ICocktailNFT public _EMPsilverMKCNFT;
    ICocktailNFT public _silverMKCNFT;
    ICocktailNFT public _goldMKCNFT;
    ICocktailNFT public _platinumMKCNFT;
    ICocktailNFT public _bloodyMaryNft;
    ICocktailNFT public _ginAndTonicNft;
    ICocktailNFT public _irishCoffeeNft;
    ICocktailNFT public _margaritaNft;
    ICocktailNFT public _oldFashionedNft;
    ICocktailNFT public _pinaColadaNft;
    IFounderNFT public _founderNft;

    address private MINTING_CONTRACT_ADDRESS;
    address private EMP_SILVER_ADDRESS;
    address private SILVER_ADDRESS;
    address private GOLD_ADDRESS;
    address private PLATINUM_ADDRESS;
    address private GT_ADDRESS;
    address private MARGARITA_ADDRESS;
    address private BLOODYMARY_ADDRESS;
    address private PINACOLADA_ADDRESS;
    address private IRISHCOFFEE_ADDRESS;
    address private OLDFASHIONED_ADDRESS;
    address private FOUNDER_ADDRESS;

    address private DEV_ADDRESS;
    address private STAFF_ADDRESS;
    address private OPERATION_ADDRESS;
    address private BANK_ADDRESS;
    address private OWNER_ADDRESS;
    address payable internal _dev;
    address payable internal _staff;
    address payable internal _bank;
    address payable internal _owner;

    uint32 private SECONDS_PER_DAY;
    uint8 private COMMON_POT_FEE;
    uint8 private REINVEST_POT_FEE;
    uint8 private STAFF_FEE;
    uint16 private DEV_FEE;
    uint8 private REF_BONUS;
    uint256 private MIN_DEPOSIT;
    uint256 private MAX_WEEKLY_REWARDS_IN_BNB;
    uint256 private MAX_TOTAL_DEPOSIT_SIZE;
    uint32 private MAX_REFS;

    uint256 public totalUsers;
    bool public investorsCapEnabled;
    uint256 public investorsCap;

    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

    struct User {
        address adr;
        uint256 lastActionAt;
        uint256 lastDepositAt;
        uint256 lastClaimAt;
        uint256 lastReinvestAt;
        uint256 tvl;
        address upline;
        bool hasReferred;
        address[] referrals;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
        uint256 reinvestBonusReward;
    }

    mapping(address => User) internal users;

    event EmitBought(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 bnbBefore,
        uint256 bnbAfter
    );
    event EmitReinvested(
        address indexed adr,
        address indexed ref,
        uint256 bnbBefore,
        uint256 bnbAfter
    );
    event EmitClaimed(
        address indexed adr,
        uint256 bnbToClaim,
        uint256 bnbToClaimBeforeFee
    );
    event LogBytes(bytes data);

    modifier onlyTeam() {
        require(msg.sender == OPERATION_ADDRESS || msg.sender == OWNER_ADDRESS);
        _;
    }

    function user(address adr) public view returns (User memory) {
        return users[adr];
    }

    function setInvestorsCap(
        bool enable,
        uint256 cap
    ) public onlyTeam returns (bool enabled, uint256 capSize) {
        investorsCapEnabled = enable;
        investorsCap = cap;
        return (investorsCapEnabled, investorsCap);
    }

    function minDeposit(uint256 value, address adr) public view returns (bool) {
        if (hasMembership(adr)) {
            return true;
        }
        return value >= MIN_DEPOSIT;
    }

    function deposit(address ref) public payable nonReentrant {
        require(
            hasInvested(msg.sender) == false,
            "This can only be called as the initial deposit"
        );
        require(
            investorsCapEnabled == false ||
                (investorsCapEnabled && totalUsers < investorsCap),
            "New investors are not allowed at this moment"
        );
        handleDeposit(msg.sender, msg.value, ref);
    }

    function handleDeposit(address sender, uint256 value, address ref) private {
        User storage signer = users[sender];
        User storage upline = users[ref];
        require(
            minDeposit(value, sender),
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            Math.add(signer.totalDeposit, value) <= MAX_TOTAL_DEPOSIT_SIZE,
            "Max total deposit reached"
        );
        require(
            ref == address(0) || ref == sender || hasInvested(upline.adr),
            "Ref must be investor to set as upline"
        );
        require(
            maxReferralsReached(ref) == false,
            "Ref has too many referrals."
        );

        signer.adr = sender;
        uint256 tvlBefore = signer.tvl;

        uint256 potFee = percentFromAmount(value, COMMON_POT_FEE);
        uint256 devFee = percentFromAmount(potFee, DEV_FEE);
        potFee = potFee.sub(devFee);
        uint256 staffFee = percentFromAmount(value, STAFF_FEE);
        uint256 totalBnbFee = potFee.add(staffFee).add(devFee);

        uint256 bnbValue = Math.sub(value, totalBnbFee);
        signer.tvl = Math.add(signer.tvl, bnbValue);

        uint256 toBank = Math.div(bnbValue, 2);

        if (
            !signer.hasReferred &&
            ref != sender &&
            ref != address(0) &&
            hasMembership(ref)
        ) {
            signer.upline = ref;
            signer.hasReferred = true;

            upline.referrals.push(sender);
            if (hasInvested(signer.adr) == false) {
                uint256 refBonus = percentFromAmount(value, REF_BONUS);
                upline.tvl = upline.tvl.add(refBonus);
            }
        }

        if (hasInvested(signer.adr) == false) {
            signer.firstDeposit = block.timestamp;
            totalUsers++;
        }

        signer.totalDeposit = Math.add(signer.totalDeposit, value);
        signer.lastActionAt = block.timestamp;
        signer.lastDepositAt = block.timestamp;

        _bank.transfer(toBank);
        sendFees(staffFee, devFee);

        emit EmitBought(sender, ref, value, tvlBefore, signer.tvl);
    }

    function teamAddresses()
        public
        view
        returns (address operation, address staff, address owner, address bank)
    {
        return (OPERATION_ADDRESS, STAFF_ADDRESS, OWNER_ADDRESS, BANK_ADDRESS);
    }

    function reinvest() public payable nonReentrant {
        User storage signer = users[msg.sender];
        require(hasInvested(signer.adr), "Must be invested to reinvest");
        require(
            canClaimOrReinvest(signer.adr),
            "7 days haven't passed since last action"
        );

        uint256 tvlBefore = signer.tvl;
        uint256 bnbRewardsBeforeFee = rewards(signer.adr);

        uint256 potFee = percentFromAmount(
            bnbRewardsBeforeFee,
            REINVEST_POT_FEE
        );
        uint256 devFee = percentFromAmount(potFee, DEV_FEE);
        potFee = potFee.sub(devFee);
        uint256 staffFee = percentFromAmount(bnbRewardsBeforeFee, STAFF_FEE);
        uint256 totalBnbFee = potFee.add(staffFee).add(devFee);

        uint256 bnbRewards = bnbRewardsBeforeFee.sub(totalBnbFee);

        signer.tvl = Math.add(signer.tvl, bnbRewards);
        signer.lastActionAt = block.timestamp;
        signer.lastReinvestAt = block.timestamp;

        signer.totalDeposit = Math.add(signer.totalDeposit, bnbRewards);

        signer.reinvestBonusReward = signer.reinvestBonusReward.add(10000); ///@dev/@dev adding 0.01% to daily reward

        emit EmitReinvested(msg.sender, signer.upline, tvlBefore, signer.tvl);

        if (msg.value > 0) {
            handleDeposit(msg.sender, msg.value, address(0));
        }

        sendFees(staffFee, devFee);
    }

    function claim() public nonReentrant {
        User storage signer = users[msg.sender];
        require(hasInvested(signer.adr), "Must be invested to claim");
        require(
            canClaimOrReinvest(signer.adr),
            "7 days haven't passed since last action"
        );
        require(
            maxPayoutReached(signer.adr) == false,
            "You have reached max payout"
        );

        uint256 rewardsBeforeFee = rewards(signer.adr);

        uint256 potFee = percentFromAmount(rewardsBeforeFee, COMMON_POT_FEE);
        uint256 devFee = percentFromAmount(potFee, DEV_FEE);
        potFee = potFee.sub(devFee);
        uint256 staffFee = percentFromAmount(rewardsBeforeFee, STAFF_FEE);
        uint256 totalBnbFee = potFee.add(staffFee).add(devFee);

        uint256 bnbToClaim = Math.sub(rewardsBeforeFee, totalBnbFee);

        if (
            Math.add(rewardsBeforeFee, signer.totalPayout) >=
            maxPayout(signer.adr)
        ) {
            bnbToClaim = Math.sub(maxPayout(signer.adr), signer.totalPayout);
            signer.totalPayout = maxPayout(signer.adr);
        } else {
            signer.totalPayout = Math.add(signer.totalPayout, bnbToClaim);
        }

        signer.lastActionAt = block.timestamp;
        signer.lastClaimAt = block.timestamp;

        sendFees(staffFee, devFee);
        payable(msg.sender).transfer(bnbToClaim);

        emit EmitClaimed(msg.sender, bnbToClaim, rewardsBeforeFee);
    }

    function hasMembership(address adr) public view returns (bool) {
        return
            _silverMKCNFT.balanceOf(adr) > 0 ||
            _goldMKCNFT.balanceOf(adr) > 0 ||
            _EMPsilverMKCNFT.balanceOf(adr) > 0;
    }

    function maxReferralsReached(
        address refAddress
    ) public view returns (bool) {
        return users[refAddress].referrals.length >= MAX_REFS;
    }

    function sendFees(uint256 staffFee, uint256 devFee) private {
        _dev.transfer(devFee);
        _staff.transfer(staffFee);
    }

    function maxPayoutReached(address adr) public view returns (bool) {
        return users[adr].totalPayout >= maxPayout(adr);
    }

    function maxPayout(address adr) public view returns (uint256) {
        return Math.mul(users[adr].totalDeposit, 3);
    }

    function hasInvested(address adr) public view returns (bool) {
        return users[adr].firstDeposit != 0;
    }

    function tvl(address adr) public view returns (uint256) {
        return users[adr].tvl;
    }

    function referrals(
        address adr
    ) public view returns (address[] memory downlines) {
        return users[adr].referrals;
    }

    function percentFromAmount(
        uint256 amount,
        uint256 fee
    ) private pure returns (uint256) {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function canClaimOrReinvest(address adr) public view returns (bool) {
        return secondsSinceLastAction(adr) >= Math.mul(7, SECONDS_PER_DAY);
    }

    function rewards(address adr) public view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastAction(adr);
        uint256 dailyRewardFactor = dailyRewards(adr);
        uint256 bnbRewarded = calcRewards(
            secondsPassed,
            dailyRewardFactor,
            adr
        );

        if (bnbRewarded >= MAX_WEEKLY_REWARDS_IN_BNB) {
            return MAX_WEEKLY_REWARDS_IN_BNB;
        }

        return bnbRewarded;
    }

    function secondsSinceLastAction(
        address adr
    ) private view returns (uint256) {
        return
            Math.min(
                Math.mul(SECONDS_PER_DAY, 7),
                Math.sub(block.timestamp, users[adr].lastActionAt)
            );
    }

    function dailyRewards(address adr) public view returns (uint256) {
        uint256 daily = rewardsFromSilverSet(adr);
        if (_goldMKCNFT.balanceOf(adr) > 0) {
            daily = rewardsFromGoldSet(adr);
        }
        return Math.min(1500000, daily);
    }

    function rewardsFromSilverSet(address adr) private view returns (uint256) {
        if (hasMembership(adr) == false)
            return Math.add(250000, users[adr].reinvestBonusReward); ///@dev 0.25% + reinvest bonus

        uint256 baseDaily = 500000; ///@dev 0.5%

        if (_founderNft.balanceOf(adr) > 0) {
            baseDaily = baseDaily.add(100000);
        }

        if (_oldFashionedNft.balanceOf(adr) > 0)
            return
                Math.add(
                    baseDaily.add(1000000),
                    users[adr].reinvestBonusReward
                ); ///@dev 1% + reinvest bonus
        if (_irishCoffeeNft.balanceOf(adr) > 0)
            return
                Math.add(baseDaily.add(800000), users[adr].reinvestBonusReward); ///@dev 0.8% + reinvest bonus
        if (_pinaColadaNft.balanceOf(adr) > 0)
            return
                Math.add(baseDaily.add(650000), users[adr].reinvestBonusReward); ///@dev 0.65% + reinvest bonus
        if (_bloodyMaryNft.balanceOf(adr) > 0)
            return
                Math.add(baseDaily.add(500000), users[adr].reinvestBonusReward); ///@dev 0.5% + reinvest bonus
        if (_margaritaNft.balanceOf(adr) > 0)
            return
                Math.add(baseDaily.add(350000), users[adr].reinvestBonusReward); ///@dev 0.35% + reinvest bonus
        if (_ginAndTonicNft.balanceOf(adr) > 0)
            return
                Math.add(baseDaily.add(250000), users[adr].reinvestBonusReward); ///@dev 0.25% + reinvest bonus

        return Math.add(baseDaily, users[adr].reinvestBonusReward); ///@dev (0.5% or 0.6%) + reinvest bonus
    }

    function rewardsFromGoldSet(address adr) private view returns (uint256) {
        if (hasMembership(adr) == false)
            return Math.add(250000, users[adr].reinvestBonusReward); ///@dev 0.25% + reinvest bonus

        return Math.add(750000, users[adr].reinvestBonusReward); ///@dev 0.75% + reinvest bonus
    }

    function calcRewards(
        uint256 secondsPassed,
        uint256 dailyRewardFactor,
        address adr
    ) private view returns (uint256) {
        uint256 rewardsPerDay = percentFromAmount(
            Math.mul(users[adr].tvl, 1000),
            dailyRewardFactor
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 bnbRewarded = Math.mul(rewardsPerSecond, secondsPassed);
        bnbRewarded = Math.div(bnbRewarded, 1000000000);
        return bnbRewarded;
    }
}