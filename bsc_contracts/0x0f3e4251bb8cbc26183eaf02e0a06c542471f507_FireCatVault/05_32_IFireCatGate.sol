// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatGate
*/
interface IFireCatGate {
    
    /**
    * @notice the total staked amount.
    * @return totalStaked
    */
    function totalStaked() external view returns (uint256);

    /**
    * @notice check the vault address of version.
    * @param version uint256
    * @return vault
    */
    function vaultOf(uint256 version) external view returns (address);

    /**
    * @notice check the user address of tokenId.
    * @param tokenId uint256
    * @return user
    */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
    * @notice check the staked tokenId
    * @param user_ address
    * @return staked
    */
    function stakedOf(address user_) external view returns (uint256);
    /**
    * @notice check whether the user has staked.
    * @param user_ address
    * @return hasStaked
    */
    function hasStaked(address user_) external view returns (bool);

    /**
    * @notice check the totalStaked of user, fetch data from all vault.
    * @param tokenId_ uint256
    * @return totalVaultStaked
    */
    function vaultStakedOf(uint256 tokenId_) external view returns(uint256);

    /**
    * @notice the interface of migrate, fetch data from vaultFrom, stake data to vaultTo
    * @param vaultFrom address
    * @param vaultTo address
    */   
    function migrate(address vaultFrom, address vaultTo) external;

    /**
    * @notice the stake switch, default is false
    * @param isMigrateOn_ bool
    */   
    function setMigrateOn(bool isMigrateOn_) external;

    /**
    * @notice the stake switch, default is false
    * @param isDestroyOn_ bool
    */    
    function setDestroyOn(bool isDestroyOn_) external;

    /**
    * @notice set vault list.
    * @param vaultVersions_ uint256[]
    * @param vaultAddress_ address[]
    */
    function setVault(uint256[] calldata vaultVersions_, address[] calldata vaultAddress_) external;

    /**
    * @notice set black list.
    * @param blackList_ address[]
    * @param blocked_ bool
    */
    function setBlackList(address[] calldata blackList_, bool blocked_) external;

    /**
    * @notice the interface of stake
    * @param tokenId_ uint256
    */
    function stake(uint256 tokenId_) external;

    /**
    * @notice the interface of claim
    * @return tokenId
    */  
    function claim() external returns (uint256);

    /**
    * @notice the interface of destroy
    */   
    function destroy() external;

}