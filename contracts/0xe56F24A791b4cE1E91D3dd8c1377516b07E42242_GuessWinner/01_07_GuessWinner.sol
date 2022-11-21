// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRelation.sol";


contract GuessWinner is ReentrancyGuard {

    IERC20 public _usdt;
    using SafeERC20 for IERC20;

    address public owner;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    uint256 public winnerTeam;

    mapping(uint256 => uint256) public teamAmount;

    mapping(uint256 => mapping(address => uint256)) private teamAddress;

    mapping(address => uint256) public usersAmount;

    mapping(address => uint256) public usersRewarded;

    uint256 public totalAmount;

    uint256 public totalReward;

    uint256 public amountMax = 1000000000;

    uint256 public amountMin = 10000000;

    uint256 public poolFee = 4;
    uint256 public relationFee = 4;

    address public feeAddr;
    address public poolAddr;

    bool public turnOn;
    bool public stopDeposit;
    bool public stopWithdrawal;

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   event
    /////////////////////////////////////////////////////////////////////////////////////////////////

    event DepositEvent(address userAddr, uint256 teamId, uint256 amount);
    event WithdrawalEvent(
        address userAddr,
        uint256 reward,
        uint256 teamId
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyOP() {
        require(
            msg.sender == operator || msg.sender == owner,
            "OP: unauthorized"
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

    function deposit(
        uint256 teamId,
        uint256 amount,
        address referrer
    ) public nonReentrant {
        require(!turnOn, "deposit off");

        require(!stopDeposit, "deposit stop");

        require(teamId >= 1 && teamId <= 32, "Team id error");

        require(amount >= amountMin, "Amount less");

        require(
            (usersAmount[msg.sender] + amount) <= amountMax,
            "Amount limit"
        );

        uint256 fee = getUserFee(amount);
        uint256 reward = getRelationReward(amount);
        uint256 sa = amount - (fee + reward);

        teamAmount[teamId] += sa;
        totalAmount += sa;

        teamAddress[teamId][msg.sender] += sa;

        usersAmount[msg.sender] += amount;

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

        emit DepositEvent(msg.sender, teamId, sa);
    }

    function withdrawal() public nonReentrant {
        require(!stopWithdrawal, "withdrawal stop");

        require(usersRewarded[msg.sender] == 0, "users is Rewarded");

        require(winnerTeam > 0, "Rewards are not turned on");

        require(turnOn, "Rewards are not turned on");

        require(totalReward < totalAmount, "The reward is gone");

        uint256 reward = getUserWithdrawal(msg.sender);

        totalReward += reward;

        usersRewarded[msg.sender] = reward;

        _usdt.safeTransfer(msg.sender, reward);

        emit WithdrawalEvent(msg.sender, reward, winnerTeam);
    }

    function getTeamShare(address user, uint256 teamId)
        public
        view
        returns (uint256)
    {
        if (teamId == 0) return 0;

        uint256 amount = teamAddress[teamId][user];

        uint256 total = teamAmount[teamId];

        return (amount / total) + 1000000;
    }

    function getUserFee(uint256 amount) public view returns (uint256) {
        return (amount * poolFee) / 100;
    }

    function getRelationReward(uint256 amount) public view returns (uint256) {
        return (amount * relationFee) / 100;
    }

    function getUserWithdrawal(address user) public view returns (uint256) {
        uint256 share = getTeamShare(user, winnerTeam);
        uint256 reward = (totalAmount * share) / 1000000;
        return reward;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256 teamId) public onlyOP {
        require(!turnOn, "Reward opened");
        winnerTeam = teamId;
        turnOn = true;
    }

    function setUserAmount(uint256 _amountMax, uint256 _amountMin)
        public
        onlyOP
    {
        amountMax = _amountMax;
        amountMin = _amountMin;
    }

    function setPoolFee(uint256 _poolFee) public onlyOP {
        poolFee = _poolFee;
    }

    function setRelationFee(uint256 _relationFee) public onlyOP {
        relationFee = _relationFee;
    }
    

    function setStopDeposit(bool b) public onlyOP {
        stopDeposit = b;
    }

    function setStopWithdrawal(bool b) public onlyOP {
        stopWithdrawal = b;
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