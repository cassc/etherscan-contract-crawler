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

contract CCCNetwork {
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

    bool public buyOnCCC;
    bool public sellOnCCC;
    bool public stakingOn;
    
    uint256 public cccTocnrFee;
    uint256 public burnFee;
    uint256 public refPer;

    address public owner;
    address public devAddress;
    address public communityFund;
    address public communityDevelopmentFund;
    address public rewardWallet;
    address public founderWallet;

    uint256 public minCNRBuy;
    uint256 public maxCNRBuy;
    uint256 public minCCCSell;
    uint256 public maxCCCSell;

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
        uint256 totalCNR,
        uint256 totalCCC,
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
    IBEP20 private cnrToken;
    IBEP20 private cccToken;
    
    constructor(
        address ownerAddress,
        address _devAddress,
        address _communityFund,
        address _communityDevelopmentFund,
        address _rewardWallet,
        address _founderWallet,
        IBEP20 _cccToken,
        IBEP20 _cnrToken
    ) {
        owner = ownerAddress;
        devAddress = _devAddress;
        communityFund = _communityFund;
        communityDevelopmentFund = _communityDevelopmentFund;
        rewardWallet = _rewardWallet;
        founderWallet = _founderWallet;
        cnrToken = _cnrToken;
        cccToken = _cccToken;
        rewardCapping = 5;
       

        buyOnCCC = true;
        sellOnCCC = true;
        stakingOn = true;

        stakingPrograms_.push(Program(42857143, 7*60*60*24, 42857143));

        users[ownerAddress].id=1;
        idToAddress[1] = ownerAddress;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }


    function updateFee(uint256 _cccTocnrFee) public {
        require(msg.sender == owner, "Only Owner!");
        cccTocnrFee = _cccTocnrFee;
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
        require(((tokenQty >= 2000 * 1e18) && (tokenQty <= 100000 * 1e18)), "Minimum 2000 CNR and Maximum 100000 CNR");
       
        if (!isUserExists(msg.sender)) {
            registration(msg.sender, referrer, _position);
        }

        require(isUserExists(msg.sender), "user not exists");
        require(
            users[msg.sender].nextWithdrawDate < block.timestamp,
            "Staking already exist!"
        );
        cnrToken.transferFrom(msg.sender, address(this), tokenQty);
        uint256 cccQty = (tokenQty * 1e18) / getCCCPrice();

       
            uint256 refIncome = (cccQty * refPer) / 100;
            if (
                users[users[msg.sender].referrer].restRefIncome > 0 &&
                users[users[msg.sender].referrer].nextWithdrawDate >
                block.timestamp
            ) {
                if (
                    users[users[msg.sender].referrer].restRefIncome > refIncome
                ) {
                    cccToken.transfer(users[msg.sender].referrer, refIncome);
                    users[users[msg.sender].referrer]
                        .restRefIncome -= refIncome;
                    emit ReferralReward(
                        users[msg.sender].referrer,
                        msg.sender,
                        0,
                        refIncome
                    );
                } else {
                    cccToken.transfer(
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
        

        uint256 globalQty = (cccQty * 3) / 100;
        uint256 founderQty = (cccQty * 1) / 100;
        
        
        cnrToken.transfer(communityDevelopmentFund, (tokenQty * burnFee) / 100);
        cccToken.transfer(rewardWallet, globalQty);
        cccToken.transfer(founderWallet, founderQty);
        
        uint256 programCount = users[msg.sender].programCount;

        users[msg.sender].programs[programCount].programId = _programId;
        users[msg.sender].programs[programCount].stakingDate = block.timestamp;
        users[msg.sender].programs[programCount].lastWithdrawalDate = block
            .timestamp;
        users[msg.sender].programs[programCount].staking = tokenQty;
        users[msg.sender].programs[programCount].currentRewards = 0;
        users[msg.sender].programs[programCount].isExpired = false;
        users[msg.sender].programs[programCount].stakingToken = cccQty;
        users[msg.sender].programs[programCount].stakingType = 1;
        users[msg.sender].programCount = users[msg.sender].programCount.add(1);
        users[msg.sender].nextWithdrawDate = block.timestamp + 30 days;
        users[msg.sender].totalStakingToken = users[msg.sender]
            .totalStakingToken
            .add(cccQty);
        uint256 treward = cccQty + ((cccQty * 30) / 100);
        uint256 newRefReward = (cccQty * rewardCapping) - treward;
        users[msg.sender].restRefIncome = 0;
        users[msg.sender].restRefIncome += newRefReward;
        emit CycleStarted(
            msg.sender,
            users[msg.sender].programCount,
            tokenQty,
            cccQty,
            1
        );
    }

   

    function swapCNRtoCCC(uint256 cnrQty) public payable notContract {
        require(buyOnCCC, "Buy Stopped.");
        require(cnrQty>=minCNRBuy && cnrQty<=maxCNRBuy, "Invalid Quantity");
        uint256 totalCCC = getCNRtoCCC(cnrQty);
        cnrToken.transferFrom(msg.sender, address(this), cnrQty);
        cccToken.transfer(msg.sender, totalCCC);
        emit TokenDistribution(
            address(this),
            msg.sender,
            cnrToken,
            cccToken,
            cnrQty,
            totalCCC
        );
    }

    function swapCCCtoCNR(uint256 cccQty) public payable notContract {
        require(sellOnCCC, "Sell Stopped.");
        require(cccQty>=minCCCSell && cccQty<=maxCCCSell, "Invalid Quantity");
        
        uint256 cnrBal = cnrToken.balanceOf(address(this));
        uint256 cccBal = cccToken.balanceOf(address(this));
        uint256 totalCNR = cnrBal.sub(
            (cnrBal.mul(cccBal)).div(cccBal.add(cccQty))
        );
        uint256 ded = (totalCNR * cccTocnrFee) / 100;
        cccToken.transferFrom(msg.sender, address(this), cccQty);
        if (ded > 0) {
            cnrToken.transfer(communityFund, ded);
        }
        cnrToken.transfer(msg.sender, (totalCNR-ded));
        emit TokenDistribution(
            msg.sender,
            address(this),
            cccToken,
            cnrToken,
            cccQty,
            totalCNR
        );
    }

    function getCNRtoCCC(uint256 cnrQty) public view returns (uint256) {
        uint256 cnrBal = cnrToken.balanceOf(address(this));
        uint256 cccBal = cccToken.balanceOf(address(this));
        uint256 cccOut = cccBal.sub(
            (cnrBal.mul(cccBal)).div(cnrBal.add(cnrQty))
        );
        return cccOut;
    }

    function getCCCtoCNR(uint256 cccQty) public view returns (uint256, uint256) {
        uint256 ded = (cccQty * cccTocnrFee) / 100;
        uint256 cnrBal = cnrToken.balanceOf(address(this));
        uint256 cccBal = cccToken.balanceOf(address(this));
        uint256 cnrOut = cnrBal.sub(
            (cnrBal.mul(cccBal)).div(cccBal.add(cccQty).sub(ded))
        );
        uint256 cnrOutWoFee = cnrBal.sub(
            (cnrBal.mul(cccBal)).div(cccBal.add(cccQty))
        );
        return (cnrOut, cnrOutWoFee);
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
                    (j == 1 && stake >= 4999e18) ||
                    (j < 3 && stake >= 9999e18) ||
                    (j < 5 && stake >= 24999e18) ||
                    (j < 8 && stake >= 49999e18) ||
                    (stake >= 99999e18)
                ) {
                    uint256 refBonus = (amount.mul(REFERRAL_PERCENTS[j - 1]))
                        .div(100);
                    if (
                        users[referrerAddress].restRefIncome > 0 &&
                        users[referrerAddress].nextWithdrawDate >
                        block.timestamp
                    ) {
                        if (users[referrerAddress].restRefIncome > refBonus) {
                            cccToken.transfer(referrerAddress, refBonus);
                            users[referrerAddress].restRefIncome -= refBonus;
                            emit ReferralReward(
                                referrerAddress,
                                msg.sender,
                                j,
                                refBonus
                            );
                        } else {
                            cccToken.transfer(
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
            cccToken.transfer(msg.sender,withdrawalAmount);
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

    function getCCCPrice() public view returns (uint256) {
        return ((cnrToken.balanceOf(address(this)) * 1e18) /
            cccToken.balanceOf(address(this)));
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
                        (((_amount * (_dailyInterestRate + index)) / 10000000000) *
                            INTEREST_CYCLE) /
                        (60*60*24);
                } else {
                    break;
                }
            }

            result +=
                (((_amount.mul(_dailyInterestRate)).div(10000000000)) * secondsLeft) /
                (60*60*24);

            return result;
        } else {
            return
                (((_amount * _dailyInterestRate) / 10000000000) * (_now - _start)) /
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

    function switchBuyCCC(bool e) public {
        require(msg.sender == owner, "Only Owner");
        buyOnCCC = e;
    }

    function switchSellCCC(bool e) public {
        require(msg.sender == owner, "Only Owner");
        sellOnCCC = e;
    }

    function updateMinMax(uint256 _minCNRBuy, uint256 _maxCNRBuy, uint256 _minCCCSell, uint256 _maxCCCSell) public payable
    {
        require(msg.sender==owner,"Only Owner"); 
        minCNRBuy = _minCNRBuy;
        maxCNRBuy = _maxCNRBuy;
        minCCCSell = _minCCCSell;
        maxCCCSell = _maxCCCSell;
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