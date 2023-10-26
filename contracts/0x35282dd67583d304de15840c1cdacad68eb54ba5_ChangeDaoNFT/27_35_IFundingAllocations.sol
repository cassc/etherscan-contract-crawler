// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IFundingAllocations
 * @author ChangeDao
 */

interface IFundingAllocations {
    /* ============== Events ============== */

    /**
     * @notice Emitted when owner sets a new address for ChangeDao's wallet
     */
    event NewWallet(address indexed changeDaoWallet);

    /**
     * @notice Emitted when owner sets new royalties share amount for ChangeDao
     */
    event SetRoyaltiesShares(uint256 indexed shareAmount);

    /**
     * @notice Emitted when owner sets new funding share amount for ChangeDao
     */
    event SetFundingShares(uint256 indexed shareAmount);

    /* ============== Getter Functions ============== */

    function changeDaoWallet() external view returns (address payable);

    function changeDaoRoyalties() external view returns (uint256);
    
    function changeDaoFunding() external view returns (uint256);

    /* ============== Setter Functions ============== */

    function setChangeDaoRoyalties(uint256 _royaltiesShares) external;

    function setChangeDaoFunding(uint256 _fundingShares) external;

    function setChangeDaoWallet(address payable _changeDaoWallet) external;
}