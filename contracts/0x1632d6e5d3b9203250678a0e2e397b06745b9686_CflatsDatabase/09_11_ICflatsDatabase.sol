// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The interface for implementing the CflatsDatabase smart contract 
/// with a full description of each function and their implementation 
/// is presented to your attention.

pragma solidity ^0.8.18;

interface ICflatsDatabase 
{
    /// @dev Emitted when new user is added
    ///`user` is the address of account that should be added
    event UserInserted(address indexed user);


    /// @dev Emitted when user is removed
    /// `user` is the address of account that should be removed
    event UserRemoved(address indexed user);


    /// @dev Emitted when user is added in blacklist
    /// `user` is the address of account that should be added in blacklist
    event UserBlacklisted(address indexed user);


    /// @dev Emitted when user is removed from blacklist
    /// `user` is the address of account that should be removed from blacklist
    event UserRemovedFromBlacklist(address indexed user);


    
    /// @dev Table cell of default user data in database
    ///
    /// `_account` is the address of oae also account address is an id of user
    /// `_role` is the current role for user, by default is USER_ROLE
    ///
    /// There are four types of roles:
    /// `DEFAULT_ADMIN_ROLE` - role granted only for admin of database
    /// `USER_ROLE` - default role for any user added in database
    /// `OPERATOR_ROLE` - role for special mechanisms/bots that should autamatically do
    /// special intermediate calls that are not allowed for USER_ROLE
    /// `DEVELOPER_ROLE` - the same accessibility role as OPERATOR_ROLE the difference is
    /// that this role is intended exclusively for tests on the testnet and 
    /// should not be used in the mainnet network
    struct User
    {
        address _account;
        bytes32 _role;
    }




    //************************* startregion: VARIABLES  *************************//

    /// @dev OAE wallet for team
    ///
    /// This wallet is used as a collection of fees, funds, 
    /// donations, to support the project development team
    /// @return address of team wallet
    function TEAM_WALLET() external view returns (address);


    
    /// @dev This role is given to all users who, for whatever reason,
    /// violate the rules of the project, scammers, fraudsters
    /// @return 0x000000000000000000000000000000000000000000000000000000000000dead
    function BLACKLISTED_ROLE() external view returns (bytes32);


    /// @dev The role is given to bots to automate some processes or 
    /// to be used as intermediaries between the user and the contract
    /// 
    /// NOTE: OPERATOR_ROLE can be granted for other contracts as well as for
    /// intermediate parties as bots
    ///
    /// @return 0x0000000000000000000000000000000000000000000000000000000000000001
    function OPERATOR_ROLE() external view returns (bytes32);


    
    /// @dev The role is intended only for tests on the testnet,
    /// to check the correct operability of the contract
    ///
    /// NOTE: should be only used on testnet
    ///
    /// @return 0x0000000000000000000000000000000000000000000000000000000000000002
    function DEVELOPER_ROLE() external view returns (bytes32);


    
    /// @dev Default role for any user added in database
    /// @return 0x0000000000000000000000000000000000000000000000000000000000000003
    function USER_ROLE() external view returns (bytes32);

    //************************* endregion: VARIABLES  *************************//




    //************************* startregion: CALLABLE FUNCTIONS  *************************//

    /// @dev Returns true for account that is added is blacklist  
    /// @param user - account address of user saved in db
    /// @return false if user not registered in db or not blacklisted
    function isBlacklisted(address user) external view returns (bool);


    /// @dev Returns true if user was added in database and not removed
    /// @param user - account address of user saved in db
    /// @return false if user is not registered in db
    function userExists(address user) external view returns (bool);


    /// @dev Returns table cell of user by it's account address
    /// @param user - account address of user saved in db
    /// @return table cell with user data
    function getUserByAccountAddress(address user) external view returns (User memory);


    /// @dev Returns count of all users that was added in database table
    function getUsersCount() external view returns (uint256);
    
    //************************* startregion: CALLABLE FUNCTIONS  *************************//




    //************************* startregion: SEND FUNCTIONS  *************************//
    
    /// @dev Adds user by account address
    /// @custom:accessibility OPERATOR_ROLE
    /// NOTE: it's highly access function callable only via OPERATOR_ROLE
    /// Also only never added accounts will be added without dubbing
    ///
    /// @return true if transaction is successfull or user 
    /// has never been added in database before
    function addUser(address user) external returns (bool);


    /// @dev Adds many users by account addresses
    /// @custom:accessibility OPERATOR_ROLE
    /// NOTE: it's highly access function callable only via OPERATOR_ROLE
    /// Also only never added accounts will be added without dubbing
    /// 
    /// @return true if transaction is successfull
    function addUsersBatch(address[] calldata users) external returns (bool);


    /// @dev Remove user by account address
    /// @custom:accessibility OPERATOR_ROLE
    /// @custom:requires user to be existed in database otherwise it will revert with
    /// error UserDoesNotExistsError(address user)
    ///
    /// NOTE: it's highly access function callable only via OPERATOR_ROLE
    /// Only existed users can be removed from database
    ///
    /// @return true if transaction is successfull or user is unique in database
    function removeUser(address user) external returns (bool);


    /// @dev Remove many users from database
    /// @custom:accessibility DEFAULT_ADMIN_ROLE
    /// @custom:requires user to be existed in database otherwise it will revert with
    /// error UserDoesNotExistsError(address user)
    ///
    /// NOTE: it's highly access function callable only via DEFAULT_ADMIN_ROLE
    /// Only existed users can be removed from database
    ///
    /// @return true if transaction is successfull or user is unique in database
    function removeUsersBatch(address[] memory users) external returns (bool);


    /// @dev Adds the user to the blacklist, thereby blocking and severely 
    /// restricting the user from calling most functions
    /// @custom:accessibility OPERATOR_ROLE
    ///
    /// NOTE: it's highly access function callable only via OPERATOR_ROLE
    ///
    /// @return true if user has never been added in blacklist before
    function addUserInBlacklist(address user) external returns (bool);


    /// @dev Removes user from the blacklist
    /// @custom:accessibility OPERATOR_ROLE
    ///
    /// NOTE: it's highly access function callable only via OPERATOR_ROLE
    ///
    /// @return true if user ever been added in blacklist before
    function removeUserFromBlacklist(address user) external returns (bool);

    //************************* startregion: SEND FUNCTIONS  *************************//
}