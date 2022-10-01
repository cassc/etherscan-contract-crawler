// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;


/**
* @notice IFireCatNFTStake
*/
interface IFireCatNFTStake {
    /**
    * @dev the state of NFT action.
    */
    enum State {
        locked,
        unstakeable,
        stakeable,
        claimable
    }

    /**
    * @notice the total staked amount.
    * @return totalStaked
    */
    function totalStaked() external view returns (uint256);
    
    /**
    * @notice fetch the staked tokenId of user.
    * @param user_ address
    * @return tokenId
    */
    function stakedOf(address user_) external view returns (uint256);

    /**
    * @notice fetch the max stake number of user.
    * @dev fetch token level from NFT contract.
    * @param user_ address
    * @return stakeMaxNum
    */
    function stakeMaxNumOf(address user_) external view returns (uint256);
    
    /**
    * @notice check whether the user has staked.
    * @param user_ address
    * @return isStaked
    */
    function isStaked(address user_) external view returns (bool);

    /**
    * @notice fetch the staking state of user.
    * @param user_ address
    * @return isStaked
    */
    function stateOf(address user_) external view returns (State);

    /**
    * @notice set the stake max number of token level.
    * @param tokenLevel_ uint256
    * @param maxNum_ uint256
    */
    function setStakeMaxNum(uint256 tokenLevel_, uint256 maxNum_) external;

    /**
    * @notice set the nft fireCatPool address.
    * @param pool_ address
    */
    function setPool(address pool_) external;

    /**
    * @notice set the registryProxy address.
    * @param registryProxy_ address
    */
    function setRegistryProxy(address registryProxy_) external;

    /**
    * @notice The interface of IERC721 withdrawn.
    * @dev Trasfer token to admin.
    * @param tokenId_ uint256.
    */
    function sweep(uint256 tokenId_) external;


    /**
    * @notice The interface of IERC20 withdrawn.
    * @dev Trasfer token to admin.
    * @param token address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, uint256 amount) external returns (uint256);

    /**
    * @notice the interface of stake.
    * @dev firstly, check the state of user.
    * @param tokenId_ uint256
    * @return isStaked
    */
    function stake(uint256 tokenId_) external returns (bool);

    /**
    * @notice the interface of claim.
    * @dev firstly, check the state of user.
    * @return tokenId
    */
    function claim() external returns (uint256);
}