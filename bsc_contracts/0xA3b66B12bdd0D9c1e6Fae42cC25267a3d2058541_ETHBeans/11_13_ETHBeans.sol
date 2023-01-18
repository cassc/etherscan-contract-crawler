/*

ETH Beans - Thoreum ecosystem.
https://ETHBeans.com

*/

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Pausable.sol";
import "./AuthUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a**b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

pragma solidity 0.8.4;


contract ETHBeans is Initializable, UUPSUpgradeable, Pausable, AuthUpgradeable, ReentrancyGuardUpgradeable {
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        MARKETING_ADDRESS = 0x8Ad9CB111d886dBAbBbf232c9A1339B13cB168F8;
        BANK_ADDRESS = 0x1DA680B24FbCe0EdD51b7784d0c6044B6F1a5DB3; // THOREUM BANK to distribute rewards to lockers
        TOKEN_MAIN = 0x4004e3df76d099615790342C34DAe5338826d71f; //THOREUM-ETH LP

        BNB_PER_BEAN = 1000000000000;
        SECONDS_PER_DAY = 86400;
        DEPOSIT_FEE = 8;
        WITHDRAWAL_FEE = 8;
        MARKETING_FEE = 50;
        BANK_FEE = 50;

        FIRST_DEPOSIT_REF_BONUS = 5;
        MIN_DEPOSIT = 200000000000000000; // 0.2 LP = 12 usd
        MIN_BAKE    = 200000000000000000; // 0.2 LP = 12 usd
        MAX_WALLET_TVL_IN_BNB     = 500000000000000000000; // 500 LP = $30000
        MAX_DAILY_REWARDS_IN_BNB  = 25000000000000000000; // 25 LP = $1500
        MIN_REF_DEPOSIT_FOR_BONUS = 2500000000000000000; // 2.5 LP = $150

        WHALE_TAX_MINIMUM  = 100; //1 % TVL and below is not a whale
        WHALE_TAX_MULTIPLIER = 5;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    using Math for uint256;

    address public TOKEN_MAIN;
    address public MARKETING_ADDRESS;
    address public BANK_ADDRESS;

    uint136 private BNB_PER_BEAN;
    uint32 private SECONDS_PER_DAY;
    uint8 public DEPOSIT_FEE;

    uint8 public BANK_FEE;
    uint8 public WITHDRAWAL_FEE;
    uint16 public MARKETING_FEE;
    uint8 public FIRST_DEPOSIT_REF_BONUS;
    uint256 public MIN_DEPOSIT;
    uint256 public MIN_BAKE;
    uint256 public MAX_WALLET_TVL_IN_BNB;
    uint256 public MAX_DAILY_REWARDS_IN_BNB;
    uint256 public MIN_REF_DEPOSIT_FOR_BONUS;


    mapping(uint256 => address) public bakerAddress;
    uint256 public totalBakers;
    mapping(address => Baker) internal bakers;

    uint256 public constant launch = 1674741600; // 26 Jan 2 PM UTC
    uint256 constant percentdiv = 10000;
    uint256 public WHALE_TAX_MINIMUM;
    uint256 public WHALE_TAX_MULTIPLIER;
    uint256 public constant PUNISH_PER_ATE = 5000;

    struct Baker {
        address adr;
        uint256 beans;
        uint256 bakedAt;
        uint256 ateAt;
        address upline;
        bool hasReferred;
        address[] referrals;
        address[] bonusEligibleReferrals;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
        uint256 totalAte;
    }


    event EmitBoughtBeans(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitBaked(
        address indexed adr,
        address indexed ref,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitAte(
        address indexed adr,
        uint256 bnbToEat,
        uint256 beansBeforeFee
    );

    function user(address adr) public view returns (Baker memory) {
        return bakers[adr];
    }

    function buyBeans(address ref, uint256 _amount) public {
        buyBeansFor(msg.sender, ref, _amount);
    }

    function buyBeansFor(address _user, address ref, uint256 _amount) public nonReentrant whenNotPaused {
        Baker storage baker = bakers[_user];
        Baker storage upline = bakers[ref];

        require(
            _amount >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            Math.add(baker.totalDeposit, _amount) <= MAX_WALLET_TVL_IN_BNB,
            "Max total deposit reached"
        );
        IERC20Upgradeable(TOKEN_MAIN).transferFrom(msg.sender, address(this), _amount);
        baker.adr = _user;
        uint256 beansFrom = baker.beans;

        uint256 totalBnbFee = percentFromAmount(_amount, DEPOSIT_FEE);
        uint256 bnbValue = Math.sub(_amount, totalBnbFee);
        uint256 beansBought = bnbToBeans(bnbValue);

        uint256 totalBeansBought = addBeans(baker.adr, beansBought);
        baker.beans = totalBeansBought;

        if (
            !baker.hasReferred &&
        ref != _user &&
        ref != address(0) &&
        baker.upline != _user &&
        hasInvested(upline.adr)
        ) {
            baker.upline = ref;
            baker.hasReferred = true;

            upline.referrals.push(_user);
            if (hasInvested(baker.adr) == false) {
                uint256 refBonus = percentFromAmount(
                    bnbToBeans(_amount),
                    FIRST_DEPOSIT_REF_BONUS
                );
                upline.beans = addBeans(upline.adr, refBonus);
            }
        }

        if (hasInvested(baker.adr) == false) {
            baker.firstDeposit = block.timestamp;
            bakerAddress[totalBakers] = baker.adr;
            totalBakers++;
        }

        baker.totalDeposit = Math.add(baker.totalDeposit, _amount);
        if (
            baker.hasReferred &&
            baker.totalDeposit >= MIN_REF_DEPOSIT_FOR_BONUS &&
            refExists(baker.adr, baker.upline) == false
        ) {
            upline.bonusEligibleReferrals.push(_user);
        }

        sendFees(totalBnbFee, 0);
        handleBake(_user, false);

        emit EmitBoughtBeans(_user, ref, _amount, beansFrom, baker.beans);
    }

    function refExists(
        address ref,
        address upline
    ) private view returns (bool) {
        for (
            uint256 i = 0;
            i < bakers[upline].bonusEligibleReferrals.length;
            i++
        ) {
            if (bakers[upline].bonusEligibleReferrals[i] == ref) {
                return true;
            }
        }

        return false;
    }

    function sendFees(uint256 totalFee, uint256 giveAway) private {
        uint256 marketing = percentFromAmount(totalFee, MARKETING_FEE);
        uint256 bank = percentFromAmount(totalFee, BANK_FEE);

        IERC20Upgradeable(TOKEN_MAIN).transfer(MARKETING_ADDRESS, marketing);
        IERC20Upgradeable(TOKEN_MAIN).transfer(BANK_ADDRESS, bank);

        if (giveAway > 0) {
            IERC20Upgradeable(TOKEN_MAIN).transfer(BANK_ADDRESS, giveAway);
        }
    }

    function handleBake(address _user,bool onlyRebaking) private {
        Baker storage baker = bakers[_user];
        require(maxTvlReached(baker.adr) == false, "Total wallet TVL reached");
        require(hasInvested(baker.adr), "Must be invested to bake");
        if (onlyRebaking == true) {
            require(
                beansToBnb(rewardedBeans(baker.adr)) >= MIN_BAKE,
                "Rewards must be equal or higher than MIN_BAKE to bake"
            );
        }

        uint256 beansFrom = baker.beans;
        uint256 beansFromRewards = percentFromAmount(rewardedBeans(baker.adr), 100 - WITHDRAWAL_FEE - DEPOSIT_FEE);

        uint256 totalBeans = addBeans(baker.adr, beansFromRewards);
        baker.beans = totalBeans;
        baker.bakedAt = block.timestamp;

        emit EmitBaked(_user, baker.upline, beansFrom, baker.beans);
    }

    function bake() public nonReentrant {
        handleBake(msg.sender,true);
    }

    function eat() public nonReentrant {
        require(started(),"pool not launched");
        Baker storage baker = bakers[msg.sender];
        require(hasInvested(baker.adr), "Must be invested to eat");
        require(
            maxPayoutReached(baker.adr) == false,
            "You have reached max payout"
        );

        uint256 beansBeforeFee = rewardedBeans(baker.adr);
        uint256 beansInBnbBeforeFee = beansToBnb(beansBeforeFee);

        uint256 totalBnbFee = percentFromAmount(
            beansInBnbBeforeFee,
            WITHDRAWAL_FEE
        );

        uint256 bnbToEat = Math.sub(beansInBnbBeforeFee, totalBnbFee);
        uint256 forGiveAway = calcGiveAwayAmount(baker.adr, bnbToEat);
        bnbToEat = addWithdrawalTaxes(baker.adr, bnbToEat);

        if (
            Math.add(beansInBnbBeforeFee, baker.totalPayout) >=
            maxPayout(baker.adr)
        ) {
            bnbToEat = Math.sub(maxPayout(baker.adr), baker.totalPayout);
            baker.totalPayout = maxPayout(baker.adr);
        } else {
            uint256 afterTax = addWithdrawalTaxes(
                baker.adr,
                beansInBnbBeforeFee
            );
            baker.totalPayout = Math.add(baker.totalPayout, afterTax);
        }

        baker.ateAt = block.timestamp;
        baker.bakedAt = block.timestamp;
        baker.totalAte++;

        sendFees(totalBnbFee, forGiveAway);
        IERC20Upgradeable(TOKEN_MAIN).transfer(msg.sender, bnbToEat);

        emit EmitAte(msg.sender, bnbToEat, beansBeforeFee);
    }

    function maxPayoutReached(address adr) public view returns (bool) {
        return bakers[adr].totalPayout >= maxPayout(adr);
    }

    function maxPayout(address adr) public view returns (uint256) {
        return Math.mul(bakers[adr].totalDeposit, 3);
    }

    function addWithdrawalTaxes(
        address adr,
        uint256 bnbWithdrawalAmount
    ) private view returns (uint256) {
        return
        percentFromAmount(
            bnbWithdrawalAmount,
            Math.sub(100, hasBeanTaxed(adr))
        );
    }

    function calcGiveAwayAmount(
        address adr,
        uint256 bnbWithdrawalAmount
    ) private view returns (uint256) {
        return (percentFromAmount(bnbWithdrawalAmount, hasBeanTaxed(adr)));
    }

    function hasBeanTaxed(address adr) public view returns (uint256) {
        uint256 daysPassed = daysSinceLastEat(adr);
        uint256 lastDigit = daysPassed % 10;
        if (lastDigit <= 0) return 90;
        if (lastDigit <= 1) return 80;
        if (lastDigit <= 2) return 70;
        if (lastDigit <= 3) return 60;
        if (lastDigit <= 4) return 50;
        if (lastDigit <= 5) return 40;
        if (lastDigit <= 6) return 30;
        if (lastDigit <= 7) return 20;
        if (lastDigit <= 8) return 10;
        return 0;
    }

    function secondsSinceLastEat(address adr) public view returns (uint256) {
        if (!started()) return 0;
        uint256 lastAteOrFirstDeposit = bakers[adr].ateAt;
        if (lastAteOrFirstDeposit == 0) {
            lastAteOrFirstDeposit = bakers[adr].firstDeposit;
        }

        if (lastAteOrFirstDeposit < launch) lastAteOrFirstDeposit = launch;

        uint256 secondsPassed = Math.sub(
            block.timestamp,
            lastAteOrFirstDeposit
        );

        return secondsPassed;
    }

    function userBonusEligibleReferrals(
        address adr
    ) public view returns (address[] memory) {
        return bakers[adr].bonusEligibleReferrals;
    }

    function userReferrals(address adr) public view returns (address[] memory) {
        return bakers[adr].referrals;
    }

    function daysSinceLastEat(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastEat(adr);
        return Math.div(secondsPassed, SECONDS_PER_DAY);
    }

    function addBeans(
        address adr,
        uint256 beansToAdd
    ) private view returns (uint256) {
        uint256 totalBeans = Math.add(bakers[adr].beans, beansToAdd);
        uint256 maxBeans = bnbToBeans(MAX_WALLET_TVL_IN_BNB);
        if (totalBeans >= maxBeans) {
            return maxBeans;
        }
        return totalBeans;
    }

    function maxTvlReached(address adr) public view returns (bool) {
        return bakers[adr].beans >= bnbToBeans(MAX_WALLET_TVL_IN_BNB);
    }

    function hasInvested(address adr) public view returns (bool) {
        return bakers[adr].firstDeposit != 0;
    }

    function bnbRewards(address adr) public view returns (uint256) {
        uint256 beansRewarded = rewardedBeans(adr);
        uint256 bnbinWei = beansToBnb(beansRewarded);
        return bnbinWei;
    }

    function bnbTvl(address adr) public view returns (uint256) {
        uint256 bnbinWei = beansToBnb(bakers[adr].beans);
        return bnbinWei;
    }

    function beansToBnb(uint256 beansToCalc) public view returns (uint256) {
        uint256 bnbInWei = Math.mul(beansToCalc, BNB_PER_BEAN);
        return bnbInWei;
    }

    function bnbToBeans(uint256 bnbInWei) public view returns (uint256) {
        uint256 beansFromBnb = Math.div(bnbInWei, BNB_PER_BEAN);
        return beansFromBnb;
    }

    function percentFromAmount(
        uint256 amount,
        uint256 fee
    ) private pure returns (uint256) {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function contractBalance() public view returns (uint256) {
        return IERC20Upgradeable(TOKEN_MAIN).balanceOf(address(this));
    }

    function dailyReward(address adr) public view returns (uint256) {
        uint256 referralsCount = bakers[adr].bonusEligibleReferrals.length;
        if (referralsCount < 10) return 30000;
        if (referralsCount < 25) return (35000);
        if (referralsCount < 50) return (40000);
        if (referralsCount < 100) return (45000);
        if (referralsCount < 150) return (50000);
        if (referralsCount < 250) return (55000);
        return 60000;
    }

    function dailyPunish(address adr) public view returns (uint256) {
        return bakers[adr].totalAte * PUNISH_PER_ATE;
    }


    function secondsSinceLastAction(
        address adr
    ) private view returns (uint256) {
        if (!started()) return 0;
        uint256 lastTimeStamp = bakers[adr].bakedAt;
        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].ateAt;
        }

        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].firstDeposit;
        }
        if (lastTimeStamp < launch) lastTimeStamp = launch; // predeposit user

        return Math.sub(block.timestamp, lastTimeStamp);
    }

    function rewardedBeans(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastAction(adr);
        uint256 dailyRewardFactor = dailyReward(adr);
        uint256 dailyPunishFactor = dailyPunish(adr);
        uint256 beansRewarded = calcBeansReward(
            secondsPassed,
            dailyRewardFactor,
            dailyPunishFactor,
            adr
        );

        if (beansRewarded >= bnbToBeans(MAX_DAILY_REWARDS_IN_BNB)) {
            return bnbToBeans(MAX_DAILY_REWARDS_IN_BNB);
        }

        return beansRewarded;
    }

    function calcBeansReward(
        uint256 secondsPassed,
        uint256 dailyRewardFactor,
        uint256 dailyPunishFactor,
        address adr
    ) private view returns (uint256) {

        dailyRewardFactor = (dailyRewardFactor>dailyPunishFactor) ? dailyRewardFactor - dailyPunishFactor : 0;
        uint256 rewardsPerDay = percentFromAmount(
            Math.mul(bakers[adr].beans, 100000000),
            dailyRewardFactor
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 beansRewarded = Math.mul(rewardsPerSecond, secondsPassed);
        beansRewarded = Math.div(beansRewarded, 1000000000000);
        return beansRewarded - getWhaleTax(adr,beansRewarded);
    }

    function getUserPercentage(address _adr) public view returns(uint256) {
        uint256 _contractBalance = contractBalance();
        if (bakers[_adr].totalDeposit==0 || _contractBalance==0) return 0;
        return (bakers[_adr].totalDeposit * percentdiv)/(_contractBalance);
    }

    function getWhaleTax(address _adr, uint256 amount) public view returns(uint256 _whaleTax) {
        uint256 userPercentage = getUserPercentage(_adr);
        if (userPercentage>1000) { userPercentage=1000;} // maximum 10%
        else if (userPercentage<= WHALE_TAX_MINIMUM) { userPercentage=0;}
        _whaleTax = (amount * userPercentage * WHALE_TAX_MULTIPLIER)/(percentdiv);
    }

    function started() public view returns(bool) {
        return block.timestamp > launch;
    }

}