// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStakedSoccerStarNftV2 {
    struct TokenStakedInfo {
        address owner;
        uint tokenId;
        uint unclaimed;
        uint cooldown;
    }

    // Trigred to stake a nft card
    event Stake(address sender, uint tokenId);

    // Triggered when redeem the staken
    event Redeem(address sender, uint  tokenId);

    // Triggered after unfrozen peroid
    event Withdraw(address sender, uint  tokenId);

    // Triggered when reward is taken
    event ClaimReward(address sender, uint tokenId, uint amount);

    function getTokenOwner(uint tokenId) external view returns(address);

    // protocol to udpate the star level
    function updateStarlevel(uint tokenId, uint starLevel) external;

    // user staken the spcified token
    function stake(uint tokenId) external;

    // user staken multiple tokens
    function stake(uint[] memory tokenIds) external;

    // user redeem the spcified token
    function redeem(uint tokenId) external;

    // user withdraw the spcified token
    function withdraw(uint tokenId) external;

    // Get unclaimed rewards by the specified tokens
    function getUnClaimedRewardsByToken(uint tokenId) 
    external view returns(uint);

    // Get unclaimed rewards by a set of the specified tokens
    function getUnClaimedRewardsByTokens(uint[] memory tokenIds) 
    external view returns(uint[] memory amount);
    
    // Get unclaimed rewards 
    function getUnClaimedRewards(address user) 
    external view returns(uint amount);

    // Claim rewards
    function claimRewards() external;

    function claimRewardsOnbehalfOf(address to) external;

    // Get user stake info by page
    function getUserStakedInfoByPage(address user,uint pageSt, uint pageSz) 
    external view returns(TokenStakedInfo[] memory userStaked);

    // Check if the specified token is staked
    function isStaked(uint tokenId) external view returns(bool);

    // Check if the specified token is unfreezing
    function isUnfreezing(uint tokenId) external view returns(bool);

    function transferOwnershipNFT(uint tokenId, address to) external;

    // Check if the specified token is withdrawable
    function isWithdrawAble(uint tokenId) external view returns(bool);
}