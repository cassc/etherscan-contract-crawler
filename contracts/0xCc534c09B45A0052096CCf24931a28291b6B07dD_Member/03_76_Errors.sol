//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the Webacy
 * @dev inspired by Aave's https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/helpers/Errors.sol
 * @dev Error messages prefix glossary:
 *  - ASF = AssetStoreFactory
 *  - MF = MembershipFactory
 *  - BL = Blacklist
 *  - WL = Whitelist
 *  - AS = AssetStore
 *  - CO = ChainlinkOperations
 *  - M = Member
 *  - MS = Membership
 *  - PD = ProtocolDirectory
 *  - RC = RelayerContract
 */
library Errors {
    // AssetStoreFactory Errors
    string public constant ASF_NO_MEMBERSHIP_CONTRACT = "1"; // "User does not have a membership contract deployed"
    string public constant ASF_HAS_AS = "2"; // "User has an AssetStore"

    // MembershipFactory Errors
    string public constant MF_HAS_MEMBERSHIP_CONTRACT = "3"; //  "User already has a membership contract"
    string public constant MF_INACTIVE_PLAN = "4"; //  "Membership plan is no longer active"
    string public constant MF_NEED_MORE_DOUGH = "5"; //  "Membership cost send is not sufficient"

    // Blacklist Errors
    string public constant BL_BLACKLISTED = "6"; //  "Address is blacklisted"

    // AssetStore Errors
    string public constant AS_NO_MEMBERSHIP = "7"; //  "AssetsStore: User does not have a membership"
    string public constant AS_USER_DNE = "8"; //  "User does not exist"
    string public constant AS_ONLY_RELAY = "9"; //  "Only relayer contract can call this"
    string public constant AS_ONLY_CHAINLINK_OPS = "10"; //  "Only chainlink operations contract can call this"
    string public constant AS_DIFF_LENGTHS = "11"; // "Lengths of parameters need to be equal"
    string public constant AS_ONLY_PRIMARY_WALLET = "12"; // "Only the primary wallet can approve to store assets"
    string public constant AS_INVALID_TOKEN_RANGE = "13"; // "tokenAmount can only range from 0-100 percentage"
    string public constant AS_ONLY_BENEFICIARY = "14"; // "Only the designated beneficiary can claim assets"
    string public constant AS_NO_APPROVALS = "15"; // "No Approvals found"
    string public constant AS_NOT_CHARITY = "16"; // "is not charity"
    string public constant AS_INVALID_APPROVAL = "17"; // "Approval should not be active and should not be claimed in order to make changes"
    string public constant AS_NEED_TOP = "18"; // "User does not have sufficient topUp Updates in order to store approvals"

    // Member Errors
    string public constant M_NOT_OWNER = "19"; // "Member UID does not own this wallet Address"
    string public constant M_NOT_HOLDER = "20"; // "The user does not own a token of the supporting NFT Collection"
    string public constant M_USER_DNE = "21"; // "No user exists"
    string public constant M_UID_DNE = "22"; // "No UID found"
    string public constant M_INVALID_BACKUP = "23"; // "BackUp Wallet specified is not the users backup Wallet"
    string public constant M_NOT_MEMBER = "24"; // "Member: User does not have a membership"
    string public constant M_EMPTY_UID = "25"; // "UID is empty"
    string public constant M_PRIM_WALLET = "26"; // "You cannot delete your primary wallet"
    string public constant M_ALREADY_PRIM = "27"; // "Current Wallet is already the primary Wallet"
    string public constant M_DIFF_LENGTHS = "28"; // "Lengths of parameters need to be equal"
    string public constant M_BACKUP_FIRST = "29"; // "User should backup assets prior to executing panic button"
    string public constant M_NEED_TOP = "30"; // "User does not have sufficient topUp Updates in order to store approvals"
    string public constant M_INVALID_ADDRESS = "31"; // "Membership Error: User should have its deployed Membership Address"
    string public constant M_USER_MUST_WALLET = "32"; //"User should have a primary wallet prior to adding a backup wallet"
    string public constant M_USER_EXISTS = "33"; // User with UID already exists

    // Membership Errors
    string public constant MS_NEED_MORE_DOUGH = "34"; // "User needs to send sufficient amount to topUp"
    string public constant MS_INACTIVE = "35"; // "Membership inactive"

    // RelayerContract Errors
    string public constant RC_UNAUTHORIZED = "36"; // "Only relayer can invoke this function"
}