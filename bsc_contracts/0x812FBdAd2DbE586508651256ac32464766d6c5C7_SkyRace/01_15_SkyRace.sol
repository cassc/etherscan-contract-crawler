// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SkyRace is ERC721URIStorage, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string public QuizURI;
    IERC20 public platformToken;
    IERC20 public usdtToken;
    uint256 public nftPrice;
    uint256 public maxNFTGroupCount;
    uint256 public platformTax;
    uint256 public oneLevelTax;
    uint256 public twoLevelTax;
    uint256 public threeLevelTax;
    uint256 public platformAmount;
    uint256 public minDeposit;
    uint256 public maxRoomTax;
    uint256 public nftSupply;

    struct QuizItem {
        uint256 status;
        uint256 result;
        uint256 allowCreationTime;
        uint256 beginTime;
        uint256 endTime;
    }

    struct RoomItem {
        uint256 quizID;
        uint256 oddsType;
        uint256 odds;
        uint256 nftID;
        address creator;
        uint256 resultOneTotal;
        uint256 resultTwoTotal;
        uint256 resultOneFixedOdds;
        uint256 resultTwoFixedOdds;
        uint256 roomDeposit;
        uint256 nowRoomNumber;
        uint256 maxRoomNumber;
        uint256 roomTax;
        uint256 minUserJoinAmount;
    }

    struct UserRecord {
        uint256 quizID;
        uint256 roomID;
        uint256 amount;
        uint256 result;
        uint256 withdrawalState;
    }

    mapping (address => bool) private operators;
    mapping (uint256 => QuizItem) public quizList;
    mapping (uint256 => RoomItem) public roomList;
    mapping (uint256 => uint256) public ntfGroupInfo;
    mapping (address => UserRecord[]) public userRecordList;
    mapping (address => address) public userList;
    mapping (address => address) public userLeaderList;
    mapping (address => bool) public isLeader;
    mapping (address => bool) public topAddress;

    event LogReceived(address, uint);
    event LogFallback(address, uint);
    event LogCreatQuizRoom(address, uint);
    event LogAddMargin(address, uint, uint);

    constructor() ERC721("SkyRace", "SkyRace") {
        platformToken = IERC20(0x0DBEb7df568fb4cf91a62C1D9F6D1c29ED95693E);
        usdtToken = IERC20(0x55d398326f99059fF775485246999027B3197955);
        nftPrice = 399000000000000000000;
        minDeposit = 1000000000000000000000;
        maxNFTGroupCount = 1000;
        platformTax = 10;
        oneLevelTax = 10;
        twoLevelTax = 10;
        threeLevelTax = 10;
        maxRoomTax = 60;
        nftSupply = 59;
        QuizURI = "https://www.skycompetition.co/api/app/nft/mini/NFT?tokenId=";
    }

    function setQuizURI (string memory _uri) public onlyOwner {
        QuizURI = _uri;
    }

    function setNftSupply (uint256 _nftSupply) public onlyOwner {
        nftSupply = _nftSupply;
    }


    function setNFTPrice (uint256 _price) public onlyOwner {
        nftPrice = _price;
    }


    function setMinDeposit (uint256 _minDeposit) public onlyOwner {
        minDeposit = _minDeposit;
    }


    function setTopAddress(address _address, bool _bool) public onlyOwner {
        topAddress[_address] = _bool;
    }


    function setLeaderAddress(address _address, bool _bool) public onlyOwner {
        isLeader[_address] = _bool;
    }


    function serOperators(address _address, bool _bool) public onlyOwner {
        operators[_address] = _bool;
    }


    function setPlatformToken (IERC20 _token) public onlyOwner {
        platformToken = _token;
    }


    function setUsdtToken (IERC20 _token) public onlyOwner {
         usdtToken = _token;
    }


    function setMaxNFTGroupCount (uint256 _maxNFTGroupCount) public onlyOwner {
        maxNFTGroupCount = _maxNFTGroupCount;
    }


    function setInvite (address _address, address _invite) public onlyOwner {
        userList[_address] = _invite;
    }


    function setLeader (address _address, address _leader) public onlyOwner {
        userLeaderList[_address] = _leader;
    }


    function setTax (uint256 _index, uint256 _tax) public onlyOwner {
        if (_index == 0) {
            platformTax = _tax;
        }
        else if (_index == 1) {
            oneLevelTax = _tax;
        }
        else if (_index == 2) {
            twoLevelTax = _tax;
        }
        else if (_index == 3) {
            threeLevelTax = _tax;
        }
        else if (_index == 5) {
            maxRoomTax = _tax;
        }
    }


    function getInvite (address _address) public view returns(address) {
        return userList[_address];
    }

    function getLeader (address _address) public view returns(address) {
        return userLeaderList[_address];
    }


    function mintNFT () public returns (uint256) {

        uint256 newItemId = _tokenIds.current();

        require(userList[msg.sender] != address(0), "Please register first");
        require(nftSupply >= newItemId, "Over supply");

        usdtToken.safeTransferFrom(msg.sender, address(this), nftPrice);

        _tokenIds.increment();
        
        _mint(msg.sender, newItemId);

        return newItemId;
    }


    function userRegister (address _address) public {
        require(userList[msg.sender] == address(0), "You have been registered");
        require(topAddress[_address] || userList[_address] != address(0), "The inviter has an incorrect address");

        if (isLeader[_address]) {
            userLeaderList[msg.sender] = _address;
        }
        else if (userLeaderList[_address] != address(0)) {
            userLeaderList[msg.sender] = userLeaderList[_address];
        }

        userList[msg.sender] = _address;
    }


    function createQuizProject (uint256 _quizID, uint256 _beginTime, uint256 _endTime, uint256 _allowCreationTime) public {
        require(operators[msg.sender], "Operators only");
        require(quizList[_quizID].status == 0, "The ID has been occupied");
        require(_beginTime < _endTime, "Time anomaly");

        quizList[_quizID].status = 1;
        quizList[_quizID].beginTime = _beginTime;
        quizList[_quizID].endTime = _endTime;
        quizList[_quizID].allowCreationTime = _allowCreationTime;
    }


    function editQuizProject (uint256 _quizID, uint256 _beginTime, uint256 _endTime, uint256 _result, uint256 _allowCreationTime) public {
        require(operators[msg.sender], "Operators only");
        require(quizList[_quizID].status == 1, "The ID has been occupied");
        require(_beginTime < _endTime, "Time anomaly");
        
        quizList[_quizID].beginTime = _beginTime;
        quizList[_quizID].endTime = _endTime;
        quizList[_quizID].result = _result;
        quizList[_quizID].allowCreationTime = _allowCreationTime;
    }


    function createQuizRoom (uint256 _roomId, uint256 _quizID, uint256 _nftID, uint256 _oddsType, uint256 _maxRoomNumber, uint256 _roomTax, uint256 _minUserJoinAmount, uint256 _resultOneFixedOdds, uint256 _resultTwoFixedOdds, uint256 _roomDeposit) public {
        require(roomList[_roomId].quizID == 0, "Room ID already exists");
        require(ownerOf(_nftID) == msg.sender, "You are not the owner");
        require(quizList[_quizID].status == 1, "Abnormal state");
        require(block.timestamp >= quizList[_quizID].allowCreationTime && block.timestamp < quizList[_quizID].endTime, "Out of time");
        require(ntfGroupInfo[_nftID] < maxNFTGroupCount, "The number of groups exceeds the upper limit");
        require(_roomTax <= maxRoomTax, "Room Tax exceeds the limit");

        if (_oddsType == 2) {
            require(_roomDeposit >= minDeposit, "It needs to be more than the minimum amount");
            platformToken.safeTransferFrom(msg.sender, address(this), _roomDeposit);
            roomList[_roomId].resultOneFixedOdds = _resultOneFixedOdds;
            roomList[_roomId].resultTwoFixedOdds = _resultTwoFixedOdds;
            roomList[_roomId].roomDeposit = _roomDeposit;
        }

        ntfGroupInfo[_nftID] = ntfGroupInfo[_nftID] + 1;

        roomList[_roomId].quizID = _quizID;
        roomList[_roomId].creator = msg.sender;
        roomList[_roomId].oddsType = _oddsType;
        roomList[_roomId].nftID = _nftID;
        roomList[_roomId].maxRoomNumber = _maxRoomNumber;
        roomList[_roomId].roomTax = _roomTax;
        roomList[_roomId].minUserJoinAmount = _minUserJoinAmount;

        emit LogCreatQuizRoom(msg.sender, _roomId);
    }


    function editQuizRoom (uint256 _roomId, uint256 _maxRoomNumber, uint256 _minUserJoinAmount) public {
        require(roomList[_roomId].creator == msg.sender, "Not Creator");
        roomList[_roomId].maxRoomNumber = _maxRoomNumber;
        roomList[_roomId].minUserJoinAmount = _minUserJoinAmount;
    }


    function addMargin (uint256 _roomId, uint256 _amount) public {
        require(roomList[_roomId].oddsType == 2, "Types of abnormal");
        platformToken.safeTransferFrom(msg.sender, address(this), _amount);
        roomList[_roomId].roomDeposit = roomList[_roomId].roomDeposit + _amount;

        emit LogAddMargin(msg.sender, _roomId, _amount);
    }


    function creatorWithdrawalMargin (uint256 _roomId, uint256 _amount, uint256 _withdrawalType) public {
        require(roomList[_roomId].oddsType == 2, "Types of abnormal");
        require(roomList[_roomId].creator == msg.sender, "Not Creator");

        uint256 _quizID = roomList[_roomId].quizID;
        require(block.timestamp >= quizList[_quizID].endTime, "Out of time");

        if (roomList[_roomId].resultOneTotal == 0 || roomList[_roomId].resultTwoTotal == 0) {
             platformToken.safeTransfer(msg.sender, roomList[_roomId].roomDeposit);
        }
        else {
            if (_withdrawalType == 1) {
                uint256 _oneFinal = roomList[_roomId].resultOneTotal + roomList[_roomId].roomDeposit - _amount;
                require(_oneFinal * roomList[_roomId].resultTwoFixedOdds == roomList[_roomId].resultTwoTotal * roomList[_roomId].resultOneFixedOdds, "The amount is wrong [1]");
                platformToken.safeTransfer(msg.sender, _amount);
                roomList[_roomId].roomDeposit = roomList[_roomId].roomDeposit - _amount;
            } 
            else if (_withdrawalType == 2) {
                uint256 _twoFinal = roomList[_roomId].resultTwoTotal + roomList[_roomId].roomDeposit - _amount;
                require(roomList[_roomId].resultOneTotal * roomList[_roomId].resultTwoFixedOdds == _twoFinal * roomList[_roomId].resultOneFixedOdds, "The amount is wrong [2]");
                platformToken.safeTransfer(msg.sender, _amount);
                roomList[_roomId].roomDeposit = roomList[_roomId].roomDeposit - _amount;
            }
        }
    }


    function userJoin (uint256 _roomId, uint256 _amount, uint256 _result) public {
        require(userList[msg.sender] != address(0), "Please register first");
        require(_result > 0 && _result < 3, "The betting result is wrong");
        require(roomList[_roomId].nowRoomNumber < roomList[_roomId].maxRoomNumber, "Exceeding the number limit");
        require(_amount >= roomList[_roomId].minUserJoinAmount, "Less than the minimum participation quota");

        uint256 _quizID = roomList[_roomId].quizID;
        require(block.timestamp >= quizList[_quizID].beginTime && block.timestamp < quizList[_quizID].endTime, "It's not in the time frame");


        if (roomList[_roomId].oddsType == 2) {
            if (_result == 1) {
                uint256 _oneEexpected = roomList[_roomId].resultOneTotal + _amount;
                uint256 _twoEexpected = roomList[_roomId].resultTwoTotal + roomList[_roomId].roomDeposit;

                require((_oneEexpected * roomList[_roomId].resultTwoFixedOdds) <= (roomList[_roomId].resultOneFixedOdds * _twoEexpected), "The amount exceeded the odds limit [1]");
            }
            else if (_result == 2) {
                uint256 _oneEexpected = roomList[_roomId].resultOneTotal + roomList[_roomId].roomDeposit;
                uint256 _twoEexpected = roomList[_roomId].resultTwoTotal + _amount;

                require((_twoEexpected * roomList[_roomId].resultOneFixedOdds) <= (_oneEexpected * roomList[_roomId].resultTwoFixedOdds), "The amount exceeded the odds limit [2]");
            }
        }

        platformToken.safeTransferFrom(msg.sender, address(this), _amount);

        if (_result == 1) {
            roomList[_roomId].resultOneTotal = roomList[_roomId].resultOneTotal + _amount;
        }
        else if (_result == 2) {
            roomList[_roomId].resultTwoTotal = roomList[_roomId].resultTwoTotal + _amount;
        }

        userRecordList[msg.sender].push(
            UserRecord({
                quizID: _quizID,
                roomID: _roomId,
                amount: _amount,
                result: _result,
                withdrawalState: 0
            })
        );

        roomList[_roomId].nowRoomNumber = roomList[_roomId].nowRoomNumber + 1;
    }


    function userWithdrawal (address _address, uint256[] memory _indexList) public {
        require(_indexList.length > 0, "Abnormal data");

        uint256 _totalAmount = 0;
        uint256 _oneLevelTotalAmount;
        uint256 _twoLevelTotalAmount;
        uint256 _threeLevelTotalAmount;
        uint256 _platformTotalAmount;

        for (uint256 _index = 0; _index < _indexList.length; _index = _index + 1) {

            uint256 _recordIndex = _indexList[_index];
            uint256 _quizID = userRecordList[_address][_recordIndex].quizID;
            uint256 _roomID = userRecordList[_address][_recordIndex].roomID;
            uint256 _amount = userRecordList[_address][_recordIndex].amount;

            require(userRecordList[_address][_recordIndex].withdrawalState == 0, "Abnormal recording status");

            if (roomList[_roomID].resultOneTotal == 0 || roomList[_roomID].resultTwoTotal == 0) {
                if (block.timestamp > quizList[_quizID].endTime && quizList[_quizID].result != 0) {
                    _totalAmount = _totalAmount + _amount;
                }
                updateRecordState(_address, _recordIndex);
            }
            else if (quizList[_quizID].result == userRecordList[_address][_recordIndex].result) {

                uint256 _winAmount = getWinAmount(_roomID, quizList[_quizID].result, _amount);

                uint256 _roomAmount = 0;

                if (roomList[_roomID].roomTax > 0) {
                    _roomAmount = _winAmount / 1000 * roomList[_roomID].roomTax;
                    platformToken.safeTransfer(roomList[_roomID].creator, _roomAmount);
                }

                _platformTotalAmount = _platformTotalAmount + _winAmount / 1000 * platformTax;
                _oneLevelTotalAmount = _oneLevelTotalAmount + _winAmount / 1000 * oneLevelTax;
                _twoLevelTotalAmount = _twoLevelTotalAmount + _winAmount / 1000 * twoLevelTax;
                _threeLevelTotalAmount = _threeLevelTotalAmount + _winAmount / 1000 * threeLevelTax;

                _totalAmount = _totalAmount + _amount + _winAmount - _roomAmount;
                updateRecordState(_address, _recordIndex);
            }
        }

        platformAmount = platformAmount + _platformTotalAmount;

        _totalAmount = _totalAmount - _oneLevelTotalAmount - _twoLevelTotalAmount - _threeLevelTotalAmount;
        platformToken.safeTransfer(_address, _totalAmount);

        levelBonus(_oneLevelTotalAmount, _twoLevelTotalAmount, _threeLevelTotalAmount, _address);
    }


    function getWinAmount (uint256 _roomID, uint256 _result, uint256 _amount) public view returns (uint256) {
        uint256 _winAmount = 0;
        if (roomList[_roomID].oddsType == 1) {
            if (_result == 1) {
                _winAmount = _amount * roomList[_roomID].resultTwoTotal / roomList[_roomID].resultOneTotal;
            }
            else if (_result == 2) {
                _winAmount = _amount * roomList[_roomID].resultOneTotal / roomList[_roomID].resultTwoTotal;
            }
        }
        else if (roomList[_roomID].oddsType == 2) {
            if (_result == 1) {
                _winAmount = _amount * roomList[_roomID].resultTwoFixedOdds / roomList[_roomID].resultOneFixedOdds;
            }
            else if (_result == 2) {
                _winAmount = _amount * roomList[_roomID].resultOneFixedOdds / roomList[_roomID].resultTwoFixedOdds;
            }
        }
        return _winAmount;
    }


    function updateRecordState (address _address, uint256 _recordIndex) private {
        userRecordList[_address][_recordIndex].withdrawalState = 1;
    }

    function levelBonus (uint256 _oneLevelTotalAmount, uint256 _twoLevelTotalAmount, uint256 _threeLevelTotalAmount, address _address) private {

        address _levelOneAddress = userList[_address];

         if (_oneLevelTotalAmount > 0) {
            platformToken.safeTransfer(_levelOneAddress, _oneLevelTotalAmount);
        }

        if (_twoLevelTotalAmount > 0) {

            address _levelTwoAddress = userList[_levelOneAddress];

            if (_levelTwoAddress != address(0)) {
                platformToken.safeTransfer(_levelTwoAddress, _twoLevelTotalAmount);
            }
            else {
                platformAmount = platformAmount + _twoLevelTotalAmount;
            }

            if (_threeLevelTotalAmount > 0) {

                address _levelThreeAddress = userList[_levelTwoAddress];

                if (_levelThreeAddress != address(0)) {
                    platformToken.safeTransfer(_levelThreeAddress, _threeLevelTotalAmount);
                } else {
                    platformAmount = platformAmount + _threeLevelTotalAmount;
                }
            }
        }
    }


    function platformWithdrawal (address _to) public onlyOwner {
        platformToken.safeTransfer(_to, platformAmount);
        platformAmount = 0;
    }


    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }


    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
}