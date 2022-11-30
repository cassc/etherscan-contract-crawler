// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//    _____                       ______                   
//   / ___/____  ____ _________  / ____/___ __________ ___ 
//   \__ \/ __ \/ __ `/ ___/ _ \/ /_  / __ `/ ___/ __ `__ \
//  ___/ / /_/ / /_/ / /__/  __/ __/ / /_/ / /  / / / / / /
// /____/ .___/\__,_/\___/\___/_/    \__,_/_/  /_/ /_/ /_/ 
//     /_/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Main
struct Main {
    uint256 totalUsers;
    uint256 totalCompounds;
    uint256 totalWith;
    uint256 totalStakeNumber;
    uint256 totalVipNumber;
    uint256 totalRoundLottery;
    address previousLotteryWinner;
    uint256 previousLotteryAmount;
    uint256 previousLotteryPercentage;
}
// User
struct User {
    uint256 startDate;
    uint256 activeStakeCounter;
    uint256 totalStake;
    uint256 totalWith;
    uint256 lastWith;
    Depo[] depoList;
    address ref;
    uint256 bonus;
    uint256 totalBonus;
    uint256[3] levels;
    uint256 VipType;
}
// Percs
struct DivPercs {
    uint256 daysInSeconds;
    uint256 divsPercentage;
    uint16[4] feePercentage;
}
// Deposit
struct Depo {
    uint256 key;
    uint256 depoTime;
    uint256 amt;
    bool validated;
}
// VIP
struct VIP {
    uint256 percentageLottery;
    uint72[3] price;
    uint8[3] refPercentage;
}
// SpaceLottery
struct SpaceLottery {
    uint256 balance;
    address payable[] participants;
    uint256 participantCount;
    address winner;
    uint256 winnerAmount;
    uint256 winnerPercentage;
    bool payout;
}

