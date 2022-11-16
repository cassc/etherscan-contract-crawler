// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/access/Ownable.sol";
import "../includes/libraries/Percentages.sol";
import "../includes/token/BEP20/IBEP20.sol";
import "../includes/interfaces/IUniswapV2Router02.sol";
import "../includes/interfaces/IPriceConsumerV3.sol";
import "../includes/interfaces/IRugZombieNft.sol";
import "../includes/utils/ReentrancyGuard.sol";

contract DrBurnenstein is Ownable, ReentrancyGuard {
    using Percentages for uint256;

    enum DepositType {
        NONE,
        TOKEN,
        NFT
    }

    struct UserInfo {
        uint256 amount;             // How many tokens are staked
        bool    deposited;          // Flag for if the required NFT/token has been deposited
        uint256 nftMintDate;        // The date the NFT is available to mint
        uint256 depositedAmount;    // The amount of the required tokens that were deposited
        uint    depositedId;        // The token ID of the deposited NFT
        uint256 burnedAmount;       // The amount of zombie that has been burned this minting cycle
    }

    struct GraveInfo {
        bool            isEnabled;          // Flag for it the grave is active
        IBEP20          stakingToken;       // The token to be staked
        DepositType     depositType;        // The type of required deposit
        address         deposit;            // The NFT/token that needs to be deposited
        IRugZombieNft   rewardNft;          // The NFT that gets rewarded by the grave
        uint256         minimumStake;       // The minimum amount of tokens that need to be staked
        uint256         mintingTime;        // The time it takes to mint the reward NFT
        uint256         burnTokens;         // The number of tokens that get burned when supply is low
        uint            burnHours;          // How many hours to take off the mint timer during a burn
        uint256         maxBurned;          // The maximum amount that can be burned per minting cycle
        uint256         totalStaked;        // The total tokens staked in a grave
        uint256         totalBurned;        // The total amount of ZMBE burned in this grave
    }

    IBEP20              public  zombie;         // The ZMBE token
    GraveInfo[]         public  graveInfo;      // Array of the pool structs
    address             payable treasury;       // Wallet address for the treasury

    // Mapping of user info to address mapped to each pool
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // Address to send burned tokens to
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event MintNft(address indexed to, uint date, address nft, uint indexed id);
    event ZombieBurned(address indexed user, uint grave, uint date, uint256 amount);

    // Constructor for constructing things
    constructor(
        address _zombie,
        address _treasury
    ) {
        zombie = IBEP20(_zombie);
        treasury = payable(_treasury);
    }

    // Modifier to ensure a user is staked in a grave
    modifier isStaked(uint _gid) {
        require(userInfo[_gid][msg.sender].amount > 0, 'Grave: You are not staked in this grave');
        _;
    }

    // Modifier to ensure grave has been unlocked
    modifier isUnlocked(uint _gid) {
        UserInfo memory user = userInfo[_gid][msg.sender];
        GraveInfo memory grave = graveInfo[_gid];
        require(user.deposited || grave.depositType == DepositType.NONE, 'Locked: Have not made the required deposit');
        _;
    }

    // Modifier to ensure user had made required deposit
    modifier hasDeposited(uint _gid) {
        require(userInfo[_gid][msg.sender].deposited || graveInfo[_gid].depositType == DepositType.NONE, 'Locked: Have not made the required deposit');
        _;
    }

    // Modifier to ensure a pool exists
    modifier graveExists(uint _gid) {
        require(_gid <= graveInfo.length - 1, 'Grave: Grave does not exist');
        _;
    }

    // Function to add a grave
    function addGrave(
        address _stakingToken,
        uint _depositType,
        address _deposit,
        address _rewardNft,
        uint256 _minimumStake,
        uint256 _mintingTime,
        uint256 _burnAmount,
        uint _burnHours,
        uint256 _maxBurn
    ) public onlyOwner() {
        graveInfo.push(GraveInfo({
            stakingToken: IBEP20(_stakingToken),
            depositType: DepositType(_depositType),
            deposit: _deposit,
            rewardNft: IRugZombieNft(_rewardNft),
            minimumStake: _minimumStake,
            mintingTime: _mintingTime,
            burnTokens: _burnAmount,
            burnHours: _burnHours,
            maxBurned: _maxBurn,
            isEnabled: false,
            totalStaked: 0,
            totalBurned: 0
        }));
    }

    // Function to set the amount of tokens to be burned when supply is high
    function setBurnedTokens(uint _gid, uint256 _amount) public onlyOwner() {
        graveInfo[_gid].burnTokens = _amount;
    }

    // Function to set the amount of hours reduced by burning
    function setBurnHours(uint _gid, uint _hours) public onlyOwner() {
        graveInfo[_gid].burnHours = _hours;
    }

    // Function to set the maximum burn allowed per minting cycle
    function setMaxBurned(uint _gid, uint256 _amount) public onlyOwner() {
        graveInfo[_gid].maxBurned = _amount;
    }

    // Function to set the enabled state of a grave
    function setIsEnabled(uint _gid, bool _enabled) public onlyOwner() {
        graveInfo[_gid].isEnabled = _enabled;
    }

    // Function to set the reward NFT for a grave
    function setRewardNft(uint _gid, address _nft) public onlyOwner() {
        graveInfo[_gid].rewardNft = IRugZombieNft(_nft);
    }

    // Function to set the minimum stake for a grave
    function setMinimumStake(uint _gid, uint256 _minimumStake) public onlyOwner() {
        graveInfo[_gid].minimumStake = _minimumStake;
    }

    // Function to set the minting time for a grave
    function setMintingTime(uint _gid, uint256 _mintingTime) public onlyOwner() {
        graveInfo[_gid].mintingTime = _mintingTime;
    }

    // Function to set the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Function to get the number of graves
    function graveCount() public view returns(uint) {
        return graveInfo.length;
    }

    // Function to make the required deposit
    function deposit(uint _gid, uint256 _amount, uint _tokenId) public graveExists(_gid) {
        GraveInfo memory grave = graveInfo[_gid];
        require(grave.isEnabled, 'Grave: This grave is not enabled');
        require(grave.depositType != DepositType.NONE, 'Grave: No deposit is necessary for this grave');
        UserInfo storage user = userInfo[_gid][msg.sender];
        if (grave.depositType == DepositType.TOKEN) {
            _depositTokens(grave, user, _amount);
        } else {
            _depositNft(grave, user, _tokenId);
        }
    }

    // Function to enter staking in a grave
    function enterStaking(uint _gid, uint256 _amount) public isUnlocked(_gid) {
        GraveInfo storage grave = graveInfo[_gid];
        UserInfo storage user = userInfo[_gid][msg.sender];

        require(grave.isEnabled, 'Grave: This grave is not enabled');
        require(user.amount + _amount >= grave.minimumStake, 'Grave: Must stake at least the minimum amount');

        if (_amount > 0) {
            if (user.amount < grave.minimumStake) {
                user.nftMintDate = block.timestamp + grave.mintingTime;
                user.burnedAmount = 0;
            }
            require(grave.stakingToken.transferFrom(msg.sender, address(this), _amount));
            user.amount += _amount;
            grave.totalStaked += _amount;
        }

        emit Deposit(msg.sender, _gid, _amount);
    }

    // Function to burn zombie to reduce the minting timer
    function burnZombie(uint _gid, uint256 _amount) public isStaked(_gid) {
        GraveInfo storage grave = graveInfo[_gid];
        UserInfo storage user = userInfo[_gid][msg.sender];

        require(grave.isEnabled, 'Grave: This grave is not enabled');

        require(_amount >= grave.burnTokens, 'Grave: Insufficient tokens to burn');
        require(user.burnedAmount + _amount <= grave.maxBurned, 'Grave: You have already burned the maximum for this minting cycle');

        require(zombie.transferFrom(msg.sender, burnAddr, _amount));
        user.burnedAmount += _amount;
        grave.totalBurned += _amount;

        uint burnCycles = _amount / grave.burnTokens;
        user.nftMintDate -= ((grave.burnHours * 1 hours) * burnCycles);

        emit ZombieBurned(msg.sender, _gid, block.timestamp, _amount);
    }

    // Function to leave staking from a grave
    function leaveStaking(uint _gid, uint256 _amount) public {
        GraveInfo storage grave = graveInfo[_gid];
        UserInfo storage user = userInfo[_gid][msg.sender];

        require(user.amount >= _amount, 'Grave: Cannot unstake more than has been staked');
        uint256 endAmount = user.amount - _amount;
        require(grave.isEnabled || endAmount == 0, 'Grave: Must remove entire stake from inactive grave');
        require(endAmount >= grave.minimumStake || endAmount == 0, 'Grave: Can only unstake to minimum stake, or unstake entirely');

        if (user.amount >= grave.minimumStake && block.timestamp >= user.nftMintDate) {
            uint tokenId = grave.rewardNft.reviveRug(msg.sender);
            user.nftMintDate = block.timestamp + grave.mintingTime;
            user.burnedAmount = 0;
            emit MintNft(msg.sender, block.timestamp, address(grave.rewardNft), tokenId);
        }

        if (_amount > 0) {
            require(grave.stakingToken.transfer(msg.sender, _amount));
            user.amount -= _amount;
            grave.totalStaked -= _amount;
        }

        emit Withdraw(msg.sender, _gid, _amount);
    }

    // Function to deposit required tokens
    function _depositTokens(GraveInfo memory _grave, UserInfo storage _user, uint256 _amount) private {
        require(_amount >= 1, 'Grave: Must deposit at least one token');
        IBEP20 token = IBEP20(_grave.deposit);
        require(token.transferFrom(msg.sender, treasury, _amount));
        _user.deposited = true;
        _user.depositedAmount = _amount;
    }

    // Function to deposit required NFT
    function _depositNft(GraveInfo memory _grave, UserInfo storage _user, uint _tokenId) private {
        require(_tokenId > 0, 'Grave: Must provide the token ID');
        IRugZombieNft nft = IRugZombieNft(_grave.deposit);
        nft.transferFrom(msg.sender, treasury, _tokenId);
        require(nft.ownerOf(_tokenId) == treasury, 'Grave: NFT transfer failed');
        _user.deposited = true;
        _user.depositedId = _tokenId;
    }
}