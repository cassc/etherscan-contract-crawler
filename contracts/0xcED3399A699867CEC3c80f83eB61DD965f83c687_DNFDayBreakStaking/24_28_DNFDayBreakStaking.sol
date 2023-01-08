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

contract DNFDayBreakStaking is Initializable, Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public _owner;

    struct StakedAsset {
        address owner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 reward;
        uint256 lastClaimedDate;
        bool onGoing;
    }

    struct StakedAssetExtra {
        address owner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 reward;
        uint256 lastClaimedDate;
        bool onGoing;
        uint256 nextPayoutAt;
        uint256 nextPayoutDays;
        uint256 totalExp;
        uint256 totalRewards;
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
        uint256 accumulateRewards;
    }

    struct Stakeholder {
        uint256 balance;
        StakedAsset[] stakedAssets;
        address[] rewards;
    }

    struct StakeHolderToken {
        uint256[] tokenId;
        address owner;
    }

    struct StakerUnclaimed {
        UnclaimedReward[] unclaimedRewards;
        address owner;
    }

    struct Reward {
        address owner;
        address token;
        address rate;
        uint256 amount;
        uint256 createdAt;
    }

    struct Rate {
        uint year;
        uint quarter;
        uint value;
    }

    IERC20Upgradeable public rewardsToken; // Should be USDT
    IERC721Upgradeable public nftCollection;
    Rate[] public rates;

    uint256 public rewardPerToken;

    mapping(uint256 => UnclaimedReward) public unclaimedRewards;
    mapping(uint256 => StakedAsset) public stakedAssets;
    mapping(address => Reward) public rewards;
    mapping(address => Stakeholder) public stakeholders;
    mapping(uint256 => StakedExperience) public stakedExperience;
    mapping(address => StakerUnclaimed) public stakerUnclaims;
    mapping(address => StakeHolderToken) public stakeHolderTokens;


    address[] public claimedRewards;

    uint8 migrated = 0;

    function initialize(address _deployer, IERC721Upgradeable _nftCollection, IERC20Upgradeable _rewardsToken, uint256 _rewardPerToken) external payable initializer {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        rewardPerToken = _rewardPerToken;
        _owner = _deployer;
    }

    function _authorizeUpgrade(address) internal view override {
		require(msg.sender == _owner);
	}

    function getRate(uint year, uint quarter) public view returns (uint256){
        uint256 rate = 0;
        bool found = false;

        if(rates.length > 0) {
            for (uint256 index = 0; index < rates.length; index++) {
                if (rates[index].year == year && rates[index].quarter == quarter) {
                    rate = rates[index].value;
                    found = true;
                    break;
                }
            }

            if (!found) {
                rate = rates[rates.length - 1].value;
            }
        }

        return rate;
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

    function rewardCalculator(uint256 _stakeToken , bool calFirstTime) public view returns (uint256){

        StakedAsset memory stakedToken = stakedAssets[_stakeToken];
        bool check = false;

        uint256 currentBlockTs = block.timestamp;
        currentBlockTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(currentBlockTs), BokkyPooBahsDateTimeLibrary.getMonth(currentBlockTs), BokkyPooBahsDateTimeLibrary.getDay(currentBlockTs));

        // Check if timestamp meet at least 3 months
        uint256 currentTs = DateTimeLib.addDays(DateTimeLib.getEndOfPreviousQuarter(currentBlockTs),1);

        uint256 realQuater = DateTimeLib.getQuarter(DateTimeLib.getEndOfPreviousQuarter(currentBlockTs));
        uint256 reward = 0;

        if(stakedToken.owner == address(0)) {
            return reward;
        }

        uint256 stakeAtTs = stakedToken.stakedAt;
        if(stakeAtTs < stakedToken.lastClaimedDate){
            stakeAtTs = stakedToken.lastClaimedDate;
        }

        // Set stakeAtTs to Start of Day
        stakeAtTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(stakeAtTs), BokkyPooBahsDateTimeLibrary.getMonth(stakeAtTs), BokkyPooBahsDateTimeLibrary.getDay(stakeAtTs));

        // Skip if it is stake in within current quarter
        if (calFirstTime == false){
            uint256 previousQTs = BokkyPooBahsDateTimeLibrary.subMonths(currentTs,3);
            if(stakeAtTs < currentTs && BokkyPooBahsDateTimeLibrary.diffDays(stakeAtTs, currentTs) < BokkyPooBahsDateTimeLibrary.diffDays(previousQTs, currentTs)) {
                check = true;
            }
        }

        while (check == false)
        {
            uint256 rate = getRate(BokkyPooBahsDateTimeLibrary.getYear(currentTs-1), realQuater);
            uint256 rewardPerQuater =  (stakedToken.reward * rate) * 100;

            currentTs = BokkyPooBahsDateTimeLibrary.subMonths(currentTs,3);

            if(stakeAtTs <= currentTs){
                reward += (rewardPerQuater / 4);
            }else{
                uint256 endofquater = BokkyPooBahsDateTimeLibrary.addMonths(currentTs,3);

                if(stakeAtTs > endofquater){
                    check = true;
                }else{
                    check = true;
                    uint256 dayDiff = BokkyPooBahsDateTimeLibrary.diffDays(stakeAtTs,endofquater);

                    uint256 totalDayOfQuater = BokkyPooBahsDateTimeLibrary.diffDays(currentTs,endofquater) ;
                    uint256 rewardCurrentQuater = (((rewardPerQuater) * dayDiff)  / totalDayOfQuater)/4;
                    reward += rewardCurrentQuater;
                }


            }

            if(realQuater == 1){
                realQuater = 4;
            }else{
                realQuater = realQuater - 1;
            }

        }
        return reward;
    }

    function rewardPerDay(uint256 rate, uint256 amount) internal pure returns (uint256) {
        return (rate * amount) / 100 / 365;
    }

    function updateLastClaimDate(uint256 _stakeToken) internal {
        StakedAsset memory stakedToken = stakedAssets[_stakeToken];

        uint256 currentBlockTs = block.timestamp;
        currentBlockTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(currentBlockTs), BokkyPooBahsDateTimeLibrary.getMonth(currentBlockTs), BokkyPooBahsDateTimeLibrary.getDay(currentBlockTs));

        // Check if timestamp meet at least 3 months
        uint256 currentTs = DateTimeLib.addDays(DateTimeLib.getEndOfPreviousQuarter(currentBlockTs),1);

        uint256 stakeAtTs = stakedToken.stakedAt;
        if(stakeAtTs < stakedToken.lastClaimedDate){
            stakeAtTs = stakedToken.lastClaimedDate;
        }

        // Set stakeAtTs to Start of Day
        stakeAtTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(stakeAtTs), BokkyPooBahsDateTimeLibrary.getMonth(stakeAtTs), BokkyPooBahsDateTimeLibrary.getDay(stakeAtTs));

        if(stakeAtTs <= BokkyPooBahsDateTimeLibrary.subMonths(currentTs,3)){
            stakedToken.lastClaimedDate = currentTs;
            stakedAssets[_stakeToken] = stakedToken;
        }

    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
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

            StakedAsset memory stakedAsset = StakedAsset(msg.sender, _tokenIds[i], block.timestamp, rewardPerToken, 0, true);
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

            reward = rewardCalculator(_tokenIds[i],false);
            UnclaimedReward memory unclaimedReward = UnclaimedReward(msg.sender,_tokenIds[i],reward,stakedAssets[_tokenIds[i]].stakedAt , block.timestamp);
            stakerUnclaims[msg.sender].unclaimedRewards.push(unclaimedReward);

            stakedAssets[_tokenIds[i]].owner = address(0);
            stakedAssets[_tokenIds[i]].onGoing = false;

            StakedExperience memory exp = stakedExperience[_tokenIds[i]];
            stakedExperience[_tokenIds[i]].accumulateRewards = exp.accumulateRewards + reward;

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

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards(uint256 tokenId) external {

        uint256 calculatedRewards = 0;

        calculatedRewards = rewardCalculator(tokenId,false);

        // uint256 unclaimed = getUnclaimed();

        require(calculatedRewards > 0, "You have no rewards to claim");

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint wallet = rewardsToken.balanceOf(address(this));

        require(calculatedRewards <= wallet, "Staking: Insufficient rewards in the contract");
        StakedExperience memory exp = stakedExperience[tokenId];

        stakedExperience[tokenId].accumulateRewards = exp.accumulateRewards + calculatedRewards;

        updateLastClaimDate(tokenId);

        rewardsToken.safeTransfer(msg.sender, calculatedRewards);
        emit RewardPaid(msg.sender, calculatedRewards);
    }

    function claimAllRewards() external {

        uint256 calculatedRewards = 0;

        calculatedRewards = calculateTotalRewards();

        // uint256 unclaimed = getUnclaimed();

        require(calculatedRewards > 0, "You have no rewards to claim");

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint wallet = rewardsToken.balanceOf(address(this));

        require(calculatedRewards <= wallet, "Staking: Insufficient rewards in the contract");

        for (uint256 index = 0; index < stakeHolderTokens[msg.sender].tokenId.length; index++) {
            updateLastClaimDate(stakeHolderTokens[msg.sender].tokenId[index]);
        }
        rewardsToken.safeTransfer(msg.sender, calculatedRewards);

        stakerUnclaims[msg.sender].owner = address(0);
        delete stakerUnclaims[msg.sender];

        emit RewardPaid(msg.sender, calculatedRewards);
    }

    // Set the rewardsPerHour variable
    // Because the rewards are calculated passively, the owner has to first update the rewards
    // to all the stakers, witch could result in very heavy load and expensive transactions or
    // even reverting due to reaching the gas limit per block. Redesign incoming to bound loop.
    function setRate(uint256 _year, uint256 _quarter, uint _value) external onlyOwner  {

        Rate memory rate = Rate(_year, _quarter, _value);
        rates.push(rate);
        emit RateAdded(_year, _quarter, _value);
    }

    // Function to migrate data from stakeholders into stakeHolderTokens
    function migrateFromV1(uint256 _no_of_stakedAsset) external onlyOwner {

        StakedAsset memory tempStakedAsset;

        require(migrated == 0, "Already been migrated before");
        
        for (uint index = 0; index < _no_of_stakedAsset; index++) {
            tempStakedAsset = stakedAssets[index];
            stakeHolderTokens[tempStakedAsset.owner].tokenId.push(tempStakedAsset.tokenId);
        }
        migrated = 1;
        
    }

    // Function to set
    function setStakedExperience(uint256 tokenId, uint256 accumulateRewards, uint256 accumulateDays) external onlyOwner {
        StakedExperience memory exp = stakedExperience[tokenId];
        stakedExperience[tokenId].accumulateRewards = accumulateRewards;
        stakedExperience[tokenId].accumulateDays = accumulateDays;
    }

    //////////
    // View //
    //////////

    function balanceOf(address _user) public view returns (uint256 _tokensStaked, uint256 _availableRewards) {
        return (getAssetsCount(_user), calculateTotalRewards());
    }

    function calculateRewards (uint256 _stakeToken)
        public
        view
        returns (uint256 _rewards)
    {
        _rewards = rewardCalculator(_stakeToken,false);
    }

    function calculateTotalRewards ()
        public
        view
        returns (uint256 _rewards)
    {
        for (uint index = 0; index < stakeHolderTokens[msg.sender].tokenId.length; index++) {
            _rewards += rewardCalculator(stakeHolderTokens[msg.sender].tokenId[index],false);
        }

        _rewards = _rewards + getUnclaimed();
    }

    function getExperience(uint256 tokenId) public view returns (uint256 , uint256){

        StakedExperience memory exp = stakedExperience[tokenId];
        StakedAsset memory stakedToken = stakedAssets[tokenId];

        uint256 ongoing = rewardCalculator(tokenId,true);

        uint256 currentStakedTime  = BokkyPooBahsDateTimeLibrary.diffHours(stakedToken.stakedAt,block.timestamp);

        return (exp.accumulateRewards + ongoing , (exp.accumulateDays*24) + currentStakedTime);

    }

    function getNextPayout(uint256 tokenId) public view returns (uint256,uint256){

        StakedAsset memory stakedToken = stakedAssets[tokenId];

        uint256 currentBlockTs = block.timestamp;
        currentBlockTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(currentBlockTs), BokkyPooBahsDateTimeLibrary.getMonth(currentBlockTs), BokkyPooBahsDateTimeLibrary.getDay(currentBlockTs));

        // Check if timestamp meet at least 3 months
        uint256 currentTs = DateTimeLib.addDays(DateTimeLib.getEndOfPreviousQuarter(currentBlockTs),1);
        uint256 stakeAtTs = stakedToken.stakedAt;
        uint256 nextPayoutAt = currentTs;

        if(stakeAtTs < stakedToken.lastClaimedDate){
            stakeAtTs = stakedToken.lastClaimedDate;
        }

        // Set stakeAtTs to Start of Day
        stakeAtTs = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(stakeAtTs), BokkyPooBahsDateTimeLibrary.getMonth(stakeAtTs), BokkyPooBahsDateTimeLibrary.getDay(stakeAtTs));

        uint256 previousQTs = BokkyPooBahsDateTimeLibrary.subMonths(currentTs,3);

        if(stakeAtTs <= currentTs && BokkyPooBahsDateTimeLibrary.diffDays(stakeAtTs, currentTs) < BokkyPooBahsDateTimeLibrary.diffDays(previousQTs, currentTs)) {
            nextPayoutAt = BokkyPooBahsDateTimeLibrary.addMonths(currentTs,3);
        }

        if(stakeAtTs > currentTs) {
            nextPayoutAt = BokkyPooBahsDateTimeLibrary.addMonths(currentTs,6);
        }

        if(nextPayoutAt < currentBlockTs) {
            nextPayoutAt = BokkyPooBahsDateTimeLibrary.addMonths(nextPayoutAt,3);
        }

        uint256 nextPayoutDays = BokkyPooBahsDateTimeLibrary.diffDays(stakeAtTs, nextPayoutAt);

        return (nextPayoutAt, nextPayoutDays);
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

    event RewardPaid(address indexed user, uint256 reward);
    event RateAdded(uint256 _year, uint256 _quarter, uint _value);

    function getAssets(address _user) public view returns(StakedAssetExtra[] memory){

        uint256 nextPayoutAt = 0;
        uint256 nextPayoutDays = 0;
        uint256 totalExp = 0;
        uint256 totalRewards = 0;

        uint256 stakedTokenId = 0;

        uint256[] memory stakedTokenIds = stakeHolderTokens[_user].tokenId;

        StakedAssetExtra[] memory tempStakedAssetsExtra = new StakedAssetExtra[](stakeHolderTokens[_user].tokenId.length);

        for (uint256 index = 0; index < stakeHolderTokens[_user].tokenId.length; index++) {
            stakedTokenId = stakedTokenIds[index];

            (nextPayoutAt, nextPayoutDays) = getNextPayout(stakedTokenId);
            (totalRewards, totalExp) = getExperience(stakedTokenId);

            tempStakedAssetsExtra[index].owner = stakedAssets[stakedTokenId].owner;
            tempStakedAssetsExtra[index].tokenId = stakedAssets[stakedTokenId].tokenId;
            tempStakedAssetsExtra[index].stakedAt = stakedAssets[stakedTokenId].stakedAt;
            tempStakedAssetsExtra[index].reward = stakedAssets[stakedTokenId].reward;
            tempStakedAssetsExtra[index].lastClaimedDate = stakedAssets[stakedTokenId].lastClaimedDate;
            tempStakedAssetsExtra[index].onGoing = stakedAssets[stakedTokenId].onGoing;
            tempStakedAssetsExtra[index].totalExp = totalExp;
            tempStakedAssetsExtra[index].totalRewards = totalRewards;
            tempStakedAssetsExtra[index].nextPayoutAt = nextPayoutAt;
            tempStakedAssetsExtra[index].nextPayoutDays = nextPayoutDays;
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

}