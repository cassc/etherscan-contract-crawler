// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IStakedFuzzyFighters.sol";

contract FuzzyFightersStaking is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public  rewardToken;
    IERC721 public stakingToken;
    address public ERC1155_CONTRACT;
   
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositTimes;
    mapping (uint256 => uint256) public tokenRarity;
    uint256[3] public rewardRate; 
    uint256 maxRewardTime;
    bool started;

    constructor(
        address _erc20,
        address _erc721,
        address _erc1155,
        uint256 _maxRewardTime
    ) {
        rewardToken = IERC20(_erc20);
        stakingToken = IERC721(_erc721);
        ERC1155_CONTRACT = _erc1155;
        rewardRate = [5*1e18, 10*1e18, 20*1e18];
        started = false;
        maxRewardTime = _maxRewardTime;
    }

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

    function toggleStart() public onlyOwner() {
        started = !started;
    }

    function setRewardToken(address _tokenAddress) public onlyOwner() {
        // Used to change rewards token if needed
       rewardToken = IERC20(_tokenAddress);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
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

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 rate = findRate(tokenId);
            uint256 diff = Math.min(block.timestamp, maxRewardTime) > depositTimes[account][tokenId]?
                (Math.min(block.timestamp, maxRewardTime) - depositTimes[account][tokenId]) : 0;
                
            rewards[i] = rate * (_deposits[account].contains(tokenId) ? 1 : 0) * diff;
        }

        return rewards;
    }

    function withdrawRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 curTime = Math.min(block.timestamp, maxRewardTime);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositTimes[msg.sender][tokenIds[i]] = curTime;
        }

        if (reward > 0) {
            rewardToken.safeTransfer(msg.sender, reward);
        }
    }

    function stake(uint256[] calldata tokenIds) external {
        require(started, 'FuzzStaking: Staking contract not started yet');
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
}