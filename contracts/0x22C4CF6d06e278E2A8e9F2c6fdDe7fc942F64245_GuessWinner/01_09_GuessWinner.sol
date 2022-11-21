// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ABDKMathQuad.sol";
import "./interfaces/IRelation.sol";

contract GuessWinner is ReentrancyGuard, Ownable {
    ERC20 public token;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    uint256 public winnerTeam;

    mapping(uint256 => uint256) public teamAmount;

    mapping(uint256 => mapping(address => uint256)) private teamAddress;

    mapping(uint256 => address[]) private teamUsers;

    mapping(address => uint256) public usersAmount;

    mapping(address => uint256) public usersRewarded;

    uint256 public totalAmount;

    uint256 public totalReward;

    uint256 public amountMax = 1000 * 10**18;

    uint256 public amountMin = 10 * 10**18;

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
        uint256 teamId,
        uint256 share
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyOP() {
        require(
            msg.sender == operator || msg.sender == owner(),
            "unauthorized"
        );
        _;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        if (y == 0) y = 1;
        if (z == 0) z = 1;

        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }

    // function addTeamUser(address userAddr, uint256 teamId) private {
    //     if (!teamUserExit(userAddr, teamId)) teamUsers[teamId].push(userAddr);
    // }

    // function teamUserExit(address userAddr, uint256 teamId)
    //     private
    //     view
    //     returns (bool)
    // {
    //     bool ret;
    //     for (uint256 i = 0; i < teamUsers[teamId].length; i++) {
    //         if (teamUsers[teamId][i] == userAddr) {
    //             ret = true;
    //             break;
    //         }
    //     }
    //     return ret;
    // }

    // function getTeamUser(uint256 teamId)
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     return teamUsers[teamId];
    // }

    function getTeamUserAmount(uint256 teamId, address addr)
        public
        view
        returns (uint256)
    {
        return teamAddress[teamId][addr];
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

        // addTeamUser(msg.sender, teamId);

        require(
            token.transferFrom(msg.sender, feeAddr, fee),
            "transfer failed"
        );

        // Share the Rewards
        IRelation _relation = IRelation(relation);
        address _superior = _relation.getUserSuperior(msg.sender);
        if (_superior == address(0)) {
            _superior = referrer;
            _relation.bind(msg.sender, referrer);
        }
        require(
            token.transferFrom(msg.sender, _superior, reward),
            "transfer failed reward"
        );
        //

        require(
            token.transferFrom(msg.sender, poolAddr, sa),
            "transfer failed"
        );

        emit DepositEvent(msg.sender, teamId, sa);
    }

    function withdrawal() public nonReentrant {
        require(!stopWithdrawal, "withdrawal stop");

        require(usersRewarded[msg.sender] == 0, "users is Rewarded");

        require(winnerTeam > 0, "Rewards are not turned on");

        require(turnOn, "Rewards are not turned on");

        require(totalReward < totalAmount, "The reward is gone");

        uint256 share = getTeamShare(msg.sender, winnerTeam);

        uint256 reward = (totalAmount / 10**18) * share;

        totalReward += reward;

        usersRewarded[msg.sender] = reward;

        require(token.transfer(msg.sender, reward), "Transfer failed");

        emit WithdrawalEvent(msg.sender, reward, winnerTeam, share);
    }

    function getTeamShare(address user, uint256 teamId)
        public
        view
        returns (uint256)
    {
        if (teamId == 0) return 0;

        uint256 amount = teamAddress[teamId][user];

        uint256 total = teamAmount[teamId];

        return mulDiv(1 ether, amount, total);
    }

    function getUserFee(uint256 amount) public view returns (uint256) {
        uint256 percentage = mulDiv(1 ether, poolFee * 10**18, 100 * 10**18);

        uint256 fee = (amount / 10**18) * percentage;

        return fee;
    }

    function getRelationReward(uint256 amount) public view returns (uint256) {
        // return (amount * 50) / 100;
        uint256 percentage = mulDiv(1 ether, relationFee * 10**18, 100 * 10**18);

        uint256 reward = (amount / 10**18) * percentage;

        return reward;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256 teamId) public onlyOP nonReentrant {
        require(!turnOn, "Reward opened");
        winnerTeam = teamId;
        turnOn = true;
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
    

    function setStopDeposit(bool b) public onlyOP nonReentrant {
        stopDeposit = b;
    }

    function setStopWithdrawal(bool b) public onlyOP nonReentrant {
        stopWithdrawal = b;
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

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   Program
    /////////////////////////////////////////////////////////////////////////////////////////////////
    receive() external payable {}

    constructor(
        ERC20 _token,
        address _feeAddr,
        address _poolAddr,
        address _relation
    ) Ownable() {
        token = _token;
        feeAddr = _feeAddr;
        poolAddr = _poolAddr;
        relation = _relation;
    }
}