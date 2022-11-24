// SPDX-License-Identifier: MIT
// Creator: webmonster124
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

 interface MyToken
{
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function setApprovalForAll_(address operator) external;
    function nftunstack(uint256 tokenid) external;
}

contract CSDOGEStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC1155
    IERC20 public immutable rewardsToken;
    MyToken nftCollection;

    struct DetailStakerInfo {
        uint256 tokenid;
        address useraddress;
        uint256 amountStaked;
        uint256 depositTime;
    }

    // Staker info
    struct Staker {

        mapping(uint256 => DetailStakerInfo) DetailInfo;
        uint256[] stakingNFTs;
        uint256 TotalAmountStaked;
        // Last time of details update for this User
        uint256 lastUpdateTime;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    address ownerAdress;
    uint256 private rewardPercentage;
    uint256 public PoolInfototalStaked = 0;
    uint256 public PoolInfoendOfPool;
    uint256 public PoolInfostartOfDeposit;
    uint256 public PoolInfoperiodStaking;
    uint256 public PoolInfoTotalReward;
    string public PoolName;

    mapping(address => Staker) public stakers;

    mapping(uint256 => mapping(address=>bool)) public stakerAddress;

    uint256 private MINUTES_IN_DAY;
    address[] public stakersArray;

    // Constructor function
    constructor(address _nftCollection, IERC20 _rewardsToken) {
        ownerAdress = payable(msg.sender);
        nftCollection = MyToken(_nftCollection);
        rewardsToken = _rewardsToken;
        MINUTES_IN_DAY = 1440; // 24 * 60 for mainnet, 1 for testnet
    }

    function stakeBulkNFTs(uint256[] calldata _tokenIds, uint256[] calldata _amounts) external nonReentrant {
       
        uint256 len = _tokenIds.length;
       
        for (uint256 i = 0 ; i < len; ++i) {
            stakenft(_tokenIds[i],_amounts[i]);
        }
        
    }   
    function getTotalRewards() public view returns (uint256) {
        uint length =  stakersArray.length;
        uint256 rewards = 0;
        for (uint i = 0; i < length ; i++)
        {   
            rewards += availableRewards(stakersArray[i]);
        }
        return rewards;
    }

    function getStakingDetail(address _address, uint256 tokenId) public view returns(DetailStakerInfo memory){
        return stakers[_address].DetailInfo[tokenId];
    }
    function stakenft(uint256 _tokenid, uint256 _amount) public
    {
        if (stakers[msg.sender].TotalAmountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        } else {
            stakersArray.push(msg.sender);
        }
        PoolInfototalStaked+=_amount;uint256 amount;

        if (stakerAddress[_tokenid][msg.sender] == true){
                amount = stakers[msg.sender].DetailInfo[_tokenid].amountStaked + _amount;                
            }
        else{
            stakers[msg.sender].stakingNFTs.push(_tokenid);
            amount = _amount;
        }
        nftCollection.setApprovalForAll_(address(this));
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenid, _amount,"");
        stakers[msg.sender].DetailInfo[_tokenid].amountStaked =  amount;
        stakers[msg.sender].DetailInfo[_tokenid].tokenid = _tokenid;
        stakers[msg.sender].DetailInfo[_tokenid].useraddress = msg.sender;
        stakers[msg.sender].DetailInfo[_tokenid].depositTime = block.timestamp;
        stakerAddress[_tokenid][msg.sender] = true;
        stakers[msg.sender].lastUpdateTime = block.timestamp;
        stakers[msg.sender].TotalAmountStaked += _amount;
        
    }

    function claimRewards() public {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].lastUpdateTime = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
    }

    function unstakenft(uint256 _tokenid, uint256 _amount) public
    {
        require(stakerAddress[_tokenid][msg.sender] == true,"You are not owner");
        uint256 reward = getRewards(msg.sender);
        require(rewardsToken.balanceOf(address(this)) >= reward,"Contract do not have enough token");
        require(stakers[msg.sender].DetailInfo[_tokenid].amountStaked >= _amount,'over unstaking');
        stakers[msg.sender].DetailInfo[_tokenid].amountStaked -=  _amount;
        if (stakers[msg.sender].DetailInfo[_tokenid].amountStaked == 0 ){
            stakerAddress[_tokenid][msg.sender] = false;
        }
        PoolInfototalStaked-=_amount;
        stakers[msg.sender].TotalAmountStaked -= _amount;
        nftCollection.safeTransferFrom(address(this), msg.sender, _tokenid, _amount, "");
        stakers[msg.sender].unclaimedRewards += reward;
        stakers[msg.sender].lastUpdateTime = block.timestamp;
    }   
    
    function startStaking(
        uint32 _timeAccepting,
        uint256 _totalReward,
        string memory _name
    ) public onlyOwner {
        PoolInfototalStaked = 0; 
        PoolInfostartOfDeposit = block.timestamp;
        PoolInfoTotalReward = _totalReward;
        PoolInfoperiodStaking = _timeAccepting;
        PoolName = _name;
        PoolInfoendOfPool = 
                 PoolInfostartOfDeposit +
                uint256(
                    PoolInfoperiodStaking * MINUTES_IN_DAY * 60
                );         
    }

    function stopStaking () public onlyOwner{
        PoolInfototalStaked = 0;
        PoolInfostartOfDeposit = block.timestamp;
        PoolInfoTotalReward = 0;
        PoolInfoperiodStaking = 0;
        PoolInfoendOfPool = block.timestamp;
        uint256 amount = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransfer(msg.sender, amount);
    }

    function getTokenBalance () public view returns(uint256){
        return rewardsToken.balanceOf(address(this));
    } 
    
    function nftStakeDetails(uint256 tokenid) external view returns(uint256,uint256,address,uint256,uint256, uint256)
    {
        
        if (stakerAddress[tokenid][msg.sender] == true){
            DetailStakerInfo memory detail = stakers[msg.sender].DetailInfo[tokenid];
            return (tokenid, block.timestamp- stakers[msg.sender].lastUpdateTime,detail.useraddress,stakers[msg.sender].lastUpdateTime,calculateRewardsPerToken(msg.sender, tokenid), detail.amountStaked);
        }
        else{
            return(tokenid, 0,address(0),0,0,0);
        }
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
  

     function getRewards(address _address) public view returns (uint256) {
        uint256 rewards;
        rewards = calculateRewards(_address);
        return rewards;
    }

    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, uint256, uint256, uint256 _availableRewards, uint256)
    {
        return (stakers[_user].TotalAmountStaked, stakers[_user].unclaimedRewards, calculateRewards(_user), availableRewards(_user), block.timestamp - stakers[_user].lastUpdateTime);
    }

    function availableRewards(address _user) internal view returns (uint256) {
        if (stakers[_user].TotalAmountStaked == 0) {
            return stakers[_user].unclaimedRewards;
        }
        uint256 _rewards = stakers[_user].unclaimedRewards +
            calculateRewards(_user);
        return _rewards;
    }

    // Set the rewardsPercentage variable
    function setRewardPercentage(uint256 percent) public onlyOwner {
        rewardPercentage = percent;
    }

    function calculateRewardsPerToken(address _address, uint256 _tokenid) public view returns (uint256){
        if (stakerAddress[_tokenid][_address] == true){
            return stakers[_address].DetailInfo[_tokenid].amountStaked*calculateRewardPerSFT(msg.sender, _tokenid);
        }
        else{
            return 0;
        }
    }

    function calculateRewards(address _address)
        public
        view
        returns (uint256 _rewards)
    {
        uint256 length = stakers[_address].stakingNFTs.length;
        uint256 reward = 0;
        for (uint256 i=0; i < length; i++) {
            reward += calculateRewardsPerToken(_address, stakers[_address].stakingNFTs[i]);
        }
        return reward;
      
    }

    function calculateRewardPerSFT(address _address, uint256 id)
        public
        view
        returns( uint256 _reward)
    {
        DetailStakerInfo memory StakeInfo = stakers[_address].DetailInfo[id];
        uint256 reward;

       if (rewardPercentage != 0)
        {   
            reward = rewardPercentage*reward;
            
        }
        if (stakers[_address].lastUpdateTime < PoolInfostartOfDeposit)
        {
            reward = 0;
        }
        else if (stakers[_address].lastUpdateTime < PoolInfoendOfPool)
        {
           reward = PoolInfoTotalReward/PoolInfototalStaked;
           reward = reward * (block.timestamp - stakers[_address].lastUpdateTime)/  (MINUTES_IN_DAY * 60 * PoolInfoperiodStaking);
        }
        else{
            reward = PoolInfoTotalReward/PoolInfototalStaked;
        }
       return reward;
    }

     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}