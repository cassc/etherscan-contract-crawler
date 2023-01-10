pragma solidity 0.8.12;

import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./MarketingNFT.sol";

contract MarketingNFTStaking is IERC721Receiver {
    MarketingNFT nft;
    using SafeMath for uint256;

    uint256 constant ONE_DAY = 86400;
    uint256 constant ONE_WEEK = 604800;
    uint256 constant REWARD_EPOCH_SECONDS = ONE_DAY;
    uint256[4] public COOLDOWN = [
        SafeMath.mul(REWARD_EPOCH_SECONDS, 3),   // common
        SafeMath.mul(REWARD_EPOCH_SECONDS, 5),   // uncommon
        SafeMath.mul(REWARD_EPOCH_SECONDS, 7),   // rare
        SafeMath.mul(REWARD_EPOCH_SECONDS, 14)   // legendary
    ];

    uint256[4] public INCOME_PERCENT = [
    1,   // 0.1 %
    2,   //  0.2 %
    3,   //  0.3 %
    6   // legendary 0.6 %
    ];

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 constant stakingTime = 180 seconds;


    /**
    * Stake represents staked nft token
    * @param startStaking - last staking start timestamp
    * @param cooldown - represents timestamp when cooldown finish
    */
    struct Stake {
        uint256 startStaking;
        address owner;
    }

    //mapping(address => Stake)
    mapping(address => Stake) public stakes;
    // mapping(tokenId => cooldown)
    mapping(uint256 => uint256) public tokenCooldown;
    //mapping(address => rewardMultiplier)
    mapping(address => uint256) public rewardMultiplier;

    event Staked(address indexed owner, uint256 tokenId);
    event Unstaked(address indexed owner, uint256 tokenId);
    event EmergencyUnstake(address indexed owner, uint256 tokenId);

    constructor(MarketingNFT _marketingNFT) {
        nft = _marketingNFT;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(nft.ownerOf(_tokenId) == _user, "not owner");
        Stake storage userStake = stakes[_user];
        require(userStake.startStaking == 0, "already staked");
        require(block.timestamp > tokenCooldown[_tokenId], 'token on cooldown');

        userStake.startStaking = block.timestamp;
        userStake.owner = _user;
        nft.safeTransferFrom(_user, address(this), _tokenId);
        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        Stake storage userStake = stakes[_user];
        require(userStake.owner == _user, "not owner");
        require(userStake.startStaking + stakingTime < block.timestamp, "not ready");

        uint256 nftRarity = nft.getNftRarity(_tokenId);
        uint256 multiplier = calcRewardMultiplier(nftRarity, userStake.startStaking);
        rewardMultiplier[_user] += multiplier;
        tokenCooldown[_tokenId] = block.timestamp + COOLDOWN[nftRarity];

        nft.safeTransferFrom(address(this), _user, _tokenId);
        
        emit Unstaked(_user, _tokenId);
        userStake.startStaking = 0;
        stakedTotal--;
    }

    function emergencyUnstake(uint256 _tokenId) public {
        _emergencyUnstake(msg.sender, _tokenId);
    }

    function _emergencyUnstake(address _user, uint256 _tokenId) internal {
        Stake storage userStake = stakes[_user];
        require(userStake.owner == _user, "not owner");
        // unstake without saving staking period rewards somewhere
        nft.safeTransferFrom(address(this), _user, _tokenId);
        emit EmergencyUnstake(_user, _tokenId);
        userStake.startStaking = 0;
        stakedTotal--;
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // need to by normilized by (REWARD_EPOCH_SECONDS * 100 * PERCENT_MULTIPLIER)
    function calcRewardMultiplier(uint256 nftRarity, uint256 startStaking) public view returns(uint256) {
        uint256 secondPassed = min(REWARD_EPOCH_SECONDS, SafeMath.sub(block.timestamp, startStaking));
        return SafeMath.mul(secondPassed, INCOME_PERCENT[nftRarity]);
    }

    function getRewardMultiplier(address _address) external view returns (uint256) {
        return rewardMultiplier[_address];
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}