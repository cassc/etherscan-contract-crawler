// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/router2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "hardhat/console.sol";

contract BKCFINANCE3 is OwnableUpgradeable {
    using AddressUpgradeable for address;

    address[2] private buyPath;
    address[2] private sellPath;
    uint[] private stakeAmountList;
    uint[] private profitRatioList;
    uint[] private releaseAmount;
    uint[] private releaseTime;

    bool public status;
    uint public ACC;
    uint public intervals;
    uint public freezeTime;
    uint public minimumStake;
    uint public slotLength;
    uint[] public slotList;

    struct AddressContainer {
        address BKC;
        address USDT;
        address PAIR;
        address PANCAKE_ROUTER;
    }
    AddressContainer public addr;

    struct SlotInfo {
        uint acc;
        uint lockTime;
    }
    mapping(uint => SlotInfo) public slotInfo;

    struct ReleasePoolInfo {
        uint day;
        uint amount;
        uint startTime;
        uint lastTime;
        uint claimedAmount;
    }
    mapping(address => mapping(uint => ReleasePoolInfo)) public releasePoolInfo;

    struct UserInfo {
        uint stakeAmount;
        uint stakeValue;
        uint profitRatio;
        uint stakeTime;
        uint startTime;
        uint lockTime;
        uint lastTime;
        uint rewardValue;
        uint claimedAmount;
        uint claimedValue;
    }
    mapping(address => mapping(uint => UserInfo)) public userInfo;
    mapping(address => bool) public isStake;
    mapping(address => bool) public wc;

    event Stake(address indexed user, uint indexed amount, uint indexed value);
    event Withdraw(
        address indexed user,
        uint indexed amount,
        uint indexed value
    );
    event WithdrawLast(address indexed user, uint indexed amount);
    event UnStake(address indexed user, uint indexed amount);

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "only EOA");
        _;
    }

    function init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        status = true;
        ACC = 1 ether;

        setAddress(
            0x55d398326f99059fF775485246999027B3197955,
            0x32BbB60889A6b4e16D75c1AdD60b58BB323A71A5,
            0x1ADdB6f2F7cD57b9391f65795E7Be23c073b82b2,
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        newSlot((86400 * 30));
        newSlot((86400 * 30 * 3));
        newSlot((86400 * 30 * 6));

        profitRatioList = [3, 5, 7, 9, 12, 15];
        stakeAmountList = [
            10000000000 ether,
            50000000000 ether,
            100000000000 ether,
            200000000000 ether,
            400000000000 ether,
            1000000000000 ether
        ];

        releaseTime = [(86400 * 5), (86400 * 13), (86400 * 13), (86400 * 20)];
        releaseAmount = [
            10000000000 ether,
            100000000000 ether,
            400000000000 ether,
            1000000000000 ether
        ];
        minimumStake = 10000000000 ether;
        intervals = (86400 * 7);
    }

    function setAddress(
        address u_,
        address bkc_,
        address pair_,
        address router_
    ) public onlyOwner {
        addr.USDT = u_;
        addr.BKC = bkc_;
        addr.PAIR = pair_;
        addr.PANCAKE_ROUTER = router_;

        buyPath[0] = u_;
        buyPath[1] = bkc_;
        sellPath[0] = bkc_;
        sellPath[1] = u_;
    }

    // function testMode() public onlyOwner {
    //     slotInfo[0].lockTime = (60 * 30);
    //     slotInfo[1].lockTime = (60 * 30 * 3);
    //     slotInfo[2].lockTime = (60 * 30 * 6);
    //     releaseTime = [(60 * 5), (60 * 13), (60 * 15), (60 * 20)];
    //     intervals = (60 * 7);
    // }

    function setStatus(bool b_) public onlyOwner {
        require(status, "is close");
        status = b_;
        freezeTime = block.timestamp;
    }

    function setMinimumStake(uint u_) public onlyOwner {
        minimumStake = u_;
    }

    function setIntervals(uint u_) public onlyOwner {
        intervals = u_;
    }

    function setReleaseTime(
        uint[] memory amounts_,
        uint[] memory us_
    ) public onlyOwner {
        require(amounts_.length == us_.length, "length worry");
        require(amounts_[0] == minimumStake, "minimum not metch");
        releaseAmount = amounts_;
        releaseTime = us_;
    }

    function setProfitRatioList(
        uint[] calldata ratios_,
        uint[] calldata amounts_
    ) public onlyOwner {
        require(ratios_.length == amounts_.length, "length worry");
        profitRatioList = ratios_;
        stakeAmountList = amounts_;
        minimumStake = amounts_[0];
    }

    function safePull(
        address token,
        address wallet,
        uint amount_
    ) public onlyOwner {
        IERC20(token).transfer(wallet, amount_);
    }

    ////////////////////////////////
    ////////////         ///////////
    ////////////////////////////////

    function newSlot(uint lockTime_) public onlyOwner {
        uint id = slotLength;
        slotLength += 1;
        slotList.push(id);

        slotInfo[id].lockTime = lockTime_;
        if (lockTime_ > (86400 * 30)) {
            slotInfo[id].acc = lockTime_ / (86400 * 30);
        } else {
            slotInfo[id].acc = 1;
        }
    }

    function setSlotAcc(uint id_, uint acc_) public onlyOwner {
        require(slotInfo[id_].acc != 0, "slot is not start");
        slotInfo[id_].acc = acc_;
    }

    ////////////////////////////////
    //////////// Finance ///////////
    ////////////////////////////////

    // 0 sell , 1 buy
    function getOut(
        address[2] memory path_,
        uint tradeType_,
        uint amountInput_
    ) public view returns (uint amountOutput) {
        uint price;
        address pair = addr.PAIR;
        (uint re0, uint re1, ) = IPair(pair).getReserves();
        address _t0 = IPair(pair).token0();
        address _t1 = IPair(pair).token1();
        {
            // scope for _t{0,1}, avoids stack too deep errors
            if (_t0 == addr.USDT) price = (re0 * ACC) / re1;
            if (_t1 == addr.USDT) price = (re1 * ACC) / re0;
        }
        // scope for amountOutput, avoids stack too deep errors

        if (tradeType_ == 0) {
            amountOutput = (amountInput_ * price) / ACC;
        } else if (tradeType_ == 1) {
            amountOutput = (amountInput_ * ACC) / price;
        }
    }

    function calculateBasicRatio(uint amount) public view returns (uint) {
        uint index;
        uint len = stakeAmountList.length;
        if (amount > stakeAmountList[len - 1]) {
            index = len - 1;
            return profitRatioList[index];
        }

        for (uint i = 0; i < (len - 1); i++) {
            if (amount > stakeAmountList[i + 1]) {
                continue;
            } else {
                index = i;
                break;
            }
        }
        return profitRatioList[index];
    }

    function calculateProfitRatio(
        uint slot,
        uint basicRatio
    ) public view returns (uint) {
        uint acc = slotInfo[slot].acc;
        uint realRatio = acc * basicRatio;
        return realRatio;
    }

    function stake(uint amount_, uint slot_) public onlyEOA {
        if (msg.sender.isContract()) {
            require(wc[msg.sender], "contract is illegal");
        }
        require(status, "not start");
        require(amount_ >= minimumStake, "amount too low");
        // require(userInfo[msg.sender][slot_].stakeAmount == 0, "already stake");
        require(!isStake[msg.sender], "already stake");

        uint _stakeValue = getOut(sellPath, 0, amount_);
        uint _lockTime = slotInfo[slot_].lockTime;
        uint _basicRatio = calculateBasicRatio(amount_);
        uint _profitRatio = calculateProfitRatio(slot_, _basicRatio);
        uint _totalReward = (_stakeValue * _profitRatio * slotInfo[slot_].acc) /
            100;

        userInfo[msg.sender][slot_] = UserInfo({
            stakeAmount: amount_,
            stakeValue: _stakeValue,
            profitRatio: _profitRatio,
            stakeTime: block.timestamp,
            startTime: block.timestamp + intervals,
            lockTime: _lockTime,
            lastTime: 0,
            rewardValue: _totalReward,
            claimedAmount: 0,
            claimedValue: 0
        });
        isStake[msg.sender] = true;

        IERC20(addr.BKC).transferFrom(msg.sender, address(this), amount_);
        emit Stake(
            msg.sender,
            userInfo[msg.sender][slot_].stakeAmount,
            userInfo[msg.sender][slot_].stakeValue
        );
    }

    function calculateReward(
        uint slot_,
        address user_
    ) public view returns (uint _amount, uint _value) {
        UserInfo storage user = userInfo[user_][slot_];
        uint endTime = user.startTime + user.lockTime;
        uint total = user.rewardValue;
        if (block.timestamp < user.startTime) {
            return (0, 0);
        }

        if (user.claimedValue == total) {
            return (0, 0);
        }

        if (block.timestamp < endTime) {
            if (status) {
                if (user.lastTime == 0) {
                    _value =
                        (total * (block.timestamp - user.startTime)) /
                        user.lockTime;
                } else {
                    _value =
                        (total * (block.timestamp - user.lastTime)) /
                        user.lockTime;
                }
            } else {
                if (user.lastTime < freezeTime) {
                    if (user.lastTime == 0 && user.startTime < freezeTime) {
                        // first
                        _value =
                            (total * (freezeTime - user.startTime)) /
                            user.lockTime;
                    } else if (user.lastTime != 0) {
                        // last
                        _value =
                            (total * (freezeTime - user.lastTime)) /
                            user.lockTime;
                    }
                }
            }
        } else {
            // last
            _value = total - user.claimedValue;
        }

        if (_value != 0) {
            _amount = getOut(buyPath, 1, _value);
        }
    }

    function withdraw(uint slot_) public onlyEOA returns (uint _amount) {
        UserInfo storage user = userInfo[msg.sender][slot_];
        if (msg.sender.isContract()) {
            require(wc[msg.sender], "contract is illegal");
        }
        require(block.timestamp > user.startTime, "not start");
        require(user.claimedValue < user.rewardValue, "out of total");

        uint _value;
        (_amount, _value) = calculateReward(slot_, msg.sender);
        if (_amount != 0) {
            user.claimedAmount += _amount;
            user.claimedValue += _value;
            user.lastTime = block.timestamp;

            if (user.rewardValue == user.claimedValue) {
                _after(slot_);
            }
            IERC20(addr.BKC).transfer(msg.sender, _amount);
            emit Withdraw(msg.sender, _amount, _value);
        }
    }

    function getDay(uint slot_) internal view returns (uint index) {
        UserInfo storage user = userInfo[msg.sender][slot_];
        uint len = releaseAmount.length;
        require(len != 0, "no length");

        if (user.stakeAmount > releaseAmount[len - 1]) {
            index = len - 1;
        }
        if (index == 0) {
            for (uint i = 0; i < (len - 1); i++) {
                if (user.stakeAmount > releaseAmount[i + 1]) {
                    continue;
                } else {
                    index = i;
                    break;
                }
            }
        }
    }

    function calculateRelease(
        uint slot_,
        address user_
    ) public view returns (uint) {
        ReleasePoolInfo storage release = releasePoolInfo[user_][slot_];
        uint _value;
        uint _day;
        uint total;
        if (release.amount != 0) {
            total = release.amount;
            _day = release.day;
        } else {
            return 0;
        }

        uint start = release.startTime;
        uint end = release.startTime + _day;

        if (!status && release.claimedAmount < total) {
            _value = total - release.claimedAmount;
            return _value;
        }

        if (block.timestamp > start && release.claimedAmount < total) {
            if (block.timestamp < end) {
                if (release.lastTime == 0) {
                    _value = (total * (block.timestamp - start)) / _day;
                } else {
                    _value =
                        (total * (block.timestamp - release.lastTime)) /
                        _day;
                }
            } else {
                _value = total - release.claimedAmount;
            }
        }
        return _value;
    }

    function freed(uint slot_) public onlyEOA {
        UserInfo storage user = userInfo[msg.sender][slot_];
        uint index = getDay(slot_);
        if (status) {
            require(
                block.timestamp > user.stakeTime + user.lockTime,
                "not the time"
            );
        }

        require(user.stakeValue != 0, "no value");
        require(
            releasePoolInfo[msg.sender][slot_].amount == 0,
            "already release"
        );
        releasePoolInfo[msg.sender][slot_] = ReleasePoolInfo({
            day: releaseTime[index],
            amount: user.stakeValue,
            startTime: block.timestamp,
            lastTime: 0,
            claimedAmount: 0
        });
    }

    function unStake(uint slot_) public onlyEOA {
        ReleasePoolInfo storage release = releasePoolInfo[msg.sender][slot_];
        if (msg.sender.isContract()) {
            require(wc[msg.sender], "contract is illegal");
        }
        require(release.amount > 0, "no amount");

        uint _value = calculateRelease(slot_, msg.sender);
        uint _amount = getOut(buyPath, 1, _value);

        release.claimedAmount += _value;
        release.lastTime = block.timestamp;
        if (release.amount == release.claimedAmount) {
            _after(slot_);
        }

        IERC20(addr.BKC).transfer(msg.sender, _amount);
        emit UnStake(msg.sender, _amount);
    }

    function _after(uint slot_) internal {
        UserInfo storage user = userInfo[msg.sender][slot_];
        ReleasePoolInfo storage release = releasePoolInfo[msg.sender][slot_];

        if (release.amount != 0 && user.rewardValue != 0) {
            if (
                release.amount == release.claimedAmount &&
                user.rewardValue == user.claimedValue
            ) {
                releasePoolInfo[msg.sender][slot_] = ReleasePoolInfo({
                    day: 0,
                    amount: 0,
                    startTime: 0,
                    lastTime: 0,
                    claimedAmount: 0
                });

                userInfo[msg.sender][slot_] = UserInfo({
                    stakeAmount: 0,
                    stakeValue: 0,
                    profitRatio: 0,
                    stakeTime: 0,
                    startTime: 0,
                    lockTime: 0,
                    lastTime: 0,
                    rewardValue: 0,
                    claimedAmount: 0,
                    claimedValue: 0
                });

                isStake[msg.sender] = false;
            }
        }
    }

    ////////////////////////////////
    ///////////// view /////////////
    ////////////////////////////////

    function checkProfitRatioList() public view returns (uint[] memory) {
        return profitRatioList;
    }

    function checkStakeAmountList() public view returns (uint[] memory) {
        return stakeAmountList;
    }

    function checkRelease() public view returns (uint[] memory, uint[] memory) {
        return (releaseAmount, releaseTime);
    }

    function checkPancakePrice() public view returns (uint price) {
        address pair = addr.PAIR;
        (uint re0, uint re1, ) = IPair(pair).getReserves();
        address _t0 = IPair(pair).token0();
        address _t1 = IPair(pair).token1();

        {
            // scope for _t{0,1}, avoids stack too deep errors
            if (_t0 == addr.USDT) price = (re0 * ACC) / re1;
            if (_t1 == addr.USDT) price = (re1 * ACC) / re0;
        }
    }

    function checkSlot(address user_) public view returns (uint) {
        uint _slot;
        for (uint i = 0; i < slotLength; i++) {
            if (userInfo[user_][i].stakeAmount != 0) {
                _slot = i;
                break;
            } else {
                continue;
            }
        }
        return _slot;
    }

    function checkReward(
        address user_
    )
        public
        view
        returns (
            bool[2] memory bools,
            uint[3] memory times,
            uint[5] memory amounts
        )
    {
        uint _slot = checkSlot(user_);
        amounts[0] = _slot;
        console.log(_slot);

        (amounts[1], ) = calculateReward(_slot, user_);

        if (releasePoolInfo[user_][_slot].startTime != 0) {
            times[1] =
                releasePoolInfo[user_][_slot].startTime +
                releasePoolInfo[user_][_slot].day;
        }

        if (releasePoolInfo[user_][_slot].amount != 0) {
            amounts[2] = releasePoolInfo[user_][_slot].amount;
            times[2] = releasePoolInfo[user_][_slot].day;
            amounts[4] = releasePoolInfo[user_][_slot].claimedAmount;
        } else {
            if (times[1] == 0) {
                amounts[2] = userInfo[user_][_slot].stakeValue;
                times[2] = releaseTime[getDay(_slot)];
            }
        }

        amounts[3] = calculateRelease(_slot, user_);

        times[0] =
            userInfo[user_][_slot].stakeTime +
            userInfo[user_][_slot].lockTime;

        bools[0] = isStake[user_];
        bools[1] = status;
        // times = [start, end, _releaseTime];
        // amounts = [slot,toclaim,total, toRelease, claimedRelease ]
    }
}