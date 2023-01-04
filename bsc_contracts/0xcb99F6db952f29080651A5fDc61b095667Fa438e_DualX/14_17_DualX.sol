// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";

/**
 * Website: https://DualX.co
 * Telegram channel: https://t.me/DualXNews
 * Hashtag: #DualX
 */

contract DualX is DataStorage {
    
    function version() external pure returns(string memory) {
        return "2.3.9";
    }

    constructor(
        uint256 _enterPrice,
        uint256 _maxDualXmembers,
        uint256 _maxPoint,
        address _backupOwner,
        address _DUXOwner,
        IERC20 _DPT
    ) {
        DUX = new DualXNFT(_DUXOwner, address(this));
        DPT = _DPT; 
        owner = _backupOwner;
        maxDualXmembers = _maxDualXmembers;
        maxPoint = _maxPoint;
        enterPrice = _enterPrice;
        lastRun = block.timestamp;
    }

    function register(address upAddr) public {
        address userAddr = msg.sender;

        checkCanRegister(userAddr, upAddr);
        registered[userAddr] = true;

        DPT.transferFrom(
            userAddr,
            address(this),
            enterPrice
        ); 
        
        _newUserId(userAddr);
        _newNode(userAddr, upAddr);
        _setDirects(userAddr, upAddr);

        DUX.safeMint(userAddr);
    }

    function checkCanRegister(address userAddr, address upAddr) public view returns(bool) {
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            userAddr != upAddr,
            "You can not enter your own address!"
        );
        require(
            !registered[userAddr],
            "This address is already registered!"
        );
        require(
            registered[upAddr],
            "This Upline address is Not Exist!"
        );
        return true;
    }

    function _newUserId(address userAddr) internal {
        idToAddr[userCount] = userAddr;
        addrToId[userAddr] = userCount;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr) internal {
        _userData[userAddr] = NodeData (
            0,
            0,
            0,
            0,
            _userData[upAddr].depth + 1,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
    }

    function _setDirects(address userAddr, address upAddr) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;

        address[] storage rewardCandidates = _rewardCandidates[rcIndex];
        
        uint256 depth = _userData[userAddr].depth;
        for (uint256 i; i < depth; i++) {
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance++;
                } else {
                    _userData[upAddr].rightVariance--;
                    uint8 todayPoints = _userTodayPoints[pIndex][upAddr];
                    if(todayPoints < maxPoint) {
                        if(todayPoints == 0) {
                            rewardCandidates.push(upAddr);
                        }
                        _userTodayPoints[pIndex][upAddr]++;
                        todayTotalPoint++;
                    }
                }
                _userData[upAddr].allLeftDirect++;
            } else {
                if(_userData[upAddr].leftVariance == 0) {
                    _userData[upAddr].rightVariance++;
                } else {
                    _userData[upAddr].leftVariance--;
                    uint8 todayPoints = _userTodayPoints[pIndex][upAddr];
                    if(todayPoints < maxPoint) {
                        if(todayPoints == 0) {
                            rewardCandidates.push(upAddr);
                        }
                        _userTodayPoints[pIndex][upAddr]++;
                        todayTotalPoint++;
                    }
                }
                _userData[upAddr].allRightDirect++;
            }
            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }
    }

    function reward24() public {
        address writer = msg.sender;

        checkCanReward24(writer);

        lastRewardWriter = writer;
        lastRun = block.timestamp;

        uint256 todayBalance = balanceDPT();
        allPayments += todayBalance;

        uint256 pointValue = todayEveryPointValue();
        uint256 lotteryValue = todayLotteryValue();
        uint256 clickReward = todayWriterReward();

        address[] storage rewardCandidates = _rewardCandidates[rcIndex];

        address userAddr;
        uint256 len = rewardCandidates.length;
        for(uint256 i; i < len; i++) {
            userAddr = rewardCandidates[i];
            DPT.transfer(userAddr, _userTodayPoints[pIndex][userAddr] * pointValue);
            DUX.safeMint(userAddr);
        }
        delete todayTotalPoint;
        _resetUserPoints();
        _resetRewardCandidates();

        DPT.transfer(writer, clickReward);
        _rewardLottery(lotteryValue);

        DPT.transfer(owner, balanceDPT());
    }    

    function checkCanReward24(address writer) public view returns(bool) {
        require(
            _userTodayPoints[pIndex][writer] > 0,
            "You Dont Have Any Points Today"
        );
        require(
            block.timestamp > lastRun + 1430 minutes,
            "The Reward_24 Time Has Not Come"
        );
        return true;
    }


    function _rewardLottery(uint256 lotteryValue) internal {
        _resetLotteryWinners();
        
        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 lotteryReward1 = 100 * 10 ** 18;
        uint256 lotteryReward2 = 25 * 10 ** 18;

        uint256 candidatesCount = todayLotteryCandidatesCount();

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, msg.sender, candidatesCount
        )));
        address winner;
        uint256 nonce;
        while (
            lotteryValue >= lotteryReward1 &&
            candidatesCount > 0 
        ) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, nonce++))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            lotteryValue -= lotteryReward1;
            DPT.transfer(winner, lotteryReward1);
        }
        while (
            lotteryValue >= lotteryReward2 &&
            candidatesCount > 0 
        ) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, nonce++))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            lotteryValue -= lotteryReward2;
            DPT.transfer(winner, lotteryReward2);
        }
        _resetLotteryCandidates();
    }

    function registerInLottery(uint256 tokenId) public {
        address userAddr = msg.sender;
        require(
            _userTodayPoints[pIndex][userAddr] == 0,
            "You Have Points Today"
        );
        require(
            registered[userAddr],
            "This address is not registered in DualX Contract!"
        );
        require(
            DUX.ownerOf(tokenId) == userAddr,
            "You are not owner of this token!"
        );
        DUX.burn(tokenId);
        _lotteryCandidates[lcIndex].push(userAddr);
    }

    function retrieve() public {
        require(msg.sender == owner, "Just Owner Can Run This Order!");
        require(
            block.timestamp > lastRun + 5 days,
            "The retrieve 5 days Time Has Not Come"
        );
        DPT.transfer(owner, balanceDPT());
    }

    function dualXmember(
        address upAddr,
        address userAddr
    ) public {
        require(msg.sender == owner, "Just Owner Can Run This Order!");
        require(userCount < maxDualXmembers, "The number of old users is over!");

        if(userCount != 0) {
            require(
                _userData[upAddr].childs < 2,
                "This address have two directs and could not accept new members!"
            );
            require(
                userAddr != upAddr,
                "You can not enter your own address!"
            );
            require(
                !registered[userAddr],
                "This address is already registered!"
            ); 
            require(
                registered[upAddr],
                "This Upline address is Not Exist!"
            );
            _newNode(userAddr, upAddr);
            _setDirects(userAddr, upAddr);
        }
        registered[userAddr] = true;
        allPayments += enterPrice;

        _newUserId(userAddr);
        DUX.safeMint(userAddr);
    }
}