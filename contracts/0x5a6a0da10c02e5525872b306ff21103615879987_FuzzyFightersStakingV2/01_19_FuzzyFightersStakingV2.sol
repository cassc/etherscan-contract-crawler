// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./IStakedFuzzyFighters.sol";

contract FuzzyFightersStakingV2 is UUPSUpgradeable,IERC721ReceiverUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IERC20Upgradeable public  rewardToken;
    IERC721Upgradeable public stakingToken;
    address public ERC1155_CONTRACT;
   
    mapping(address => EnumerableSetUpgradeable.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositTimes;
    mapping (uint256 => uint256) public tokenRarity;
    bool public pauseStaking;
    bool public pauseTokenEmissions;
    uint256[3] public rewardRate; 
    uint256 private maxRewardTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize( address _erc20,
        address _erc721,
        address _erc1155,
        uint256 _maxRewardTime) initializer public {
        rewardToken = IERC20Upgradeable(_erc20);
        stakingToken = IERC721Upgradeable(_erc721);
        ERC1155_CONTRACT = _erc1155;
        rewardRate = [5*1e18, 10*1e18, 20*1e18];
        maxRewardTime = _maxRewardTime;
        pauseStaking = true;
        pauseTokenEmissions = false;
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setRate(uint256 _rarity, uint256 _rate) public onlyOwner() {
        rewardRate[_rarity] = _rate;
    }

    function setRarity(uint256 _tokenId, uint256 _rarity) public onlyOwner() {
        tokenRarity[_tokenId] = _rarity;
    }

    function setBatchRarity(uint256[] memory _tokenIds, uint256 _rarity) public onlyOwner() {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            tokenRarity[tokenId] = _rarity;
        }
    }

    function setMaxRewardTime(uint256 _maxRewardTime) public onlyOwner() {
        require(_maxRewardTime>block.timestamp,'FuzzStaking: invalid max reward time');
        maxRewardTime = _maxRewardTime;
    }

    function togglePauseStaking() external onlyOwner() {
        pauseStaking = !pauseStaking;
    }

    function toggleEmissions() external onlyOwner {
        pauseTokenEmissions = !pauseTokenEmissions;
    }

    function setRewardToken(address _tokenAddress) public onlyOwner() {
        // Used to change rewards token if needed
       rewardToken = IERC20Upgradeable(_tokenAddress);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSetUpgradeable.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function findRate(uint256 tokenId)
        public
        view
        returns (uint256) 
    {
        uint256 rarity = tokenRarity[tokenId];
        uint256 perDay = rewardRate[rarity];
         
        uint256 rate = perDay  / 86400;
        
        return rate;
    }

    function rewardPerDay(uint256[] memory tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 totalReward = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 rarity = tokenRarity[tokenId];
            uint256 perDay = rewardRate[rarity];
            totalReward += perDay;
        }

        return totalReward;
    }

     function _calculateReward(address account, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 rate = findRate(tokenId);
        uint256 diff = MathUpgradeable.min(block.timestamp, maxRewardTime) > depositTimes[account][tokenId]?
            (MathUpgradeable.min(block.timestamp, maxRewardTime) - depositTimes[account][tokenId]) : 0;
            
        uint256 rewards  = rate * (_deposits[account].contains(tokenId) ? 1 : 0) * diff;
        return rewards;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            rewards[i] = _calculateReward(account,tokenId);
        }

        return rewards;
    }

    function withdrawRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 curTime = MathUpgradeable.min(block.timestamp, maxRewardTime);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            reward += _calculateReward(msg.sender, tokenId);
            depositTimes[msg.sender][tokenIds[i]] = curTime;
        }

        if (reward > 0 && !pauseTokenEmissions) {
            rewardToken.safeTransfer(msg.sender, reward);
        }
    }

    function stake(uint256[] calldata tokenIds) external {
        require(!pauseStaking, 'FuzzStaking: staking is paused');
        uint256 curTime = MathUpgradeable.min(block.timestamp, maxRewardTime);
        for (uint256 i; i < tokenIds.length; i++) {
            depositTimes[msg.sender][tokenIds[i]] = curTime;
            stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
        IStakedFuzzyFighters(ERC1155_CONTRACT).whitelistMint(msg.sender, 1,tokenIds.length);
    }

    function admin_stake(uint256[] calldata tokenIds) onlyOwner() external {
        withdrawRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
        IStakedFuzzyFighters(ERC1155_CONTRACT).whitelistMint(msg.sender, 1,tokenIds.length);
    }

    function unstake(uint256[] calldata tokenIds) external {
        withdrawRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'FuzzStaking: Token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            stakingToken.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }

        IStakedFuzzyFighters(ERC1155_CONTRACT).whitelistBurn(msg.sender, 1, tokenIds.length);
    }
    
    function version() external pure returns(uint256) {
        return 2;
    }
}