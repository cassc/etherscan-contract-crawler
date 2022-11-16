// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface ISkyRace {
    function getInvite(address) external view returns (address);
    function getLeader(address) external view returns (address);
}


contract SkyIDO is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public platformToken;
    IERC20 public usdtToken;
    ISkyRace public skyRace;

    uint256 public minJoinAmount = 100000000000000000000;
    uint256 public maxJoinAmount = 2000000000000000000000;
    uint256 public maxUserAmount = 10000000000000000000000;
    uint256 public idoProportion = 1000;
    uint256 public withdrawalPhaseOne = 400;
    uint256 public withdrawalPhaseTwo = 300;
    uint256 public withdrawalPhaseThree = 300;
    uint256 public inviteBonus = 100;
    uint256 public leaderBonus = 300;

    uint256 public idoDeadline = 1671120001;
    uint256 public phaseTwoTime = 1671120001;
    uint256 public phaseThreeTime = 1673798401;

    struct UserInfo {
        uint256 totalJoin;
        uint256 phaseOne;
        uint256 phaseTwo;
        uint256 phaseThree;
    }

    struct RecordInfo {
        uint256 recordType;
        uint256 amount;
        uint256 time;
    }

    mapping (address => UserInfo) public userList;
    mapping (address => RecordInfo[]) public recordList;

    event LogReceived(address, uint);
    event LogFallback(address, uint);


    constructor() {
        platformToken = IERC20(0x0DBEb7df568fb4cf91a62C1D9F6D1c29ED95693E);
        usdtToken = IERC20(0x55d398326f99059fF775485246999027B3197955);
        skyRace = ISkyRace(0x812FBdAd2DbE586508651256ac32464766d6c5C7);
    }


    function setAmount (uint256 _index, uint256 _amount) public onlyOwner {
        if (_index == 0) {
            minJoinAmount = _amount;
        }
        else if (_index == 1) {
            maxJoinAmount = _amount;
        }
        else if (_index == 2) {
            minJoinAmount = _amount;
        }
        else if (_index == 3) {
            idoProportion = _amount;
        }
        else if (_index == 4) {
            withdrawalPhaseOne = _amount;
        }
        else if (_index == 5) {
            withdrawalPhaseTwo = _amount;
        }
        else if (_index == 6) {
            withdrawalPhaseThree = _amount;
        }
        else if (_index == 7) {
            inviteBonus = _amount;
        }
        else if (_index == 8) {
            leaderBonus = _amount;
        }
    }


    function setTime (uint256 _index, uint256 _time) public onlyOwner {
        if (_index == 0) {
            phaseTwoTime = _time;
        }
        else if (_index == 1) {
            phaseThreeTime = _time;
        }
        else if (_index == 3) {
            idoDeadline = _time;
        }
    }


    function setPlatformToken (IERC20 _token) public onlyOwner {
        platformToken = _token;
    }


    function setUsdtToken (IERC20 _token) public onlyOwner {
        usdtToken = _token;
    }


    function setSkyRace (address _address) public onlyOwner {
        skyRace = ISkyRace(_address);
    }


    function getRecordList (address _address) public view returns (RecordInfo[] memory) {
        return recordList[_address];
    }


    function IDO (uint256 _joinAmount) public {
        require(skyRace.getInvite(msg.sender) != address(0), "Please register first");
        require(block.timestamp <= idoDeadline, "IDO has come to an end");
        require(_joinAmount >= minJoinAmount && _joinAmount <= maxJoinAmount, "Amount of abnormal[1]");
        require((userList[msg.sender].totalJoin + _joinAmount) <= maxUserAmount, "Amount of abnormal[2]");

        usdtToken.safeTransferFrom(msg.sender, address(this), _joinAmount);

        uint256 _inviteAmount = _joinAmount * inviteBonus / 1000;
        usdtToken.safeTransfer(skyRace.getInvite(msg.sender), _inviteAmount);

        recordList[skyRace.getInvite(msg.sender)].push(
            RecordInfo({
                recordType: 5,
                amount: _inviteAmount,
                time: block.timestamp
            })
        );

        if (skyRace.getLeader(msg.sender) != address(0)) {
            uint256 _leaderAmount = _joinAmount * leaderBonus / 1000;
            usdtToken.safeTransfer(skyRace.getLeader(msg.sender), _leaderAmount);
            recordList[skyRace.getLeader(msg.sender)].push(
                RecordInfo({
                    recordType: 6,
                    amount: _leaderAmount,
                    time: block.timestamp
                })
            );
        }

        uint256 _phaseOne = _joinAmount * idoProportion * withdrawalPhaseOne / 1000;
        uint256 _phaseTwo = _joinAmount * idoProportion * withdrawalPhaseTwo / 1000;
        uint256 _phaseThree = _joinAmount * idoProportion * withdrawalPhaseThree / 1000;

        platformToken.safeTransfer(msg.sender, _phaseOne);

        userList[msg.sender].totalJoin = userList[msg.sender].totalJoin + _joinAmount;
        userList[msg.sender].phaseOne = userList[msg.sender].phaseOne + _phaseOne;
        userList[msg.sender].phaseTwo = userList[msg.sender].phaseTwo + _phaseTwo;
        userList[msg.sender].phaseThree = userList[msg.sender].phaseThree + _phaseThree;

        recordList[msg.sender].push(
            RecordInfo({
                recordType: 1,
                amount: _joinAmount,
                time: block.timestamp
            })
        );

        recordList[msg.sender].push(
            RecordInfo({
                recordType: 2,
                amount: _phaseOne,
                time: block.timestamp
            })
        );
    }


    function userWithdrawal (uint256 _phase) public {
        if (_phase == 2) {
            require(block.timestamp >= phaseTwoTime, "Time not to [2]");

            recordList[msg.sender].push(
                RecordInfo({
                    recordType: 3,
                    amount: userList[msg.sender].phaseTwo,
                    time: block.timestamp
                })
            );

            platformToken.safeTransfer(msg.sender, userList[msg.sender].phaseTwo);
            userList[msg.sender].phaseTwo = 0;
            
        }
        else if (_phase == 3) {
            require(block.timestamp >= phaseThreeTime, "Time not to [3]");

            recordList[msg.sender].push(
                RecordInfo({
                    recordType: 4,
                    amount: userList[msg.sender].phaseThree,
                    time: block.timestamp
                })
            );

            platformToken.safeTransfer(msg.sender, userList[msg.sender].phaseThree);
            userList[msg.sender].phaseThree = 0;
        }
    }


    function ownerOperation (uint256 _amount, address _to) public onlyOwner {
        platformToken.safeTransfer(_to, _amount);
    }

    function ownerOperationU (uint256 _amount, address _to) public onlyOwner {
        usdtToken.safeTransfer(_to, _amount);
    }


    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }


    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
}