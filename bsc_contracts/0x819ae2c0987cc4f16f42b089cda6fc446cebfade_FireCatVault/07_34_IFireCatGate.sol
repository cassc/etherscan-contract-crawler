// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatGate
*/
interface IFireCatGate {

    /**
    * @notice check the vault address of version.
    * @param version uint256
    * @return vault
    */
    function vaultOf(uint256 version) external view returns (address);

    /**
    * @notice check the totalStaked of user, fetch data from all vault.
    * @param tokenId_ uint256
    * @return totalVaultStaked
    */
    function vaultStakedOf(uint256 tokenId_) external view returns(uint256);

    /**
    * @notice the interface of migrate, fetch data from vaultFrom, stake data to vaultTo
    * @param tokenId uint256
    * @param vaultFrom address
    * @param vaultTo address
    */   
    function migrate(uint256 tokenId, address vaultFrom, address vaultTo) external;

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
    * @notice set the fireCat treasury contract.
    * @dev set to fireCatTreasury.
    * @param fireCatTreasury_ address.
    */
    function setFireCatTreasury(address fireCatTreasury_) external;

    /**
    * @notice the interface of destroy
    * @param tokenId uint256
    */   
    function destroy(uint256 tokenId) external;

}