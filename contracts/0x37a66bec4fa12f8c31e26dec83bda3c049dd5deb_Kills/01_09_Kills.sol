// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Kills is ReentrancyGuard, ERC20 {
    
    struct Hunters {
        uint256 amountHunting;
        uint256 timeOfHunting;
        uint256 deposit;
    }

    struct JoinRaffle {
        address addressRaffle;
        uint256 amountRaffle;
    }

    struct JoinLuckyChance {
        address addressLuckyChance;
        string prizeLuckyChance;
    }  

    IERC721 public IMechaApe;
    IERC721 public IMechaHound;
    address public owner;
    mapping(string => JoinLuckyChance[]) public LuckyChance;
    mapping(string => JoinRaffle[]) public Raffle;
    mapping(string => uint256) public RafflePrice;
    mapping(string => address) public RaffleWinner;
    uint256 public MechaApeRatio;
    uint256 public MechaHoundRatio;
    uint256 private rewardsPerHour = 33333;
    string public Empty = "";
    mapping(address => Hunters) public MechaStake;
    mapping(uint256 => address) public MechaApeStakeAddress;
    mapping(uint256 => address) public MechaHoundStakeAddress;
    mapping(address => uint256[]) public MechaApeStakeToken;
    mapping(address => uint256[]) public MechaHoundStakeToken;
    address[] public MechaStakeArray;
    uint256 public LuckyChancePrice;
    bool public isRaffle; 
    bool public isLuckyChance; 
    bool public isFeature; 

    constructor(IERC721 _mechaApe,IERC721 _mechaHound,string memory _name, string memory _symbol)ERC20(_name, _symbol){
        IMechaApe = _mechaApe;
        IMechaHound = _mechaHound;
        owner = msg.sender;
    }

    function _onlyOwner() private view{
        require(msg.sender == owner, "not Owner");
    }

    function newOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner(){
        _onlyOwner();
        _;
    }

    function onTransferKills(address to ,uint256 amount) public nonReentrant {
        require(isFeature, "not Active");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        MechaStake[msg.sender].deposit -= amount;
        MechaStake[to].deposit += amount;
    }

    function onDepositKills(uint256 amount) public nonReentrant {
        require(isFeature, "not Active");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        MechaStake[msg.sender].deposit += amount;
    }

    function onWithdrawKills() external nonReentrant {
        require(isFeature, "not Active");
        uint256 rewardKills = calculateKills(msg.sender) + MechaStake[msg.sender].deposit;
        require(rewardKills > 0, "You dont' have any $Kills to claim");
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        MechaStake[msg.sender].deposit = 0;
        _mint(msg.sender, rewardKills);
    }

    function onMoveKills() external nonReentrant {
        require(isFeature, "not Active");
        uint256 rewardKills = calculateKills(msg.sender) + MechaStake[msg.sender].deposit;
        require(rewardKills > 0, "You dont' have any $Kills to claim");
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        MechaStake[msg.sender].deposit = rewardKills;
    }

    function onRaffleJoin(uint256 amount,string memory raffleName) external nonReentrant {
        require(isRaffle, "not Active");
        uint256 rafflePrice = RafflePrice[raffleName];
        require(amount >= rafflePrice, "Not Enough $Kills");
        JoinRaffle memory newStruct = JoinRaffle(msg.sender,amount);
        Raffle[raffleName].push(newStruct);
        MechaStake[msg.sender].deposit -= amount;
    }
    
    function onLuckyChance(uint256 amount,string memory luckyChanceName) external nonReentrant returns(string memory) {
        require(isLuckyChance, "not Active");
        require(amount >= LuckyChancePrice, "Not Enough $Kills");
        require(MechaStake[msg.sender].deposit >= amount, "Not Enough $Kills");
        uint256 burn = amount;
        uint256 random = generateRandomNumberLuckyChance(luckyChanceName);
        if(keccak256(abi.encodePacked(LuckyChance[luckyChanceName][random].prizeLuckyChance)) != keccak256(abi.encodePacked(Empty)))
        {
            if(LuckyChance[luckyChanceName][random].addressLuckyChance == address(0))
            {
                LuckyChance[luckyChanceName][random].addressLuckyChance = msg.sender;
                return LuckyChance[luckyChanceName][random].prizeLuckyChance;
            }
            else{
                burn = generateRandomNumberCoin();
                return Strings.toString(burn);
            }
        }
        else{
            burn = generateRandomNumberCoin();
        }
        MechaStake[msg.sender].deposit -= burn;
        return Strings.toString(burn);
    }
    
    function RaffleDeclareWinner(string memory raffleName) public onlyOwner {
        require(Raffle[raffleName].length > 0);
        uint index = generateRandomNumberRaffle(raffleName) % Raffle[raffleName].length;
        address winner = Raffle[raffleName][index].addressRaffle;
        RaffleWinner[raffleName] = winner;
    }     

    function setIsFeature(bool _isDeposit,bool _isFeature , bool _isLuckyChance)public onlyOwner {
        isRaffle =_isDeposit; 
        isFeature =_isFeature; 
        isLuckyChance =_isLuckyChance; 
    }
    
    function setPrizeLucky(string memory LuckyChanceName,string[] memory prizeLuckyChance) public onlyOwner {
        for (uint256 i = 0; i < prizeLuckyChance.length; ++i) {
            JoinLuckyChance memory newStruct = JoinLuckyChance(address(0),prizeLuckyChance[i]);
            LuckyChance[LuckyChanceName].push(newStruct);
        }
    }  

    function generateRandomNumberRaffle(string memory raffleName) internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (Raffle[raffleName].length);
    }
    
    function generateRandomNumberLuckyChance(string memory raffleName) internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (LuckyChance[raffleName].length);
    }
    
    function generateRandomNumberCoin() internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (LuckyChancePrice);
    }

    function MechaStakeList() internal view returns (uint256 __length) {
        return (MechaStakeArray.length);
    }

    function Stake(uint256[] calldata _idMechaApe , uint256[] calldata _idMechaHound) external nonReentrant {

        uint mechaApe = uint(_idMechaApe.length*10)/MechaApeRatio;
        uint mechaHound = uint(_idMechaHound.length*10)/MechaHoundRatio;
        uint256 lenMechaHApe = _idMechaApe.length;
        uint256 lenMechaHound = _idMechaHound.length;

        require(mechaApe == mechaHound, string(abi.encodePacked("Need 2:1 Staking | ",MechaApeRatio," Mecha Apes : ", MechaHoundRatio," Mecha Hound")));
        if (MechaStake[msg.sender].amountHunting > 0) {
            uint256 rewardsMechaApe = calculateKills(msg.sender);
            MechaStake[msg.sender].deposit += rewardsMechaApe;
        } else {
            MechaStakeArray.push(msg.sender);
        }
        for (uint256 i; i < lenMechaHApe; ++i) {
            IMechaApe.transferFrom(msg.sender, address(this), _idMechaApe[i]);
            MechaApeStakeAddress[_idMechaApe[i]] = msg.sender;
            MechaApeStakeToken[msg.sender].push(_idMechaApe[i]);
        }
        for (uint256 i; i < lenMechaHound; ++i) {
            IMechaHound.transferFrom(msg.sender, address(this), _idMechaHound[i]);
            MechaHoundStakeAddress[_idMechaHound[i]] = msg.sender;
            MechaHoundStakeToken[msg.sender].push(_idMechaHound[i]);
        }
        MechaStake[msg.sender].amountHunting += lenMechaHApe+lenMechaHound;
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
    }

    function UnStake(uint256[] calldata _idMechaApe , uint256[] calldata _idMechaHound) external nonReentrant {

        uint mechaApe = uint(_idMechaApe.length*10)/MechaApeRatio;
        uint mechaHound = uint(_idMechaHound.length*10)/MechaHoundRatio;
        require(mechaApe == mechaHound, string(abi.encodePacked("Need 2:1 Staking | ",MechaApeRatio," Mecha Apes : ", MechaHoundRatio," Mecha Hound")));
        require(MechaStake[msg.sender].amountHunting > 0, "Don't have any NFT Staked");
        uint256 rewardsMechaApe = calculateKills(msg.sender);
        MechaStake[msg.sender].deposit += rewardsMechaApe;
        uint256 lenMechaApe = _idMechaApe.length;
        for (uint256 i; i < lenMechaApe; ++i) {
            require(MechaApeStakeAddress[_idMechaApe[i]] == msg.sender, "Can't Withdraw tokens you don't own!");
            MechaApeStakeAddress[_idMechaApe[i]] = address(0);
            IMechaApe.transferFrom(address(this), msg.sender, _idMechaApe[i]);
            for (uint256 j; j < MechaApeStakeToken[msg.sender].length; ++j) {
                if(MechaApeStakeToken[msg.sender][j] ==_idMechaApe[i]){
                    MechaApeStakeToken[msg.sender][j] = MechaApeStakeToken[msg.sender][MechaApeStakeToken[msg.sender].length - 1];
                    MechaApeStakeToken[msg.sender].pop();
                }
            }
        }
        uint256 lenMechaHound = _idMechaHound.length;
        for (uint256 i; i < lenMechaHound; ++i) {
            require(MechaHoundStakeAddress[_idMechaHound[i]] == msg.sender, "Can't Withdraw tokens you don't own!");
            MechaHoundStakeAddress[_idMechaHound[i]] = address(0);
            IMechaHound.transferFrom(address(this), msg.sender, _idMechaHound[i]);
            for (uint256 j; j < MechaHoundStakeToken[msg.sender].length; ++j) {
                if(MechaHoundStakeToken[msg.sender][j] ==_idMechaHound[i]){
                    MechaHoundStakeToken[msg.sender][j] = MechaHoundStakeToken[msg.sender][MechaHoundStakeToken[msg.sender].length - 1];
                    MechaHoundStakeToken[msg.sender].pop();
                }
            }
        }
        MechaStake[msg.sender].amountHunting -= lenMechaApe+lenMechaHound;
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        if (MechaStake[msg.sender].amountHunting == 0) {
            for (uint256 i; i < MechaStakeArray.length; ++i) {
                if (MechaStakeArray[i] == msg.sender) {
                    MechaStakeArray[i] = MechaStakeArray[MechaStakeArray.length - 1];
                    MechaStakeArray.pop();
                }
            }
        }
    }

    function setRewardsPerHour(uint256 _newValue) public onlyOwner {
        address[] memory _stakersMechaApe = MechaStakeArray;
        uint256 length = _stakersMechaApe.length;
        for (uint256 i; i < length; ++i) {
            address user = _stakersMechaApe[i];
            MechaStake[user].deposit += calculateKills(user);
            MechaStake[msg.sender].amountHunting = block.timestamp;
        }
        rewardsPerHour = _newValue;
    }

    function setLuckyChancePrice(uint256 _luckyChancePrice) public onlyOwner {
        LuckyChancePrice = _luckyChancePrice;
    }

    function setRafflePrice(string memory raffleName, uint256 _raffleChancePrice) public onlyOwner {
        RafflePrice[raffleName] = _raffleChancePrice;
    }

    function setEmptyLuckyChance(string memory emptyName) public onlyOwner {
        Empty = emptyName;
    }

    function setRatioStaking(uint256 _mechaApe,uint256 _mechaHound) public onlyOwner {
        MechaApeRatio = _mechaApe;
        MechaHoundRatio = _mechaHound;
    }

    function addressDetail(address _user) public view returns (uint256 _tokensMechaHoundStaked, uint256 _availableRewards)
    {
        return (MechaStake[_user].amountHunting, availableRewardsKills(_user));
    }

    function availableRewardsKills(address _user) internal view returns (uint256) {
        if (MechaStake[_user].amountHunting == 0) 
        {
            return MechaStake[_user].deposit;
        }
        uint256 _rewards = MechaStake[_user].deposit + calculateKills(_user);
        return _rewards;
    }
    
    function calculateKills(address _staker) internal view returns (uint256 _rewards)
    {
        Hunters memory staker = MechaStake[_staker];
        return (((((block.timestamp - staker.timeOfHunting) * staker.amountHunting)) * rewardsPerHour) / 3600);
    }

    function TotalReward(address _staker) public view returns (uint256 _rewards)
    {
        return (availableRewardsKills(_staker));
    }
    function MechaApeLength(address _staker) public view returns (uint256 Length)
    {
        return (MechaApeStakeToken[_staker].length);
    }
    function MechaHoundLength(address _staker) public view returns (uint256 Length)
    {
        return (MechaHoundStakeToken[_staker].length);
    }
}