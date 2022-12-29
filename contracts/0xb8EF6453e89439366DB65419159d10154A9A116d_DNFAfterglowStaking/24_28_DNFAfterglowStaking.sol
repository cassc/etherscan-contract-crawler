// SPDX-License-Identifier: MIT
// Creator: ETC
pragma solidity ^0.8.4;

import { DateTimeLib } from './lib/DateTimeLib.sol';
import { BokkyPooBahsDateTimeLibrary } from './lib/BokkyPooBahsDateTimeLibrary.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@thirdweb-dev/contracts/extension/Upgradeable.sol";
import "@thirdweb-dev/contracts/extension/Initializable.sol";
import "./Releasable.sol";

contract DNFAfterglowStaking is Initializable, Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public _owner;

    struct StakedAsset {
        address owner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 reward;
        bool onGoing;
    }

    struct StakedAssetExtra {
        address owner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 reward;
        bool onGoing;
        uint256 totalExp;
    }

    struct UnclaimedReward {
        address owner;
        uint256 tokenId;
        uint256 reward;
        uint256 stackedAt;
        uint256 unstackAt;
    }

    struct StakedExperience {
        uint256 tokenId;
        uint256 accumulateDays;
    }

    struct StakeHolderToken {
        uint256[] tokenId;
        address owner;
    }

    struct StakerUnclaimed {
        UnclaimedReward[] unclaimedRewards;
        address owner;
    }

    IERC20Upgradeable public rewardsToken; // Should be USDT
    IERC721Upgradeable public nftCollection;

    uint256 public rewardPerToken;

    mapping(uint256 => UnclaimedReward) public unclaimedRewards;
    mapping(uint256 => StakedAsset) public stakedAssets;
    mapping(uint256 => StakedExperience) public stakedExperience;
    mapping(address => StakeHolderToken) public stakeHolderTokens;
    mapping(address => StakerUnclaimed) public stakerUnclaims;

    function initialize(address _deployer, IERC721Upgradeable _nftCollection, IERC20Upgradeable _rewardsToken, uint256 _rewardPerToken) external payable initializer {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        rewardPerToken = _rewardPerToken;
        _owner = _deployer;
    }

    function _authorizeUpgrade(address) internal view override {
		require(msg.sender == _owner);
	}

    function stake(uint256[] calldata _tokenIds) external {
        require(_tokenIds.length != 0, "Staking: No tokenIds provided");

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Ownable: caller is not the owner"
            );

            // Transfer the token from the wallet to the Smart contract
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            // Add the token to the stakedTokens array

            StakedAsset memory stakedAsset = StakedAsset(msg.sender, _tokenIds[i], block.timestamp, rewardPerToken, true);
            stakeHolderTokens[msg.sender].tokenId.push(_tokenIds[i]);
            stakedAssets[_tokenIds[i]] = stakedAsset;
        }
    }

    function withdraw(uint256[] calldata _tokenIds) external {
        require(
            stakeHolderTokens[msg.sender].tokenId.length > 0,
            "You have no tokens staked"
        );

        uint256 reward = 0;

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                stakedAssets[_tokenIds[i]].owner == msg.sender,
                "You don't own this token!"
            );

            stakedAssets[_tokenIds[i]].owner = address(0);
            stakedAssets[_tokenIds[i]].onGoing = false;

            StakedExperience memory exp = stakedExperience[_tokenIds[i]];

            uint256 currentStakedTime = BokkyPooBahsDateTimeLibrary.diffDays(stakedAssets[_tokenIds[i]].stakedAt,block.timestamp);

            stakedExperience[_tokenIds[i]].accumulateDays = exp.accumulateDays + currentStakedTime;

            delete stakedAssets[_tokenIds[i]];

            for (uint256 x; x < stakeHolderTokens[msg.sender].tokenId.length; ++x) {

                if(stakeHolderTokens[msg.sender].tokenId[x] == _tokenIds[i]){
                    delete stakeHolderTokens[msg.sender].tokenId[x];
                }

            }

            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    //////////
    // View //
    //////////

    function balanceOf(address _user) public view returns (uint256 _tokensStaked) {
        return (getAssetsCount(_user));
    }

    function getUnclaimed() public view returns (uint256){

        UnclaimedReward[] memory unclaim = stakerUnclaims[msg.sender].unclaimedRewards;

        uint256 total = 0;
        if(unclaim.length > 0) {
            for (uint256 index = 0; index < unclaim.length; index++) {
                total += unclaim[index].reward;
            }
        }

        return total;
    }

    function getExperience(uint256 tokenId) public view returns (uint256){

        StakedExperience memory exp = stakedExperience[tokenId];
        StakedAsset memory stakedToken = stakedAssets[tokenId];

        uint256 currentStakedTime  = BokkyPooBahsDateTimeLibrary.diffHours(stakedToken.stakedAt,block.timestamp);

        return ((exp.accumulateDays*24) + currentStakedTime);

    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function getAssets(address _user) public view returns(StakedAssetExtra[] memory){

        uint256 totalExp = 0;
        uint256 stakedTokenId = 0;

        uint256[] memory stakedTokenIds = stakeHolderTokens[_user].tokenId;

        StakedAssetExtra[] memory tempStakedAssetsExtra = new StakedAssetExtra[](stakeHolderTokens[_user].tokenId.length);

        for (uint256 index = 0; index < stakeHolderTokens[_user].tokenId.length; index++) {
            stakedTokenId = stakedTokenIds[index];

            (totalExp) = getExperience(stakedTokenId);

            tempStakedAssetsExtra[index].owner = stakedAssets[stakedTokenId].owner;
            tempStakedAssetsExtra[index].tokenId = stakedAssets[stakedTokenId].tokenId;
            tempStakedAssetsExtra[index].stakedAt = stakedAssets[stakedTokenId].stakedAt;
            tempStakedAssetsExtra[index].reward = stakedAssets[stakedTokenId].reward;
            tempStakedAssetsExtra[index].onGoing = stakedAssets[stakedTokenId].onGoing;
            tempStakedAssetsExtra[index].totalExp = totalExp;
        }

        return tempStakedAssetsExtra;
    }

    function getAssetsCount(address _user) public view returns(uint256){

        uint256 stackedAssetsCount = 0;

        for (uint256 index = 0; index < stakeHolderTokens[_user].tokenId.length; index++) {
            if(stakedAssets[stakeHolderTokens[_user].tokenId[index]].owner == _user) {
                stackedAssetsCount++;
            }
        }

        return stackedAssetsCount;
    }

    function setUnclaimed(address owner, uint256 reward) external onlyOwner  {
        stakerUnclaims[owner].owner = address(0);
        delete stakerUnclaims[owner];

        UnclaimedReward memory unclaimedReward = UnclaimedReward(owner,0,reward,block.timestamp , block.timestamp);
        stakerUnclaims[owner].unclaimedRewards.push(unclaimedReward);
    }

    function calculateTotalRewards ()
        public
        view
        returns (uint256 _rewards)
    {

        _rewards = _rewards + getUnclaimed();
    }

    function claimAllRewards() external {

        uint256 calculatedRewards = 0;

        calculatedRewards = getUnclaimed();

        // uint256 unclaimed = getUnclaimed();

        require(calculatedRewards > 0, "You have no rewards to claim");

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint wallet = rewardsToken.balanceOf(address(this));

        require(calculatedRewards <= wallet, "Staking: Insufficient rewards in the contract");

        rewardsToken.safeTransfer(msg.sender, calculatedRewards);
        stakerUnclaims[msg.sender].owner = address(0);
        delete stakerUnclaims[msg.sender];
    }


}