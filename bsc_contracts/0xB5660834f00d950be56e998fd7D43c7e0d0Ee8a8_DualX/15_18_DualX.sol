// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";

/**
 * Website: https://DualX.co
 * Telegram channel: https://t.me/DualXNews
 * Hashtag: #DualX
 */

contract DualX is DataStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    constructor(
        uint256 _enterPrice,
        uint256 _maxOldUsers,
        uint256 _maxPoint,
        address _backupOwner,
        address _DUXOwner,
        IERC20 _DPT
    ) {
        DUX = new DualXNFT(_DUXOwner, address(this));
        DPT = _DPT; 
        owner = _backupOwner;
        maxOldUsers = _maxOldUsers;
        maxPoint = _maxPoint;
        enterPrice = _enterPrice;
        _lotteryFractions = [
            100 * 10 ** 18, 
            25 * 10 ** 18
        ];
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

        EnumerableSet.AddressSet storage rewardCandidates = _rewardCandidates[rcIndex];
        
        uint256 depth = _userData[userAddr].depth;
        for (uint256 i; i < depth; i++) {
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance++;
                } else {
                    _userData[upAddr].rightVariance--;
                    if(_userData[upAddr].todayPoints < maxPoint) {
                        _userData[upAddr].todayPoints++;
                        todayTotalPoint++;
                        rewardCandidates.add(upAddr);
                    }
                }
                _userData[upAddr].allLeftDirect++;
            } else {
                if(_userData[upAddr].leftVariance == 0) {
                    _userData[upAddr].rightVariance++;
                } else {
                    _userData[upAddr].leftVariance--;
                    if(_userData[upAddr].todayPoints < maxPoint) {
                        _userData[upAddr].todayPoints++;
                        todayTotalPoint++;
                        rewardCandidates.add(upAddr);
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

        EnumerableSet.AddressSet storage rewardCandidates = _rewardCandidates[rcIndex];

        address userAddr;
        for(uint256 i; i < rewardCandidates.length(); i++) {
            userAddr = rewardCandidates.at(i);
            uint256 userPoints = _userData[userAddr].todayPoints;

            DPT.transfer(userAddr, userPoints * pointValue);
            DUX.safeMint(userAddr);

            delete _userData[userAddr].todayPoints;
        }
        delete todayTotalPoint;
        _resetRewardCandidates();

        DPT.transfer(writer, clickReward);
        _rewardLottery(lotteryValue);

        DPT.transfer(owner, balanceDPT());
    }    

    function checkCanReward24(address writer) public view returns(bool) {
        require(
            _userData[writer].todayPoints > 0,
            "You Dont Have Any Points Today"
        );
        require(
            block.timestamp > lastRun + 24 hours,
            "The Reward_24 Time Has Not Come"
        );
        return true;
    }

    function _rewardLottery(uint256 lotteryValue) internal {
        EnumerableSet.AddressSet storage lotteryCandidates = _lotteryCandidates[lcIndex];
        EnumerableSet.AddressSet storage lotteryWinners = _lotteryWinners[lwIndex];

        _resetLotteryWinners();

        address writer = msg.sender;

        if(lotteryValue > 0 && todayLotteryCandidatesCount() > 0) {
            uint256 candidatesCount;
            uint256 randIndex;
            address winner;
            uint256 nonce;
            uint256 lotteryFraction;
            for (uint256 i; i < _lotteryFractions.length; i++) {
                lotteryFraction = _lotteryFractions[i];
                while(lotteryValue >= lotteryFraction) {
                    candidatesCount = todayLotteryCandidatesCount();
                    if(candidatesCount > 0) {
                        lotteryValue -= lotteryFraction;
                        randIndex = uint256(keccak256(abi.encodePacked(
                            block.timestamp, writer, nonce
                        ))) % candidatesCount;
                        nonce++;
                        winner = lotteryCandidates.at(randIndex);
                        lotteryCandidates.remove(winner);
                        lotteryWinners.add(winner);
                        DPT.transfer(winner, lotteryFraction);
                    }
                }
            }              
        }
        _resetLotteryCandidates();
    }

    function registerInLottery(uint256 tokenId) public {
        address userAddr = msg.sender;
        require(
            _userData[userAddr].todayPoints == 0,
            "You Have Points Today"
        );
        require(
            registered[userAddr],
            "This address is not registered in Smart Binary Contract!"
        );
        require(
            DUX.ownerOf(tokenId) == userAddr,
            "You are not owner of this token!"
        );

        DUX.burn(tokenId);

        _lotteryCandidates[lcIndex].add(userAddr);
    }

    function emergency72() public {
        require(msg.sender == owner, "Just Owner Can Run This Order!");
        require(
            block.timestamp > lastRun + 72 hours,
            "The X_Emergency_72 Time Has Not Come"
        );
        DPT.transfer(owner, balanceDPT());
    }

    function uploadOldUsers(
        address userAddr,
        address upAddr
    ) public {
        require(msg.sender == owner, "Just Owner Can Run This Order!");
        require(userCount < maxOldUsers, "The number of old users is over!");

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