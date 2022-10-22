// SPDX-License-Identifier: MIT
// website https://soldatiki.app
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

interface ReadI {
    
    function checkArmyAmount(address) external view returns (uint256);

    function checkPlayers() external view returns (uint256);

    function checkTimestamp(address) external view returns (uint256);

    function readRefCode(address) external view returns (uint256);

    function checkRefed(address) external view returns (bool);

    function readReferals(address) external view returns (address[] memory);

    function checkRefMoney(address)  external view returns (uint256);
}

contract ArmiesV2 is NI {
    address private Owner;
    AI private tokenContract1;
    IERC20 private tokenContract2;
    ReadI private oldGameContract;

    uint8 tokendecimals;

    // Army Attributes.
    uint256 taxAmount = 15;
    uint8 constant armyPrice = 10;
    uint8 constant armyRefPerc = 5;
    uint256 constant armyYieldTime = 27;
    uint256 constant starMultiplier = 5;
    uint256 armyYield = 31250;
    
    bool armiespaused = false;

    // Contract Variables.
    uint256 totalArmies = 0; 
    uint256 totalSpecOps = 0;
    uint256 totalSpaceForce = 0;
    uint256 totalPlayers = 0;
    address[] playerList;
    mapping(address => uint256) armyAmount; 
    mapping(address => uint256) armyBonusAmount;
    mapping(address => uint256) armyTimestamp; 
    mapping(address => uint256) specOpsAmount;
    mapping(address => uint256) spaceForceAmount;
    mapping(address => uint8) starsAmount;

    mapping(address => address[]) referals; 
    mapping(address => address) referrer; 
    mapping(address => bool) refed; 
    mapping(address => bool) refCodeExists; 
    mapping(uint256 => address) refOwner; 
    mapping(address => uint256) refCode; 
    mapping(address => uint256) refMoney; 

    mapping(address => bool) blacklists;

    mapping(address => bool) merged;

    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );

    constructor(
        AI _tokenContract1,
        IERC20 _tokenContract2,
        ReadI _oldGameContract,
        address _owner
    ) {
        Owner = _owner;
        tokenContract1 = _tokenContract1;
        tokenContract2 = _tokenContract2;
        oldGameContract = _oldGameContract;
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
    event SpecOpsCreated(address indexed who, uint256 indexed amount);
    event SpaceForceCreated(address indexed who, uint256 indexed amount);
    event StarsCreated(address indexed who, uint256 indexed amount);

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

    function changeTax(uint256 _to) public OnlyOwners {
        taxAmount = _to;
    }

    function stopArmies(bool _status) public OnlyOwners {
        armiespaused = _status;
    }

    function merge(address _who) public ArmiesStopper BlacklistCheck {
        require(!merged[_who], "This account is already merged!");

        uint256 oldAllArmies = oldGameContract.checkArmyAmount(_who);
        armyBonusAmount[_who] = oldAllArmies / 11;
        armyAmount[_who] = oldAllArmies - armyBonusAmount[msg.sender];

        totalArmies += armyAmount[_who] + armyBonusAmount[_who];

        armyTimestamp[_who] = oldGameContract.checkTimestamp(_who);
        refed[_who] = oldGameContract.checkRefed(_who);

        refCode[_who] = oldGameContract.readRefCode(_who);
        if (refCode[_who] != 0) {
            refCodeExists[_who] = true;
            refOwner[refCode[_who]] = _who;
        }
        refMoney[_who] = oldGameContract.checkRefMoney(_who);
        referals[_who] = oldGameContract.readReferals(_who);
        for (uint256 i = 0; i < referals[_who].length; ) {
            referrer[referals[_who][i]] = _who;
            refed[referals[_who][i]] = true;
            i++;
        }
        totalPlayers++;
        playerList.push(_who);
        merged[_who] = true;
        
    }

    function checkMerge(address _who) public view returns(bool) {
        return(merged[_who]);
    }

    function createArmies(uint256 _amount) public ArmiesStopper BlacklistCheck {
        uint256 userBalance = tokenContract2.balanceOf(msg.sender);
        uint256 bonus = 0;
        uint256 amount = _amount * armyPrice * 10**tokendecimals;
        if (
            refed[msg.sender] &&
            (((_amount + armyAmount[msg.sender]) / 10) -
                armyBonusAmount[msg.sender]) >
            0
        ) {
            bonus =
                ((_amount + armyAmount[msg.sender]) / 10) -
                armyBonusAmount[msg.sender];
        }

        claimArmyMoney(msg.sender);

        require(userBalance >= amount, "You do not have enough SOLDAT!");
        tokenContract2.transferFrom(msg.sender, address(this), amount);

        if (armyAmount[msg.sender] == 0 && specOpsAmount[msg.sender] == 0 && spaceForceAmount[msg.sender] == 0) {
            totalPlayers += 1;
            playerList.push(msg.sender);
        }
        armyAmount[msg.sender] += _amount;
        armyBonusAmount[msg.sender] += bonus;
        totalArmies += _amount + bonus;

        if (armyTimestamp[msg.sender] == 0) {
            armyTimestamp[msg.sender] = block.timestamp;
        }
        emit ArmiesCreated(msg.sender, _amount + bonus);
    }

    function reinvest(uint256 _amount) public ArmiesStopper BlacklistCheck {
        require(((block.timestamp - armyTimestamp[msg.sender]) / armyYieldTime) > 0);
        uint256 userBalance = refMoney[msg.sender] + checkArmyMoney(msg.sender);
        uint256 price = _amount * armyPrice * 10**tokendecimals;
        uint256 bonus = 0;
        require(userBalance >= price, "You do not have enough SOLDAT!");

        if (
            refed[msg.sender] &&
            (((_amount + armyAmount[msg.sender]) / 10) -
                armyBonusAmount[msg.sender]) >
            0
        ) {
            bonus =
                ((_amount + armyAmount[msg.sender]) / 10) -
                armyBonusAmount[msg.sender];
        }

        if (refed[msg.sender]) {
            address _referrer = referrer[msg.sender];
            refMoney[_referrer] += (price * armyRefPerc) / 100;
        }
        uint256 left = userBalance - price;
        armyTimestamp[msg.sender] +=
            ((block.timestamp - armyTimestamp[msg.sender]) / armyYieldTime) *
            armyYieldTime;
            
        refMoney[msg.sender] = left;

        armyAmount[msg.sender] += _amount;
        armyBonusAmount[msg.sender] += bonus;
        totalArmies += _amount + bonus;

        emit ArmiesCreated(msg.sender, _amount);
        
    }

    function createSpecOps(uint256 _amount)
        public
        payable
        ArmiesStopper
        BlacklistCheck
    {
        uint256 userArmies = checkArmyAmount(msg.sender);
        uint256 price = _amount * 0.0065 ether;
        uint256 priceInArmies = _amount * 10;

        require(msg.value >= price, "The amount is lower than the requirement");
        require(
            userArmies >= priceInArmies,
            "The army amount is lower than the requirement"
        );

        claimArmyMoney(msg.sender);

        if ((userArmies - priceInArmies) / 10 == 0) {
            armyAmount[msg.sender] = userArmies - priceInArmies;
            armyBonusAmount[msg.sender] = 0;
        } else {
            uint256 _buffer = (userArmies - priceInArmies) / 10;
            uint256 _tempBonus = armyBonusAmount[msg.sender] - _buffer;
            armyAmount[msg.sender] =
                armyAmount[msg.sender] -
                priceInArmies +
                _tempBonus;
            armyBonusAmount[msg.sender] -= _tempBonus;
        }
        specOpsAmount[msg.sender] += _amount;
        totalArmies -= priceInArmies;
        totalSpecOps += _amount;
        emit SpecOpsCreated(msg.sender, _amount);
    }

    function createSpaceForce(uint256 _amount)
        public
        payable
        ArmiesStopper
        BlacklistCheck
    {
        uint256 userSpecOps = checkSpecOpsAmount(msg.sender);
        uint256 price = _amount * 0.065 ether;
        uint256 priceInSpecOps = _amount * 10;

        require(msg.value >= price, "The amount is lower than the requirement");
        require(
            userSpecOps >= priceInSpecOps,
            "The army amount is lower than the requirement"
        );

        claimArmyMoney(msg.sender);

        specOpsAmount[msg.sender] -= priceInSpecOps;
        spaceForceAmount[msg.sender] += _amount;
        totalSpecOps -= priceInSpecOps;
        totalSpaceForce += _amount;

        emit SpaceForceCreated(msg.sender, _amount);
    }

    function createStars(uint8 _amount) public payable ArmiesStopper BlacklistCheck {
        require(_amount <= 5 - starsAmount[msg.sender], "You cannot create more than 5 stars");
        uint256 price = _amount * 0.01 ether;
        require(msg.value >= price, "The amount is lower than the requirement");
        claimArmyMoney(msg.sender);
        starsAmount[msg.sender] += _amount;
        emit StarsCreated(msg.sender, _amount);
    }

    function totalArmyAmount() public view override returns (uint256) {
        return (totalArmies);
    }

    function totalSpecOpsAmount() public view returns (uint256) {
        return (totalSpecOps);
    }

    function totalSpaceForceAmount() public view returns (uint256) {
        return (totalSpaceForce);
    }

    function checkArmyAmount(address _who)
        public
        view
        override
        returns (uint256)
    {
        return (armyAmount[_who] + armyBonusAmount[_who]);
    }

    function checkSpecOpsAmount(address _who) public view returns (uint256) {
        return (specOpsAmount[_who]);
    }

    function checkSpaceForceAmount(address _who) public view returns (uint256) {
        return (spaceForceAmount[_who]);
    }

    function checkStarsAmount(address _who) public view returns (uint256) {
        return (starsAmount[_who]);
    }

    function checkPlayers() public view override returns (uint256) {
        return (totalPlayers);
    }

    function checkPlayerList() public view returns (address[] memory) {
        return playerList;
    }

    function checkArmyMoney(address _who) public view returns (uint256) {
        uint256 _cycles;

        _cycles = ((block.timestamp - armyTimestamp[_who]) / armyYieldTime);
        
        uint256 _starMultiplier = ((starMultiplier * starsAmount[_who]));

        uint256 _amount = (
            ((armyAmount[_who] + armyBonusAmount[_who]) * (armyYield * (_starMultiplier + 1000) / 1000)) +
            (specOpsAmount[_who] * (armyYield * (_starMultiplier + 1120) / 100)) +
            (spaceForceAmount[_who] * (armyYield * (_starMultiplier + 1140) / 10))) * _cycles;

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
        require(
            readRef(result) == address(0),
            "Generated code already exists. Transaction has been refunded. Please try again."
        );
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

    function checkReferrer(address _who) public view returns (address) {
        return referrer[_who];
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

    function readReferals(address _who)
        public
        view
        override
        returns (address[] memory)
    {
        return referals[_who];
    }

    function claimArmyMoney(address _who) public ArmiesStopper BlacklistCheck {
        require(((block.timestamp - armyTimestamp[_who]) / armyYieldTime) > 0);
        uint256 _amount = checkArmyMoney(_who);
        if (refed[_who]) {
            address _referrer = referrer[_who];
            refMoney[_referrer] += (_amount * armyRefPerc) / 100;
        }
        armyTimestamp[_who] +=
            ((block.timestamp - armyTimestamp[_who]) / armyYieldTime) *
            armyYieldTime;
        uint256 _tax = (_amount + refMoney[_who]) * taxAmount / 100;
        tokenContract2.transfer(_who, _amount + refMoney[_who] - _tax);
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