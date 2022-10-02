// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatGate
*/
interface IFireCatVault {
    /**
    * @notice check user's stake qualified.
    * @dev access data from fireCatGate
    * @param user_ address.
    * @return actualSubAmount
    */
    function isQualified(address user_) external view returns (bool);
    
    /**
    * @notice The tokenId of stake in gate contract.
    * @dev access data from fireCatGate.
    * @param user_ address.
    */
    function tokenIdOf(address user_) external view returns (uint256);

    /**
    * @notice The interface of stake token migrate in.
    * @dev Trasfer token to vault.
    * @param tokenId_ address.
    * @param amount_ uint256.
    */
    function migrateIn(uint256 tokenId_, uint256 amount_) external returns(uint256);

    /**
    * @notice The interface of stake token migrate out.
    * @dev Trasfer token to msg.sender.
    * @param user_ address.
    * @param tokenId_ address.
    * @param amount_ uint256.
    */
    function migrateOut(address user_, uint256 tokenId_, uint256 amount_) external returns (uint256);

    /**
    * @notice The interface of token withdrawn.
    * @dev Trasfer token to to_address.
    * @param token address.
    * @param to address.
    * @param amount uint256.
    */
    function claimTokens(address token, address to, uint256 amount) external;

    /**
    * @dev Withdraw staked tokens without caring about rewards rewards
    * @notice Use cautiously and exit with guaranteed principal!!!
    * @param smartChefArray_ Pool address
    * @param urgent_ Locked state
    * @dev Needs to be for emergency.
    */
    function projectEmergencyWithdraw(address[] calldata smartChefArray_, bool urgent_) external;

    /**
    * @notice the interface of stake
    * @param amount_ uint256.
    */
    function stake(uint256 amount_) external;

    /**
    * @notice the interface of claim
    * @param tokenId_ uint256.
    */    
    function claim(uint256 tokenId_) external;

    /**
    * @notice the interface of exitFunds
    * @param tokenId_ uint256.
    * @param user_ address..
    * @return actualSubAmount
    */
    function exitFunds(uint256 tokenId_, address user_) external returns(uint256);
}