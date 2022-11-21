//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/ApprovalsStruct.sol";

/**
 *  @title IAssetStore
 *  @dev Interface for IAssetStore to interact with AssetStore Contracts
 *
 */
interface IAssetStore {
    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] memory _tokenIds,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) external;

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId)
        external
        view
        returns (Approvals memory approval_);

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress)
        external
        view
        returns (Approvals[] memory approval_);

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid)
        external
        view
        returns (Approvals[] memory);

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid) external;

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     *
     */
    function claimAsset(string memory uid, uint256 approvalId_) external;

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory);

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string memory uid, uint256 approvalId) external;

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external;

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] calldata _contractAddress,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] calldata _backUpWallets,
        address[] calldata _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external;

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string memory uid) external;

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string memory _uid
    ) external;
}