// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRelation.sol";

contract GuessScore is ReentrancyGuard {
    IERC20 public _usdt;
    using SafeERC20 for IERC20;

    address public owner;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    struct TeamStruct {
        mapping(address => mapping(bytes32 => uint256)) usersScore;
        mapping(address => uint256) usersAmount;
        mapping(address => uint256) usersRewarded;
        mapping(address => bool) userFirstDeposit;
        mapping(bytes32 => uint256) usersNumber;
        mapping(bytes32 => uint256) depositCount;
        mapping(bytes32 => uint256) scoreAmount;
        uint256 totalAmount;
        uint256 totalReward;
        bool turnOn;
        bool stopDeposit;
        bool stopWithdrawal;
        bytes32 score;
    }

    mapping(bytes32 => TeamStruct) private teamsData;
    mapping(bytes32 => uint256[2]) private teamsScore;

    uint256 public amountMax = 1000000000;

    uint256 public amountMin = 10000000;

    uint256 public poolFee = 4;
    uint256 public relationFee = 4;

    address public feeAddr;
    address public poolAddr;

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   event
    /////////////////////////////////////////////////////////////////////////////////////////////////

    event DepositEvent(
        address userAddr,
        uint256[2] teamIds,
        uint256[2] scores,
        uint256 amount
    );
    event WithdrawalEvent(
        address userAddr,
        uint256 reward,
        uint256[2] teamIds,
        uint256[2] scores
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////



    modifier onlyOP() {
        require(
            msg.sender == operator || msg.sender == owner,
            "unauthorized"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == operator || msg.sender == owner,
            "ADMIN: unauthorized"
        );
        _;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   play
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function arryToHash(uint256[2] memory _n) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n[0], _n[1]));
    }

    function getTeamUserDepoistAmount(uint256[2] memory teamIds, address user)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].usersAmount[user];
    }

    function getTeamUserscoreAmount(
        uint256[2] memory teamIds,
        address user,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return
            teamsData[arryToHash(teamIds)].usersScore[user][arryToHash(scores)];
    }

    function getTeamTotalAmount(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalAmount;
    }

    function getTeamTotalReward(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalReward;
    }

    function getTeamTurnOn(uint256[2] memory teamIds)
        public
        view
        returns (bool)
    {
        return teamsData[arryToHash(teamIds)].turnOn;
    }

    function getTeamScore(uint256[2] memory teamIds)
        public
        view
        returns (uint256[2] memory)
    {
        return teamsScore[arryToHash(teamIds)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   play
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function deposit(
        uint256[2] memory teamIds,
        uint256 amount,
        uint256[2] memory scores,
        address referrer
    ) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        require(!teamsData[teamId].turnOn, "deposit off");

        require(!teamsData[teamId].stopDeposit, "deposit stop");

        require(amount >= amountMin, "Amount less");

        require(
            (teamsData[teamId].usersAmount[msg.sender] + amount) <= amountMax,
            "Amount limit"
        );

        uint256 fee = getUserFee(amount);
        uint256 reward = getRelationReward(amount);
        uint256 sa = amount - (fee + reward);

        teamsData[teamId].usersScore[msg.sender][score] += sa;

        teamsData[teamId].totalAmount += sa;

        teamsData[teamId].usersAmount[msg.sender] += amount;

        if (!teamsData[teamId].userFirstDeposit[msg.sender]) {
            teamsData[teamId].usersNumber[score]++;
        } else {
            teamsData[teamId].userFirstDeposit[msg.sender] = true;
        }
        teamsData[teamId].depositCount[score]++;
        teamsData[teamId].scoreAmount[score] += sa;

        // Share the Rewards
        IRelation _relation = IRelation(relation);
        address _superior = _relation.getUserSuperior(msg.sender);
        if (_superior == address(0)) {
            _superior = referrer;
            _relation.bind(msg.sender, referrer);
        }

        _usdt.safeTransferFrom(msg.sender, feeAddr, fee);
        _usdt.safeTransferFrom(msg.sender, _superior, reward);
        _usdt.safeTransferFrom(msg.sender, poolAddr, sa);
        //

        emit DepositEvent(msg.sender, teamIds, scores, amount);
    }

    function withdrawal(uint256[2] memory teamIds) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = teamsData[teamId].score;

        require(!teamsData[teamId].stopWithdrawal, "withdrawal stop");

        require(
            teamsData[teamId].usersRewarded[msg.sender] == 0,
            "users is Rewarded"
        );

        require(teamsData[teamId].turnOn, "Rewards are not turned on");

        require(
            teamsData[teamId].totalReward < teamsData[teamId].totalAmount,
            "The reward is gone"
        );


        uint256 reward = getUserWithdrawal(msg.sender, teamId, score);

        teamsData[teamId].totalReward += reward;

        teamsData[teamId].usersRewarded[msg.sender] = reward;

        _usdt.safeTransfer(msg.sender, reward);

        emit WithdrawalEvent(
            msg.sender,
            reward,
            teamIds,
            teamsScore[teamId]
        );
    }

    function getTeamShare(
        address user,
        bytes32 teamId,
        bytes32 score
    ) public view returns (uint256) {
        if (teamId == 0) return 0;

        uint256 amount = teamsData[teamId].usersScore[user][score];

        uint256 total = teamsData[teamId].scoreAmount[score];

        return (amount / total) + 1000000;
    }

    function getUserFee(uint256 amount) public view returns (uint256) {
        return (amount * poolFee) / 100;
    }

    function getRelationReward(uint256 amount) public view returns (uint256) {
        return (amount * relationFee) / 100;
    }

    function getUserWithdrawal(address user, bytes32 teamId, bytes32 score) public view returns (uint256) {
        uint256 share = getTeamShare(user, teamId, score);
        uint256 reward = (teamsData[teamId].totalAmount * share) / 1000000;
        return reward;
    }

    function getScoreTeamDepostitCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].usersNumber[arryToHash(scores)];
    }

    function getScoreDepositCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].depositCount[arryToHash(scores)];
    }

    function getTeamScoreAmount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].scoreAmount[arryToHash(scores)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256[2] memory teamIds, uint256[2] memory scores)
        public
        onlyOP
        nonReentrant
    {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        teamsScore[teamId] = scores;

        teamsData[teamId].score = score;
        teamsData[teamId].turnOn = true;
    }

    function setUserAmount(uint256 _amountMax, uint256 _amountMin)
        public
        onlyOP
        nonReentrant
    {
        amountMax = _amountMax;
        amountMin = _amountMin;
    }

    function setPoolFee(uint256 _poolFee) public onlyOP nonReentrant {
        poolFee = _poolFee;
    }

    function setRelationFee(uint256 _relationFee) public onlyOP nonReentrant {
        relationFee = _relationFee;
    }

    function setStopDeposit(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopDeposit = b;
    }

    function setStopWithdrawal(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopWithdrawal = b;
    }

    function setFeeAddr(address _feeAddr) public onlyOP {
        feeAddr = _feeAddr;
    }

    function setPoolAddr(address _poolAddr) public onlyOP {
        poolAddr = _poolAddr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   manager
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function setOperators(address to) public onlyOwner {
        operator = to;
    }

    function setRelationAddr(address _relation) public onlyOwner {
        relation = _relation;
    }

    function setUsdtAddr(address _token) public onlyOwner {
        _usdt = IERC20(_token);
    }

    function emergency(address to, uint256 amount) public onlyOwner {
        _usdt.safeTransfer(to, amount);
    }

    function setOwner(address _addr) public onlyOwner {
        owner = _addr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   Program
    /////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        IERC20 _token,
        address _feeAddr,
        address _poolAddr,
        address _relation
    ) {
        owner = msg.sender;
        _usdt = _token;
        feeAddr = _feeAddr;
        poolAddr = _poolAddr;
        relation = _relation;
    }
}