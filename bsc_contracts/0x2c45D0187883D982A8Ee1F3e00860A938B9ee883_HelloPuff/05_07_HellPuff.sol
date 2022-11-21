// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IBurnableERC721.sol';
import '../core/SafeOwnable.sol';

contract HelloPuff is SafeOwnable {

    event SignIn(address user, uint timestamp, uint loop, uint score);
    event BurnReward(uint nonce, address user, IERC721 nft, uint rewardId);

    uint public immutable BEGIN_TIME = 36000;
    uint public constant MAX_LOOP = 7;
    uint public immutable interval;

    uint public startAt;
    uint public finishAt;
    uint[] public scoreInfo;
    mapping(address => uint) public userCrycle;
    mapping(address => uint) public userLoop;
    mapping(address => uint) public userScores;
    mapping(IERC721 => mapping(uint => uint)) public nftCrycle;
    uint public totalScores;
    uint public nonce;
    mapping(IERC721 => bool) public supportNfts;

    constructor(uint _startAt, uint _finishAt, uint _interval, IERC721[] memory _supportNfts, uint[] memory _scores) {
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal startAt or finishAt");
        startAt = _startAt;
        finishAt = _finishAt;
        require(_interval != 0, "interval is zero");
        interval = _interval;
        for (uint i = 0; i < _supportNfts.length; i ++) {
            supportNfts[_supportNfts[i]] = true;
        }
        require(_scores.length == MAX_LOOP, "illegal score num");
        scoreInfo.push(0);
        for (uint i = 0; i < _scores.length; i ++) {
            scoreInfo.push(_scores [i]);
        }
    }

    function getScoreInfo() external view returns(uint[] memory) {
        return scoreInfo;
    }

    function setTimeInfo(uint _startAt, uint _finishAt) external onlyOwner {
        if (_startAt != 0) {
            require(_startAt > block.timestamp, "illegal startAt");
            startAt = _startAt;
        }
        if (_finishAt != 0) {
            require(_finishAt > startAt, "illegal startAt or finishAt");
            finishAt = _finishAt;
        }
    }

    function setScore(uint _loop, uint _newScore) external onlyOwner {
        require(_loop > 0 && _loop <= MAX_LOOP, "illegal loop");
        scoreInfo[_loop] = _newScore;
    }

    function setSupportNft(IERC721 _supportNft, bool _support) external onlyOwner {
        if (_support) {
            require(!supportNfts[_supportNft], "already support");
            supportNfts[_supportNft] = true;
        } else {
            require(supportNfts[_supportNft], "not supported this nft");
            delete supportNfts[_supportNft];
        }
    }

    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }
    
    modifier NotFinish() {
        require(block.timestamp <= finishAt, "already finish");
        _;
    }

    function timeToCrycle(uint _timestamp) public view returns(uint _crycle) {
        return (_timestamp - BEGIN_TIME) / interval;
    }

    function signIn() external AlreadyBegin NotFinish {
        uint crycle = timeToCrycle(block.timestamp);
        uint lastCrycle = userCrycle[msg.sender];
        require(crycle > lastCrycle, "already signIn");
        uint loop = 1;
        if (crycle - lastCrycle == 1) {
            if (userLoop[msg.sender] >= MAX_LOOP) {
                loop = 1;
            } else {
                loop = userLoop[msg.sender] + 1;
            }
        } else {
            loop = 1; 
        }
        uint score = scoreInfo[loop];
        userCrycle[msg.sender] = crycle;
        userLoop[msg.sender] = loop;
        userScores[msg.sender] += score;
        totalScores += score;
        emit SignIn(msg.sender, block.timestamp, loop, score);
    }

    function signInInfo(address _user) external view returns(bool available, uint loop) {
        if (block.timestamp < startAt || block.timestamp > finishAt) {
            return (false, 0);
        }
        uint crycle = timeToCrycle(block.timestamp);
        if (crycle == userCrycle[_user]) {
            return (false, userLoop[_user]);
        } else if (crycle - userCrycle[_user] > 1) {
            return (true, 1);
        } else if (userLoop[_user] >= MAX_LOOP) {
            return (true, 1);
        } else {
            return (true, userLoop[_user] + 1);
        }
    }

    function strengthen(IERC721 _strengthenNft, uint _rewardId) external AlreadyBegin NotFinish {
        require(supportNfts[_strengthenNft], "nft not support");
        require(_strengthenNft.ownerOf(_rewardId) == msg.sender, "illegal owner");
        uint crycle = timeToCrycle(block.timestamp);
        uint lastCrycle = nftCrycle[_strengthenNft][_rewardId];
        require(crycle > lastCrycle, "already signIn");
        nonce ++;
        nftCrycle[_strengthenNft][_rewardId] = crycle;
        emit BurnReward(nonce, msg.sender, _strengthenNft, _rewardId);
    }

    function strengthenInfo(IERC721 _strengthenNft, uint _rewardId) external view returns(bool available) {
        uint crycle = timeToCrycle(block.timestamp);
        return  crycle > nftCrycle[_strengthenNft][_rewardId];
    }
}