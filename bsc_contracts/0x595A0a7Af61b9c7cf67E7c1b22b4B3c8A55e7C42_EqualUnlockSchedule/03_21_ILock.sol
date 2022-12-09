// contracts/interfaces/ILock.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IDepositManager.sol";
import "./IUnlockSchedule.sol";
import "./ISplitManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILock is IERC721Upgradeable{

    /// @notice The timestamp when the lock start
    function lockStartTime() external view returns (uint);
    
    /// @notice Lock policy about adding new beneficiaries
    function canAddBeneficiaries() external view returns (bool);

    /// @notice Lock policy about removing beneficiaries
    function canRemoveBeneficiaries() external view returns (bool);

    function GOVERNANCE_ROLE() external view returns (bytes32);
    function BENEFICIARY_MANAGER_ROLE() external view returns (bytes32);
    function DEPOSIT_MANAGER_ROLE() external view returns (bytes32);

    function schedule() external view returns (address);
    function depositManager() external view returns (address);
    function splitManager() external view returns (address);
    function tokenERC20() external view returns (address);

    /**
     * @notice Get all the information about a NFT with specific ID
     * @param id NFT ID of the NFT for which the information is required
     * @return Owner or beneficiary of the NFT
     * @return The actual balance of amount locked
     * @return The actual amount that the owner can claim
     * @return The time when the lock start
     * @return The time when the lock will end
     */
    function getInfoBySingleID(uint id) view external returns(address, uint, uint, uint, uint);

    /**
     * @notice Get all the information about a set of IDs
     * @param ids List of NFT IDs which the information is required
     * @return List of owners or beneficiaries
     * @return List of actual balance of amount locked
     * @return List of actual amount that is claimable
     */
    function getInfoByManyIDs(uint[] memory ids) view external returns(address[] memory, uint[] memory, uint[] memory);

    /**
     * @notice Add new beneficiaries to the Lock
     * @dev Contracts should have enought allowance to transfer the totalAmount
     * @param data ABI-encoded data of beneficiaries (arrays of addresses and amounts - specific to DepositManager)
     * @param totalAmount Total amount of tokens to be locked for additional beneficiaries
     */
    function addBeneficiaries(bytes calldata data, uint256 totalAmount) external;

    /**
     * @notice Remove existing beneficiaries from the Lock
     * @dev All the IDs inside of the array should exists
     * @param data ABI-encoded data of beneficiaries IDs (arrays of IDs - specific to DepositManager)
     */
    function removeBeneficiaries(bytes calldata data) external;

    /**
     * @notice Claim and mint a NFT from the MerkleTree
     * @param ownershipProof ABI-encoded data to verify in MerkleTree (specific to DepositManager with Merkle Tree)
     * @return The Minted NFT Id
     */
    function claimNFT(bytes calldata ownershipProof) external returns(uint);

    /**
     * @notice Claim unlocked/free tokens from a specified NFT ID
     * @param nftId NFT ID to be claimed
     */
    function claimUnlocked(uint256 nftId) external;

    /*
     * @notice DEPRECATED Claim unlocked/free tokens from a specified NFT ID
     * @dev This function is deprecated. Use claimNFT() and claimUnlocked() separately.
     * @param nftId NFT ID to be claimed
     * @param ownershipProof proof used to claim NFT
     */
    //function claimUnlocked(uint256 nftId, bytes calldata ownershipProof) external;


    /**
     * @notice Split a NFT
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     */
    function split(uint originId, uint[] memory splitParts, address[] memory addresses) external;

    /**
     * @notice Deposit Manager call and mint an amount (count) of NFTs with addresses owners
     * @dev This function can be called only for DepositManager address
     * @param count Amount of NFTs to be minted
     * @param addresses Array of addresses to be Owners of the new NFTs
     * @return Array list with the IDs of the new NFTs
     */
    function mintNFTs(uint256 count, address[] memory addresses) external returns(uint[] memory);

    function burnNFT(uint id) external;
}