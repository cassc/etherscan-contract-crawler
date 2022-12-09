// contracts/interfaces/IDepositManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDepositManager {
    function LOCK_CONTRACT_ROLE() external view returns (bytes32);

    /**
     * @notice Get all the properties from an ID-NFT that the DM manage.
     * @dev Only will get the data that the Deposit Manager have stored
     * @param id NFT ID to get the properties
     * @return beneficiary or owner of the ID-NFT 
     * @return additionTime the Timestamp of when the beneficiary was added
     * @return initial amount that was locked on this ID-NFT
     * @return claimed amount so far 
     */
    function getProperties(uint id) external view returns(address, uint, uint, uint);

    /**
     * @notice Add a new deposits and save the data
     * @dev If is the first call, the contract asume that Manager want to create the merkle tree. The contract will hash with keccak256 the data
     * @param data ABI-encoded data of beneficiaries (arrays of addresses and amounts)
     * @param totalAmount Total amount of tokens to be locked for additional beneficiaries
     */
    function addDeposits(bytes calldata data, uint256 totalAmount) external returns(uint256);

    /**
     * @notice Remove an existing deposit and delete the data
     * @dev Manager benefiary onyl can remove Beneficiaries/ID that are already minted
     * @param id beneficiaries ID
     */
    function removeDeposits(uint id) external;

    /**
     * @notice Split a deposit
     * @dev Split a deposit with IDs provided by the Lock Contract
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     */
    function split(uint originId, uint lockedPart, uint[] memory splitParts, address[] memory addresses) external returns(uint[] memory);

    /**
     * @notice Update the claimed amount of an NFT ID
     * @param id NFT ID to be update
     * @param amountToClaim The amount to claim and update
     */
    function updateClaimedAmount(uint id, uint amountToClaim) external;

    /**
     * @notice Transfer an ID to a new beneficiary
     * @param to New beneficiary address that receives the NFT
     * @param id NFT ID to be transfer
     */
    function transfer(address to, uint id) external;

    /**
     * @notice Verifying the onwership of a beneficiary for an ID
     * @dev data param will be empty. If this function is called, the ID just doesn't exist
     * @param beneficiary The beneficiary/caller
     * @param data Empty OR initial amount and array of hashes of merkle tree leafs
     */
    function verifyOwnership(address beneficiary, bytes calldata data) external returns(bool, uint);
}