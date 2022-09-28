// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./coin.sol";

interface NI {
    function totalArmyAmount() external view returns (uint256);
    function checkArmyAmount(address) external view returns (uint256);
    function checkPlayers() external view returns (uint256);
    function readRefCode(address) external view returns (uint256);
    function readReferals(address) external view returns (address[] memory);
}

contract Armies is NI {
    address private Owner;
    AI private tokenContract1;
    IERC20 private tokenContract2;

    uint8 tokendecimals;


    // Army Attributes.
    uint8 constant armyPrice = 10;
    uint8 constant armyRefPerc = 5; // %
    uint256 constant armyYieldTime = 27;
    uint256 armyYield = 31250;
    bool armiespaused = false;


    // Contract Variables.
    uint256 totalArmies = 0;
    uint256 totalPlayers = 0;
    mapping(address => uint256) armyAmount;
    mapping(address => uint256) armyBonusAmount;
    mapping(address => uint256) armyTimestamp;

    mapping(address => address[]) referals;
    mapping(address => address) referrer;
    mapping(address => bool) refed;
    mapping(address => bool) refCodeExists;
    mapping(uint256 => address) refOwner;
    mapping(address => uint256) refCode;
    mapping(address => bool) refClaimed;
    mapping(address => uint256) refMoney;
    
    mapping(address => bool) blacklists;

    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );

    constructor(
        AI _tokenContract1,
        IERC20 _tokenContract2,
        address _owner
    ) {
        Owner = _owner;
        tokenContract1 = _tokenContract1;
        tokenContract2 = _tokenContract2;
        tokendecimals = tokenContract1.decimals();
    }

    modifier OnlyOwners() {
        require((msg.sender == Owner), "You are not the owner of the token");
        _;
    }

    modifier BlacklistCheck() {
        require(blacklists[msg.sender] == false, "You are in the blacklist");
        _;
    }

    modifier ArmiesStopper() {
        require(armiespaused == false, "Armies code is currently stopped.");
        _;
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    event ArmiesCreated(address indexed who, uint256 indexed amount);

    event Blacklist(
        address indexed owner,
        address indexed blacklisted,
        bool indexed added
    );

    function addBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkBlacklistMember(address _who) public view returns (bool) {
        return blacklists[_who];
    }

    function stopArmies(bool _status) public OnlyOwners {
        armiespaused = _status;
    }

    function createArmies(uint256 _amount) public ArmiesStopper BlacklistCheck {
        uint256 userBalance = tokenContract2.balanceOf(msg.sender);
        uint256 bonus = 0;
        uint256 amount = _amount * armyPrice * 10**tokendecimals;
        if (refed[msg.sender] && (((_amount + armyAmount[msg.sender]) / 10) - armyBonusAmount[msg.sender]) > 0) {
            bonus = ((_amount + armyAmount[msg.sender]) / 10) - armyBonusAmount[msg.sender];
        }

        claimArmyMoney(msg.sender);

        require(userBalance >= amount, "You do not have enough SOLDAT!");
        tokenContract2.transferFrom(msg.sender, address(this), amount);

        if (armyAmount[msg.sender] == 0) {
            totalPlayers += 1;
        }
        armyAmount[msg.sender] += _amount;
        armyBonusAmount[msg.sender] += bonus;
        totalArmies += _amount + bonus;

        if (armyTimestamp[msg.sender] == 0) {
            armyTimestamp[msg.sender] = block.timestamp;
        }
        emit ArmiesCreated(msg.sender, _amount + bonus);
    }

    function totalArmyAmount() public view override returns (uint256) {
        return (totalArmies);
    }

    function checkArmyAmount(address _who) public view override returns (uint256) {
        return (armyAmount[_who] + armyBonusAmount[_who]);
    }

    function checkPlayers() public view override returns (uint256) {
        return (totalPlayers);
    }

    function checkArmyMoney(address _who) public view returns (uint256) {
        uint256 _cycles;

        _cycles = ((block.timestamp - armyTimestamp[_who]) / armyYieldTime);

        uint256 _amount = ((armyAmount[_who] + armyBonusAmount[_who]) * armyYield) * _cycles;

        return _amount;
    }

    function checkRefMoney(address _who) public view returns (uint256) {
        return refMoney[_who];
    }

    function checkTimestamp(address _who) public view returns (uint256) {
        return armyTimestamp[_who];
    }

    function createRef() public {
        require(
            refCodeExists[msg.sender] == false,
            "You already have a referral code"
        );
        address _address = msg.sender;
        uint256 rand = uint256(
            keccak256(abi.encodePacked(_address, block.number - 1))
        );
        uint256 result = uint256(rand % (10**12));
        require(readRef(result) == address(0), "Generated code already exists. Transaction has been refunded. Please try again.");
        refOwner[result] = msg.sender;
        refCode[_address] = result;
        refCodeExists[msg.sender] = true;
    }

    function readRef(uint256 _ref) public view returns (address) {
        return refOwner[_ref];
    }

    function readRefCode(address _who) public view override returns (uint256) {
        return refCode[_who];
    }

    function checkRefed(address _who) public view returns (bool) {
        return refed[_who];
    }

    function getRefd(uint256 _ref) public {
        address _referree = msg.sender;
        address _referrer = readRef(_ref);
        require(refOwner[_ref] != address(0), "Referral code does not exist!");
        require(_referrer != msg.sender, "You cannot refer yourself!");
        require(refed[_referree] == false, "You are already referred!");
        referals[_referrer].push(_referree);
        referrer[_referree] = _referrer;
        refed[_referree] = true;
    }

    function readReferals(address _who) public view override returns (address[] memory) {
        return referals[_who];
    }

    function claimArmyMoney(address _who) public ArmiesStopper BlacklistCheck {
        require(((block.timestamp - armyTimestamp[_who]) / armyYieldTime) > 0);
        uint256 _amount = checkArmyMoney(_who);
        if (refed[_who]) {
            address _referrer = referrer[_who];
            refMoney[_referrer] += _amount * armyRefPerc / 100;
        }
        armyTimestamp[_who] +=
            ((block.timestamp - armyTimestamp[_who]) / armyYieldTime) *
            armyYieldTime;
        tokenContract2.transfer(_who, _amount + refMoney[_who]);
        refMoney[_who] = 0;
    }

    function withdrawToken() public OnlyOwners {
        require(tokenContract2.balanceOf(address(this)) > 0);
        tokenContract2.transfer(Owner, tokenContract2.balanceOf(address(this)));
    }

    function withdraw() public OnlyOwners {
        require(address(this).balance > 0);
        payable(Owner).transfer(address(this).balance);
    }
}