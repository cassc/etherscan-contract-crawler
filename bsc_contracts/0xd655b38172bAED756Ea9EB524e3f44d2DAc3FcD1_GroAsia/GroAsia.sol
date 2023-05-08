/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract GroAsia {
    using SafeMath for uint256;

    struct Staking {
        uint256 programId;
        uint256 stakingDate;
        uint256 staking;
        uint256 lastWithdrawalDate;
        uint256 currentRewards;
        bool isExpired;
        uint256 stakingToken;
        bool isAddedStaked;
        uint8 stakingType;
    }

    struct Program {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }

    struct User {
        uint id;
        address referrer;
        uint256 programCount;
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        mapping(uint256 => Staking) programs;
        uint256 referralCount;
        uint256 nextWithdrawDate;
        uint256 restRefIncome;
        uint8 position;
    }

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    Program[] private stakingPrograms_;

    uint256[] public REFERRAL_PERCENTS = [10, 5, 5, 5, 10, 10, 10, 15, 15, 15];

    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;

    uint256 public rewardCapping;

    uint256 public total_staking_token;

    uint256 public total_withdraw_token;

    bool public buyOnGRO;
    bool public sellOnGRO;
    bool public stakingOn;
    
    uint256 public groTognrFee;
    uint256 public burnFee;
    uint256 public refPer;

    address public owner;
    address public devAddress;
    address public communityFund;
    address public communityDevelopmentFund;
    address public rewardWallet;

    uint256 public minGNRBuy;
    uint256 public maxGNRBuy;
    uint256 public minGROSell;
    uint256 public maxGROSell;

    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId,
        uint8 position // 1 left, 2 right
    );
    event CycleStarted(
        address indexed user,
        uint256 stakeID,
        uint256 totalGNR,
        uint256 totalGRO,
        uint256 stakingType
    );
    event TokenDistribution(
        address sender,
        address receiver,
        IBEP20 tokenFirst,
        IBEP20 tokenSecond,
        uint256 tokenIn,
        uint256 tokenOut
    );
    event onWithdraw(address _user, uint256 withdrawalAmountToken);
    event ReferralReward(
        address _user,
        address _from,
        uint8 level,
        uint256 reward
    );
    IBEP20 private gnrToken;
    IBEP20 private groToken;
    
    constructor(
        address ownerAddress,
        address _devAddress,
        address _communityFund,
        address _communityDevelopmentFund,
        address _rewardWallet,
        IBEP20 _groToken,
        IBEP20 _gnrToken
    ) {
        owner = ownerAddress;
        devAddress = _devAddress;
        communityFund = _communityFund;
        communityDevelopmentFund = _communityDevelopmentFund;
        rewardWallet = _rewardWallet;
        gnrToken = _gnrToken;
        groToken = _groToken;
        rewardCapping = 5;
       

        buyOnGRO = true;
        sellOnGRO = true;
        stakingOn = true;

        stakingPrograms_.push(Program(5, 30*60*60*24, 5));

        users[ownerAddress].id=1;
        idToAddress[1] = ownerAddress;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }


    function updateFee(uint256 _groTognrFee) public {
        require(msg.sender == owner, "Only Owner!");
        groTognrFee = _groTognrFee;
    }

    function updateCapping(uint256 _rewardCapping) public {
        require(msg.sender == owner, "Only Owner!");
        rewardCapping = _rewardCapping;
    }

    function registration(
        address userAddress,
        address referrerAddress,
        uint8 _position
    ) private notContract {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        users[userAddress].id=lastUserId;
        users[userAddress].referrer=referrerAddress;
        //users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;
        users[referrerAddress].referralCount += 1;
        lastUserId++;
        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id,
            _position
        );
    }

    // Staking Process

    function start_staking(
        uint256 tokenQty,
        uint256 _programId,
        address referrer,
        uint8 _position
    ) public {
        require(stakingOn, "Staking Stopped.");
        require(_programId == 0, "Wrong staking program id");
        require(((tokenQty >= 5000 * 1e18) && (tokenQty <= 200000 * 1e18)), "Minimum 5000 GNR and Maximum");
       
        if (!isUserExists(msg.sender)) {           
            registration(msg.sender, referrer, _position);
        }

        require(isUserExists(msg.sender), "user not exists");
        require(
            users[msg.sender].nextWithdrawDate < block.timestamp,
            "Staking already exist!"
        );
        gnrToken.transferFrom(msg.sender, address(this), tokenQty);
        uint256 groQty = (tokenQty * 1e18) / getGROPrice();

        
            uint256 refIncome = (groQty * refPer) / 100;
            if (
                users[users[msg.sender].referrer].restRefIncome > 0 &&
                users[users[msg.sender].referrer].nextWithdrawDate >
                block.timestamp
            ) {
                if (
                    users[users[msg.sender].referrer].restRefIncome > refIncome
                ) {
                    groToken.transfer(users[msg.sender].referrer, refIncome);
                    users[users[msg.sender].referrer]
                        .restRefIncome -= refIncome;
                    emit ReferralReward(
                        users[msg.sender].referrer,
                        msg.sender,
                        0,
                        refIncome
                    );
                } else {
                    groToken.transfer(
                        users[msg.sender].referrer,
                        users[users[msg.sender].referrer].restRefIncome
                    );
                    emit ReferralReward(
                        users[msg.sender].referrer,
                        msg.sender,
                        0,
                        users[users[msg.sender].referrer].restRefIncome
                    );
                    users[users[msg.sender].referrer].restRefIncome = 0;
                }
            }
       

        
        uint256 burnQty = (groQty * 10) / 100;
        
        
        gnrToken.transfer(communityDevelopmentFund, (tokenQty * burnFee) / 100);
        groToken.transfer(rewardWallet, burnQty);
        uint256 programCount = users[msg.sender].programCount;

        users[msg.sender].programs[programCount].programId = _programId;
        users[msg.sender].programs[programCount].stakingDate = block.timestamp;
        users[msg.sender].programs[programCount].lastWithdrawalDate = block
            .timestamp;
        users[msg.sender].programs[programCount].staking = tokenQty;
        users[msg.sender].programs[programCount].currentRewards = 0;
        users[msg.sender].programs[programCount].isExpired = false;
        users[msg.sender].programs[programCount].stakingToken = groQty;
        users[msg.sender].programs[programCount].stakingType = 1;
        users[msg.sender].programCount = users[msg.sender].programCount.add(1);
        users[msg.sender].nextWithdrawDate = block.timestamp + 30 days;
        users[msg.sender].totalStakingToken = users[msg.sender]
            .totalStakingToken
            .add(groQty);
        uint256 treward = groQty + ((groQty * 30) / 100);
        uint256 newRefReward = (groQty * rewardCapping) - treward;
        users[msg.sender].restRefIncome = 0;
        users[msg.sender].restRefIncome += newRefReward;
        emit CycleStarted(
            msg.sender,
            users[msg.sender].programCount,
            tokenQty,
            groQty,
            1
        );
    }

     function start_staking_admin(
        address user,
        uint256 tokenQty,
        uint256 groQty,
        uint256 _programId,
        address referrer,
        uint256 timeStamp,
        uint8 _position
    ) public {
        require(stakingOn, "Staking Stopped.");
        require(msg.sender == devAddress || msg.sender == owner, "Only Owner!");
        require(_programId == 0, "Wrong staking program id");
        require(tokenQty >= 2000 * 1e18, "Minimum 2000 GNR");
        bool isNew;
        if (!isUserExists(user)) {
            isNew = true;
            registration(user, referrer, _position);
        }

        require(isUserExists(user), "user not exists");
        require(
            users[user].nextWithdrawDate < block.timestamp,
            "Staking already exist!"
        );

        if (isNew) {
            uint256 refIncome = (groQty * refPer) / 100;
            if (
                users[users[user].referrer].restRefIncome > 0 &&
                users[users[user].referrer].nextWithdrawDate >
                block.timestamp
            ) {
                if (
                    users[users[user].referrer].restRefIncome > refIncome
                ) {
                    users[users[user].referrer]
                        .restRefIncome -= refIncome;
                    emit ReferralReward(
                        users[user].referrer,
                        user,
                        0,
                        refIncome
                    );
                } else {
                    uint256 income=users[users[user].referrer].restRefIncome;
                    emit ReferralReward(
                        users[user].referrer,
                        user,
                        0,
                        income
                    );
                    users[users[user].referrer].restRefIncome = 0;
                }
            }
        }
      
        uint256 programCount = users[user].programCount;

        users[user].programs[programCount].programId = _programId;
        users[user].programs[programCount].stakingDate = timeStamp;
        users[user].programs[programCount].lastWithdrawalDate = timeStamp;
        users[user].programs[programCount].staking = tokenQty;
        users[user].programs[programCount].currentRewards = 0;
        users[user].programs[programCount].isExpired = false;
        users[user].programs[programCount].stakingToken = groQty;
        users[user].programs[programCount].stakingType = 1;
        users[user].programCount = users[user].programCount.add(1);
        users[user].nextWithdrawDate = timeStamp + 30 days;
        users[user].totalStakingToken = users[user]
            .totalStakingToken
            .add(groQty);
        uint256 treward = groQty + ((groQty * 30) / 100);
        uint256 newRefReward = (groQty * rewardCapping) - treward;
        users[user].restRefIncome = 0;
        users[user].restRefIncome += newRefReward;
        emit CycleStarted(
            user,
            users[user].programCount,
            tokenQty,
            groQty,
            1
        );
    }

    function swapGNRtoGRO(uint256 gnrQty) public payable notContract {
        require(buyOnGRO, "Buy Stopped.");
        require(gnrQty>=minGNRBuy && gnrQty<=maxGNRBuy, "Invalid Quantity");
        uint256 totalGRO = getGNRtoGRO(gnrQty);
        gnrToken.transferFrom(msg.sender, address(this), gnrQty);
        groToken.transfer(msg.sender, totalGRO);
        emit TokenDistribution(
            address(this),
            msg.sender,
            gnrToken,
            groToken,
            gnrQty,
            totalGRO
        );
    }

    function swapGROtoGNR(uint256 groQty) public payable notContract {
        require(sellOnGRO, "Sell Stopped.");
        require(groQty>=minGROSell && groQty<=maxGROSell, "Invalid Quantity");
        
        uint256 gnrBal = gnrToken.balanceOf(address(this));
        uint256 groBal = groToken.balanceOf(address(this));
        uint256 totalGNR = gnrBal.sub(
            (gnrBal.mul(groBal)).div(groBal.add(groQty))
        );
        uint256 ded = (totalGNR * groTognrFee) / 100;
        groToken.transferFrom(msg.sender, address(this), groQty);
        if (ded > 0) {
            gnrToken.transfer(communityFund, ded);
        }
        gnrToken.transfer(msg.sender, (totalGNR-ded));
        emit TokenDistribution(
            msg.sender,
            address(this),
            groToken,
            gnrToken,
            groQty,
            totalGNR
        );
    }

    function getGNRtoGRO(uint256 gnrQty) public view returns (uint256) {
        uint256 gnrBal = gnrToken.balanceOf(address(this));
        uint256 groBal = groToken.balanceOf(address(this));
        uint256 groOut = groBal.sub(
            (gnrBal.mul(groBal)).div(gnrBal.add(gnrQty))
        );
        return groOut;
    }

    function getGROtoGNR(uint256 groQty) public view returns (uint256, uint256) {
        uint256 ded = (groQty * groTognrFee) / 100;
        uint256 gnrBal = gnrToken.balanceOf(address(this));
        uint256 groBal = groToken.balanceOf(address(this));
        uint256 gnrOut = gnrBal.sub(
            (gnrBal.mul(groBal)).div(groBal.add(groQty).sub(ded))
        );
        uint256 gnrOutWoFee = gnrBal.sub(
            (gnrBal.mul(groBal)).div(groBal.add(groQty))
        );
        return (gnrOut, gnrOutWoFee);
    }

    function withdraw() public payable {
        require(
            msg.value == 0,
            "withdrawal doesn't allow to transfer bnb simultaneously"
        );
        require(
            block.timestamp > users[msg.sender].nextWithdrawDate,
            "Withdraw after 30 days!"
        );
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any stakings");
        uint256 withdrawalAmount = 0;
        uint256 amount = 0;
        for (uint256 i = 0; i < users[msg.sender].programCount; i++) {
            if (users[msg.sender].programs[i].isExpired) {
                continue;
            }

            Program storage program = stakingPrograms_[
                users[msg.sender].programs[i].programId
            ];

            bool isExpired = false;
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (program.term > 0) {
                uint256 endTime = users[msg.sender].programs[i].stakingDate.add(
                    program.term
                );
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    isAddedStaked = true;
                    if (users[msg.sender].programs[i].stakingType == 1)
                        withdrawalAmount += users[msg.sender]
                            .programs[i]
                            .stakingToken;
                }
            }

            amount += _calculateRewards(
                users[msg.sender].programs[i].stakingToken,
                stakingPrograms_[users[msg.sender].programs[i].programId]
                    .dailyInterest,
                withdrawalDate,
                users[msg.sender].programs[i].lastWithdrawalDate,
                stakingPrograms_[users[msg.sender].programs[i].programId]
                    .dailyInterest
            );

            users[msg.sender].programs[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].programs[i].isExpired = isExpired;
            users[msg.sender].programs[i].isAddedStaked = isAddedStaked;
            users[msg.sender].programs[i].currentRewards += amount;
        }
        address referrerAddress = users[msg.sender].referrer;
        if (msg.sender != owner) {
            for (uint8 j = 1; j <= 10; j++) {
                uint256 stake = users[referrerAddress]
                    .programs[users[referrerAddress].programCount - 1]
                    .staking;
                if (
                    (j == 1 && stake >= 9999e18) ||
                    (j < 3 && stake >= 24999e18) ||
                    (j < 5 && stake >= 49999e18) ||
                    (j < 8 && stake >= 99999e18) ||
                    (stake >= 199999e18)
                ) {
                    uint256 refBonus = (amount.mul(REFERRAL_PERCENTS[j - 1]))
                        .div(100);
                    if (
                        users[referrerAddress].restRefIncome > 0 &&
                        users[referrerAddress].nextWithdrawDate >
                        block.timestamp
                    ) {
                        if (users[referrerAddress].restRefIncome > refBonus) {
                            groToken.transfer(referrerAddress, refBonus);
                            users[referrerAddress].restRefIncome -= refBonus;
                            emit ReferralReward(
                                referrerAddress,
                                msg.sender,
                                j,
                                refBonus
                            );
                        } else {
                            groToken.transfer(
                                referrerAddress,
                                users[referrerAddress].restRefIncome
                            );
                            emit ReferralReward(
                                referrerAddress,
                                msg.sender,
                                j,
                                users[referrerAddress].restRefIncome
                            );
                            users[referrerAddress].restRefIncome = 0;
                        }
                    }
                }
                if (users[referrerAddress].referrer != address(0))
                    referrerAddress = users[referrerAddress].referrer;
                else break;
            }
        }
        withdrawalAmount = withdrawalAmount + amount;
        if (withdrawalAmount > 0) {
            groToken.transfer(msg.sender,withdrawalAmount);
            total_withdraw_token = total_withdraw_token + (withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }

    function getStakingProgramByUID(
        address _user
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            bool[] memory
        )
    {
        User storage staker = users[_user];
        uint256[] memory stakingDates = new uint256[](staker.programCount);
        uint256[] memory stakings = new uint256[](staker.programCount);
        uint256[] memory currentRewards = new uint256[](staker.programCount);
        bool[] memory isExpireds = new bool[](staker.programCount);
        uint256[] memory newRewards = new uint256[](staker.programCount);
        bool[] memory isAddedStakeds = new bool[](staker.programCount);

        for (uint256 i = 0; i < staker.programCount; i++) {
            require(staker.programs[i].stakingDate != 0, "wrong staking date");
            currentRewards[i] = staker.programs[i].currentRewards;
            isAddedStakeds[i] = staker.programs[i].isAddedStaked;
            stakingDates[i] = staker.programs[i].stakingDate;
            stakings[i] = staker.programs[i].stakingToken;

            uint256 stakingPercent = stakingPrograms_[
                staker.programs[i].programId
            ].dailyInterest;

            if (staker.programs[i].isExpired) {
                isExpireds[i] = true;
                newRewards[i] = 0;
            } else {
                isExpireds[i] = false;
                if (stakingPrograms_[staker.programs[i].programId].term > 0) {
                    if (
                        block.timestamp >=
                        staker.programs[i].stakingDate.add(
                            stakingPrograms_[staker.programs[i].programId].term
                        )
                    ) {
                        newRewards[i] = _calculateRewards(
                            staker.programs[i].stakingToken,
                            stakingPercent,
                            staker.programs[i].stakingDate.add(
                                stakingPrograms_[staker.programs[i].programId]
                                    .term
                            ),
                            staker.programs[i].lastWithdrawalDate,
                            stakingPercent
                        );
                        isExpireds[i] = true;
                    } else {
                        newRewards[i] = _calculateRewards(
                            staker.programs[i].stakingToken,
                            stakingPercent,
                            block.timestamp,
                            staker.programs[i].lastWithdrawalDate,
                            stakingPercent
                        );
                    }
                } else {
                    newRewards[i] = _calculateRewards(
                        staker.programs[i].stakingToken,
                        stakingPercent,
                        block.timestamp,
                        staker.programs[i].lastWithdrawalDate,
                        stakingPercent
                    );
                }
            }
        }

        return (
            stakingDates,
            stakings,
            currentRewards,
            newRewards,
            isExpireds,
            isAddedStakeds
        );
    }

    function getGROPrice() public view returns (uint256) {
        return ((gnrToken.balanceOf(address(this)) * 1e18) /
            groToken.balanceOf(address(this)));
    }

    function getStakingToken(
        address _user
    ) public view returns (uint256[] memory) {
        User storage staker = users[_user];
        uint256[] memory stakings = new uint256[](staker.programCount);

        for (uint256 i = 0; i < staker.programCount; i++) {
            require(staker.programs[i].stakingDate != 0, "wrong staking date");
            stakings[i] = staker.programs[i].stakingToken;
        }

        return (stakings);
    }

    function _calculateRewards(
        uint256 _amount,
        uint256 _dailyInterestRate,
        uint256 _now,
        uint256 _start,
        uint256 _maxDailyInterest
    ) private pure returns (uint256) {
        uint256 numberOfDays = (_now - _start) / INTEREST_CYCLE;
        uint256 result = 0;
        uint256 index = 0;
        if (numberOfDays > 0) {
            uint256 secondsLeft = (_now - _start);
            for (index; index < numberOfDays; index++) {
                if (_dailyInterestRate + index <= _maxDailyInterest) {
                    secondsLeft -= INTEREST_CYCLE;
                    result +=
                        (((_amount * (_dailyInterestRate + index)) / 1000) *
                            INTEREST_CYCLE) /
                        (60*60*24);
                } else {
                    break;
                }
            }

            result +=
                (((_amount.mul(_dailyInterestRate)).div(1000)) * secondsLeft) /
                (60*60*24);

            return result;
        } else {
            return
                (((_amount * _dailyInterestRate) / 1000) * (_now - _start)) /
                (60*60*24);
        }
    }

    function isContract(
        address _address
    ) public view returns (bool _isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function switchStaking(bool e) public {
        require(msg.sender == owner, "Only Owner");
        stakingOn = e;
    }

    function switchBuyGRO(bool e) public {
        require(msg.sender == owner, "Only Owner");
        buyOnGRO = e;
    }

    function switchSellGRO(bool e) public {
        require(msg.sender == owner, "Only Owner");
        sellOnGRO = e;
    }

    function updateMinMax(uint256 _minGNRBuy, uint256 _maxGNRBuy, uint256 _minGROSell, uint256 _maxGROSell) public payable
    {
        require(msg.sender==owner,"Only Owner"); 
        minGNRBuy = _minGNRBuy;
        maxGNRBuy = _maxGNRBuy;
        minGROSell = _minGROSell;
        maxGROSell = _maxGROSell;
    }

    function changeBurnFee(uint256 _fee) public {
        require(msg.sender == owner, "Only Owner");
        burnFee = _fee;
    }

    function changeRefPercent(uint256 _refPer) public {
        require(msg.sender == owner, "Only Owner");
        refPer = _refPer;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}