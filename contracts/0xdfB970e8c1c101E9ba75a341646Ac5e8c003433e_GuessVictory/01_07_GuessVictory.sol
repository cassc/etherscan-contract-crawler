// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRelation.sol";

contract GuessVictory is ReentrancyGuard {
    IERC20 public _usdt;
    using SafeERC20 for IERC20;

    address public owner;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    struct TeamStruct {
        mapping(uint256 => uint256) flatAmount;
        mapping(address => mapping(uint256 => uint256)) usersFlat;
        mapping(address => uint256) usersAmount;
        mapping(address => uint256) usersRewarded;
        address[] users;
        uint256 totalAmount;
        uint256 totalReward;
        bool turnOn;
        bool stopDeposit;
        bool stopWithdrawal;
        uint256 flat;
    }

    mapping(uint256 => TeamStruct) private teamsData;

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
        uint256 teamId,
        uint256 amount,
        uint256 flat
    );
    event WithdrawalEvent(
        address userAddr,
        uint256 reward,
        uint256 teamId,
        uint256 flat
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyOP() {
        require(
            operator == msg.sender || msg.sender == owner,
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
    function getTeamUserDepoistAmount(uint256 teamId, address user)
        public
        view
        returns (uint256)
    {
        return teamsData[teamId].usersAmount[user];
    }

    function getTeamUserFlatAmount(
        uint256 teamId,
        address user,
        uint256 flat
    ) public view returns (uint256) {
        return teamsData[teamId].usersFlat[user][flat];
    }

    function getTeamFlatPool(uint256 teamId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            teamsData[teamId].flatAmount[1],
            teamsData[teamId].flatAmount[2],
            teamsData[teamId].flatAmount[3]
        );
    }

    function getTeamTotalAmount(uint256 teamId) public view returns (uint256) {
        return teamsData[teamId].totalAmount;
    }

    function getTeamTotalReward(uint256 teamId) public view returns (uint256) {
        return teamsData[teamId].totalReward;
    }

    function getTeamTurnOn(uint256 teamId) public view returns (bool) {
        return teamsData[teamId].turnOn;
    }

    function getTeamlat(uint256 teamId) public view returns (uint256) {
        return teamsData[teamId].flat;
    }


    function addTeamUser(address userAddr, uint256 teamId) private {
        if (!teamUserExit(userAddr, teamsData[teamId].users))
            teamsData[teamId].users.push(userAddr);
    }

    function teamUserExit(address userAddr, address[] memory users)
        private
        pure
        returns (bool)
    {
        bool ret;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == userAddr) {
                ret = true;
                break;
            }
        }
        return ret;
    }


    function getTeamUser(uint256 teamId)
        public
        view
        returns (address[] memory)
    {
        return teamsData[teamId].users;
    }


    function deposit(
        uint256 teamId,
        uint256 amount,
        uint256 flat,
        address referrer
    ) public nonReentrant {
        require(!teamsData[teamId].turnOn, "deposit off");

        require(!teamsData[teamId].stopDeposit, "deposit stop");

        require(teamId >= 1 && teamId <= 100000000, "Team id error");

        require(flat > 0 && flat <= 3, "flat error");

        require(amount >= amountMin, "Amount less");

        require(
            (teamsData[teamId].usersAmount[msg.sender] + amount) <= amountMax,
            "Amount limit"
        );

        uint256 fee = getPercentage(amount, poolFee);
        uint256 reward = getPercentage(amount, relationFee);
        uint256 sa = amount - (fee + reward);

        teamsData[teamId].usersFlat[msg.sender][flat] += sa;

        teamsData[teamId].flatAmount[flat] += sa;

        teamsData[teamId].totalAmount += sa;

        teamsData[teamId].usersAmount[msg.sender] += amount;

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

        addTeamUser(msg.sender, teamId);

        emit DepositEvent(msg.sender, teamId, sa, flat);
    }

    function withdrawal(uint256 teamId) public nonReentrant {
        uint256 flat = teamsData[teamId].flat;

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

        uint256 reward = getUserWithdrawal(msg.sender, teamId, flat);

        teamsData[teamId].totalReward += reward;

        teamsData[teamId].usersRewarded[msg.sender] = reward;

        _usdt.safeTransfer(msg.sender, reward);

        emit WithdrawalEvent(msg.sender, reward, teamId, flat);
    }

    function getTeamShare(
        address user,
        uint256 teamId,
        uint256 flat
    ) public view returns (uint256) {
        if (teamId == 0) return 0;

        uint256 amount = teamsData[teamId].usersFlat[user][flat];

        uint256 total = teamsData[teamId].flatAmount[flat];

        return (amount / total) + 1000000;
    }

    function getPercentage(uint256 amount, uint256 parameter) public pure returns (uint256) {
        return (amount * parameter) / 100;
    }

    function getUserWithdrawal(address user, uint256 teamId, uint256 flat) public view returns (uint256) {
        uint256 share = getTeamShare(user, teamId, flat);
        uint256 reward = (teamsData[teamId].totalAmount * share) / 1000000;
        return reward;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256 teamId, uint256 flat)
        public
        onlyOP
        nonReentrant
    {
        require(flat > 0 && flat <= 3, "flat error");
        teamsData[teamId].flat = flat;
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

    function setStopDeposit(uint256 teamId, bool b) public onlyOP nonReentrant {
        teamsData[teamId].stopDeposit = b;
    }

    function setStopWithdrawal(uint256 teamId, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[teamId].stopWithdrawal = b;
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