contract SpaceFarm is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 constant dAppLaunch = 1670022000; // Fixed to December 2st, 2022 11:00:00 PM GMT

    uint256 constant hardDays = 1 days;
    uint256 constant percentdiv = 1000;
    uint256 constant minDeposit = 50 ether;
    uint256 immutable stakeFee = 100;
    uint256 immutable reinvestFee = 50;

    bool private spaceLotteryEnabled = true;
    
    mapping(uint256 => Main) public MainKey;
    mapping(address => User) public UsersKey;
    mapping(uint256 => DivPercs) public PercsKey;
    mapping(uint256 => VIP) public VipKey;
    mapping(uint256 => SpaceLottery) public LotteryKey;

    IERC20 private BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);  // Live BUSD Address
    address private immutable dApp;
    address private immutable devOwner;

    constructor(address _devOwner) {
        PercsKey[10] = DivPercs({daysInSeconds:  10 days, divsPercentage:  10, feePercentage: [uint16(500), 400, 300, 200]});
        PercsKey[20] = DivPercs({daysInSeconds:  20 days, divsPercentage:  20, feePercentage: [uint16(470), 370, 280, 180]});
        PercsKey[30] = DivPercs({daysInSeconds:  30 days, divsPercentage:  30, feePercentage: [uint16(440), 340, 260, 160]});
        PercsKey[40] = DivPercs({daysInSeconds:  40 days, divsPercentage:  40, feePercentage: [uint16(410), 310, 240, 140]});
        PercsKey[50] = DivPercs({daysInSeconds:  50 days, divsPercentage:  50, feePercentage: [uint16(380), 280, 220, 120]});
        PercsKey[60] = DivPercs({daysInSeconds:  60 days, divsPercentage:  60, feePercentage: [uint16(350), 250, 200, 100]});
        PercsKey[70] = DivPercs({daysInSeconds:  70 days, divsPercentage:  70, feePercentage: [uint16(320), 230, 180, 80]});
        PercsKey[80] = DivPercs({daysInSeconds:  80 days, divsPercentage:  80, feePercentage: [uint16(290), 210, 160, 60]});
        PercsKey[90] = DivPercs({daysInSeconds:  90 days, divsPercentage:  90, feePercentage: [uint16(260), 190, 140, 40]});
        PercsKey[100]= DivPercs({daysInSeconds: 100 days, divsPercentage:  100, feePercentage: [uint16(230), 170, 120, 20]});
        PercsKey[110]= DivPercs({daysInSeconds: 101 days, divsPercentage: 150, feePercentage: [uint16(200), 150, 100, 0]});

        VipKey[0] = VIP({percentageLottery: 10, price: [uint72(50 ether), 100 ether, 250 ether], refPercentage: [50, 30, 20]});
        VipKey[1] = VIP({percentageLottery: 20, price: [uint72(0 ether),  50 ether,  200 ether], refPercentage: [60, 40, 30]});
        VipKey[2] = VIP({percentageLottery: 30, price: [uint72(0 ether),  0 ether,   150 ether], refPercentage: [70, 50, 30]});
        VipKey[3] = VIP({percentageLottery: 50, price: [uint72(0 ether),  0 ether,   0 ether],   refPercentage: [80, 60, 40]});

        dApp = payable(msg.sender);
        devOwner = payable(_devOwner);
    }

    function Stake(uint256 _amt, address _ref) public payable {
        require(block.timestamp >= dAppLaunch, "App did not launch yet.");
        require(_ref != msg.sender, "You cannot refer yourself!");
        require(_amt >= minDeposit, "Min Investment 50 BUSD!");

        BUSD.safeTransferFrom(msg.sender, address(this), _amt);

        Main storage main = MainKey[1];
        User storage user = UsersKey[msg.sender];
        VIP storage vip = VipKey[user.VipType];
        SpaceLottery storage spaceLottery = LotteryKey[getCurrentDay()];

        uint256 fee = _amt.mul(stakeFee).div(percentdiv);
        uint256 adjustedAmt = _amt.sub(fee);

        if (user.ref == address(0) && msg.sender != devOwner) {
            user.ref = UsersKey[_ref].depoList.length == 0 ? devOwner : _ref;
			address upline = user.ref;
            User storage userRef = UsersKey[upline];
			for (uint256 i = 0; i < VipKey[0].refPercentage.length; i++) {
				if (upline != address(0)) {
                    userRef.levels[i].add(1);
					upline = userRef.ref;
				} else break;
			}
		}

		if (user.ref != address(0)) {
            address upline = user.ref;
            if(user.VipType == 0 || UsersKey[upline].VipType == 0) {
                for (uint256 i = 0; i < VipKey[0].refPercentage.length; i++) {
                    upline = upline == address(0) ? devOwner : upline;
                    uint256 amount = adjustedAmt.mul(VipKey[0].refPercentage[i]).div(percentdiv);
                    UsersKey[upline].bonus = UsersKey[upline].bonus.add(amount);
                    UsersKey[upline].totalBonus = UsersKey[upline].totalBonus.add(amount);
                    upline = UsersKey[upline].ref;
                }
            } else if(user.VipType > 0 && user.VipType <= 3 && UsersKey[upline].VipType > 0 && UsersKey[upline].VipType <= 3){
                for (uint256 i = 0; i < vip.refPercentage.length; i++) {
                    upline = upline == address(0) ? devOwner : upline;
                    uint256 amount = adjustedAmt.mul(VipKey[UsersKey[upline].VipType].refPercentage[i]).div(percentdiv);
                    UsersKey[upline].bonus = UsersKey[upline].bonus.add(amount);
                    UsersKey[upline].totalBonus = UsersKey[upline].totalBonus.add(amount);
                    upline = UsersKey[upline].ref;
                }
            }
		}

        user.depoList.push(
            Depo({
                key: user.depoList.length,
                depoTime: block.timestamp,
                amt: adjustedAmt,
                validated: false
            })
        );

        main.totalStakeNumber += 1;
        if(user.startDate == 0){
            main.totalUsers += 1;
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }
        user.totalStake += adjustedAmt;
        user.activeStakeCounter += 1;

        BUSD.safeTransfer(dApp, stakeFee);

        if(spaceLotteryEnabled){
            if(!checkPartecipantExist(msg.sender, getCurrentDay())) {
                spaceLottery.balance += adjustedAmt;
                spaceLottery.participants.push(payable(msg.sender));
                spaceLottery.participantCount += 1;
            }
            SpaceLotteryWinner();
        }
    }

    function Unstake(uint256 _key) public payable {
        Main storage main = MainKey[1];
        User storage user = UsersKey[msg.sender];
        SpaceLottery storage spaceLottery = LotteryKey[getCurrentDay()];
        require(!user.depoList[_key].validated, "This stake has already been withdrawn.");
        
        uint256 dailyReturn;
        uint256 transferAmt;
        uint256 amount = user.depoList[_key].amt;
        uint256 elapsedTime = block.timestamp.sub(user.depoList[_key].depoTime);
        
        if (elapsedTime <= PercsKey[10].daysInSeconds){
            dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[10].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[20].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
            dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[30].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[40].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[50].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[50].daysInSeconds && elapsedTime <= PercsKey[60].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[60].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[60].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[60].daysInSeconds && elapsedTime <= PercsKey[70].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[70].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[70].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[70].daysInSeconds && elapsedTime <= PercsKey[80].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[80].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[80].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[80].daysInSeconds && elapsedTime <= PercsKey[90].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[90].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[90].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[90].daysInSeconds && elapsedTime <= PercsKey[100].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[100].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[100].feePercentage[user.VipType]).div(percentdiv));
        } else if (elapsedTime > PercsKey[110].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[110].divsPercentage).div(percentdiv);
            transferAmt = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[110].feePercentage[user.VipType]).div(percentdiv));
        } else {
            revert("Cannot calculate user's staked days.");
        }

        BUSD.safeTransfer(msg.sender, transferAmt);

        if(spaceLotteryEnabled){
            if(block.timestamp - user.depoList[_key].depoTime < hardDays){
                for (uint i = 0; i < spaceLottery.participants.length; i++) {
                    if (spaceLottery.participants[i] == msg.sender) {
                        spaceLottery.balance -= amount;
                        delete spaceLottery.participants[i];
                        spaceLottery.participantCount -= 1;
                    }
                }
            }
            SpaceLotteryWinner();
        }

        main.totalWith += transferAmt;
        main.totalStakeNumber -= 1;
        user.lastWith = block.timestamp;
        user.totalWith += transferAmt;
        user.activeStakeCounter -= 1;
        user.totalStake -= user.depoList[_key].amt;
        user.depoList[_key].amt = 0;
        user.depoList[_key].validated = true;
        user.depoList[_key].depoTime = block.timestamp;
    }

    function Reinvest(uint256 _key) public payable {
        User storage user = UsersKey[msg.sender];

        uint256 calc;
        if(_key == 0){ calc = CalculateEarnings(msg.sender); } else if(_key == 1){ calc = user.bonus; } else { calc = 0; }

        require(calc >= 50, "Min Investment 50 BUSD!");

        for (uint256 i = 0; i < user.depoList.length; i++) {
            if (user.depoList[i].validated == false) {
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        Main storage main = MainKey[1];
        VIP storage vip = VipKey[user.VipType];
        SpaceLottery storage spaceLottery = LotteryKey[getCurrentDay()];

        uint256 fee = calc.mul(reinvestFee).div(percentdiv);
        uint256 adjustedAmt = calc.sub(fee);

        user.ref = (user.ref == address(0) && msg.sender != devOwner) ? devOwner: user.ref;
        address upline = user.ref;

        if(user.VipType == 0 || UsersKey[upline].VipType == 0) {
            for (uint256 i = 0; i < VipKey[0].refPercentage.length; i++) {
                upline = (upline == address(0) && msg.sender != devOwner ) ? devOwner : upline;
                uint256 amount = adjustedAmt.mul(VipKey[0].refPercentage[i]).div(percentdiv);
                UsersKey[upline].bonus = UsersKey[upline].bonus.add(amount);
                UsersKey[upline].totalBonus = UsersKey[upline].totalBonus.add(amount);
                upline = UsersKey[upline].ref;
            }
        } else if(user.VipType > 0 && user.VipType <= 3 && UsersKey[upline].VipType > 0 && UsersKey[upline].VipType <= 3){
            for (uint256 i = 0; i < vip.refPercentage.length; i++) {
                upline = (upline == address(0) && msg.sender != devOwner) ? devOwner : upline;
                uint256 amount = adjustedAmt.mul(VipKey[UsersKey[upline].VipType].refPercentage[i]).div(percentdiv);
                UsersKey[upline].bonus = UsersKey[upline].bonus.add(amount);
                UsersKey[upline].totalBonus = UsersKey[upline].totalBonus.add(amount);
                upline = UsersKey[upline].ref;
            }
        }

        user.depoList.push(
            Depo({
                key: user.activeStakeCounter,
                depoTime: block.timestamp,
                amt: adjustedAmt,
                validated: false
            })
        );

        main.totalStakeNumber += 1;
        user.activeStakeCounter += 1;
        user.totalStake += adjustedAmt;
        user.bonus = (_key == 1) ? 0 : user.bonus;

        BUSD.safeTransfer(dApp, reinvestFee);

        if(spaceLotteryEnabled){
            if(!checkPartecipantExist(msg.sender, getCurrentDay())) {
                spaceLottery.balance += adjustedAmt;
                spaceLottery.participants.push(payable(msg.sender));
                spaceLottery.participantCount += 1;
            }
            SpaceLotteryWinner();
        }
    }

    function Compound() public {
        Main storage main = MainKey[1];
        User storage user = UsersKey[msg.sender];

        uint256 calc = CalculateEarnings(msg.sender);

        for (uint256 i = 0; i < user.depoList.length; i++) {
            if (user.depoList[i].validated == false) {
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        user.depoList.push(
            Depo({
                key: user.activeStakeCounter,
                depoTime: block.timestamp,
                amt: calc,
                validated: false
            })
        );

        main.totalStakeNumber += 1;
        main.totalCompounds += 1;
        user.activeStakeCounter += 1;
        user.totalStake += calc;
    }

    function Collect() public {
        Main storage main = MainKey[1];
        User storage user = UsersKey[msg.sender];

        uint256 calc = CalculateEarnings(msg.sender);

        for (uint256 i = 0; i < user.depoList.length; i++) {
            if (user.depoList[i].validated == false) {
                user.depoList[i].depoTime = block.timestamp;
            }
        }

        BUSD.safeTransfer(msg.sender, calc);

        main.totalWith += calc;
        user.totalWith += calc;
        user.lastWith = block.timestamp;
    }

    function CompoundRef() public {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        require(user.bonus > 10 ether);

        user.depoList.push(
            Depo({
                key: user.activeStakeCounter,
                depoTime: block.timestamp,
                amt: user.bonus,
                validated: false
            })
        );

        main.totalStakeNumber += 1;
        main.totalCompounds += 1;
        user.activeStakeCounter += 1;
        user.totalStake += user.bonus;
        user.bonus = 0;
    }

    function CollectRef() public {
        User storage user = UsersKey[msg.sender];

        uint totalAmount = UsersKey[msg.sender].bonus;

		require(totalAmount > 0, "User has no dividends");
        BUSD.safeTransfer(msg.sender, totalAmount);

        user.bonus = 0;
    }

    function CalculateEarnings(address _dy) public view returns (uint256) {
        User storage user = UsersKey[_dy];	

        uint256 totalWithdrawable;
        
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);
            uint256 amount = user.depoList[i].amt;

            if (user.depoList[i].validated == false){

                if (elapsedTime <= PercsKey[10].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[10].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[20].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[30].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[40].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[50].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[50].daysInSeconds && elapsedTime <= PercsKey[60].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[60].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[60].daysInSeconds && elapsedTime <= PercsKey[70].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[70].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[70].daysInSeconds && elapsedTime <= PercsKey[80].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[80].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[80].daysInSeconds && elapsedTime <= PercsKey[90].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[90].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[90].daysInSeconds && elapsedTime <= PercsKey[100].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[100].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
                if (elapsedTime > PercsKey[110].daysInSeconds){
                    totalWithdrawable += (amount.mul(PercsKey[110].divsPercentage).div(percentdiv)).mul(elapsedTime).div(hardDays);
                }
            } 
        }
        return totalWithdrawable;
    }

    function JoinVip(uint256 _key) public payable {
        Main storage main = MainKey[1];
        User storage user = UsersKey[msg.sender];

        require(user.activeStakeCounter == 0, "You have active investments!");
        require(_key > 0 && _key <= 3, "Invalid selection!");
        require(user.VipType < _key, "You have a better plan!");

        VIP storage vip = VipKey[user.VipType];

        uint256 _amt = vip.price[_key - 1];

        require(_amt > 0 && _amt <= 250 ether, "Invalid amount!");

        BUSD.safeTransferFrom(msg.sender, address(this), _amt);
        BUSD.safeTransfer(dApp, minDeposit);

        main.totalVipNumber = user.VipType == 0 ? main.totalVipNumber + 1 : main.totalVipNumber;
        user.VipType = _key;
    }

    function GestureVip(uint256 _key, address _vipAddr) public onlyOwner {
        Main storage main = MainKey[1];
        User storage user = UsersKey[_vipAddr];

        require(_key > 0 && _key <= 3, "Invalid selection!");

        main.totalVipNumber = user.VipType == 0 ? main.totalVipNumber + 1 : main.totalVipNumber;
        user.VipType = _key;
    }

    function checkPartecipantExist(address _key, uint256 _time) public view returns (bool) {
        SpaceLottery storage spaceLottery = LotteryKey[_time];
        for (uint i = 0; i < spaceLottery.participants.length; i++) {
            if (spaceLottery.participants[i] == _key) {
                return true;
            }
        }
        return false;
    }

    function getCurrentDay() public view returns (uint256) {
        return minZero(block.timestamp, dAppLaunch).div(hardDays);
    }

    function getTimeToNextDay() public view returns (uint256) {
        uint time = minZero(block.timestamp, dAppLaunch);
        uint nextDay = getCurrentDay().mul(hardDays);
        return nextDay.add(hardDays).sub(time);
    }

    function minZero(uint256 _a, uint256 _b) private pure returns(uint256) {
        return (_a > _b) ? _a - _b : 0;
    }

    function random() private view returns(uint256){
        uint256 count = LotteryKey[getCurrentDay()].participantCount;
        return uint256(keccak256(abi.encode(block.difficulty, block.timestamp, count, block.number)));
    }

    function SpaceLotteryWinner() private {
        require(block.timestamp >= dAppLaunch, "App did not launch yet.");
        if(getCurrentDay() > 0 && spaceLotteryEnabled){
            Main storage main = MainKey[1];
            SpaceLottery storage spaceLottery = LotteryKey[getCurrentDay() - 1];
            if(!spaceLottery.payout){
                if(spaceLottery.balance > 0 && spaceLottery.participantCount >= 10) {
                    uint256 index = random() % spaceLottery.participantCount;
                    address winner = spaceLottery.participants[index];
                    if(checkPartecipantExist(winner, getCurrentDay() - 1) && address(winner) != address(main.previousLotteryWinner)){
                        User storage user = UsersKey[winner];
                        VIP storage vip = VipKey[user.VipType];
                        uint256 balance = spaceLottery.balance;
                        uint256 percentage = vip.percentageLottery;
                        uint256 amt = balance.mul(percentage).div(percentdiv);

                        BUSD.safeTransfer(winner, amt);

                        main.totalRoundLottery += 1;
                        main.previousLotteryWinner = winner;
                        main.previousLotteryAmount = amt;
                        main.previousLotteryPercentage = percentage;
                        spaceLottery.payout = true;
                        spaceLottery.winner = winner;
                        spaceLottery.winnerAmount = amt;
                        spaceLottery.winnerPercentage = percentage;

                        delete spaceLottery.participants;
                    }
                }
            }
        }
    }

    function SpaceLotteryWinner_M(uint256 _key) external onlyOwner {
        require(block.timestamp >= dAppLaunch, "App did not launch yet.");
        require (_key >= 0 && _key < getCurrentDay(), "Invalid key!");
        Main storage main = MainKey[1];
        SpaceLottery storage spaceLottery = LotteryKey[_key];
        require(!spaceLottery.payout, "Lottery already verified!");
        require(spaceLottery.balance > 0, "Insufficient lottery balance!");
        require(spaceLottery.participantCount >= 10, "Insufficient number of participants!");

        uint256 index = random() % spaceLottery.participantCount;
        address winner = spaceLottery.participants[index];

        require(checkPartecipantExist(winner, _key), "Participant not found!");
        require(winner != main.previousLotteryWinner, "You cannot win the Lottery below!");
        User storage user = UsersKey[winner];
        VIP storage vip = VipKey[user.VipType];

        uint256 balance = spaceLottery.balance;
        uint256 percentage = vip.percentageLottery;
        uint256 amt = balance.mul(percentage).div(percentdiv);

        BUSD.safeTransfer(winner, amt);

        main.totalRoundLottery += 1;
        main.previousLotteryWinner = winner;
        main.previousLotteryAmount = amt;
        main.previousLotteryPercentage = percentage;
        spaceLottery.payout = true;
        spaceLottery.winner = winner;
        spaceLottery.winnerAmount = amt;
        spaceLottery.winnerPercentage = percentage;

        delete spaceLottery.participants;
    }

    function switchSpaceLotteryEnabled() public onlyOwner {
        require(block.timestamp >= dAppLaunch, "App did not launch yet.");
        SpaceLotteryWinner();
        spaceLotteryEnabled = !spaceLotteryEnabled ? true : false;
    }

    function UserInfo() external view returns (Depo[] memory depoList) {
        User storage user = UsersKey[msg.sender];
        return (user.depoList);
    }

    function VipInfoPrice() external view returns (uint72[3] memory price) {
        User storage user = UsersKey[msg.sender];
        VIP storage vip = VipKey[user.VipType];
        return (vip.price);
    }

    function RefPercentageInfo() external view returns (uint8[3] memory refPercentage) {
        User storage user = UsersKey[msg.sender];
        VIP storage vip = VipKey[user.VipType];
        return (vip.refPercentage);
    }
}