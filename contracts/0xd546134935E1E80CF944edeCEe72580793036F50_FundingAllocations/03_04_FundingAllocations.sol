// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFundingAllocations.sol";

/**
 * @title FundingAllocations
 * @author ChangeDao
 * @dev Contract stores the wallet address for ChangeDAO along with the percentages sent to ChangeDAO from minting fees and royalties from token sales.
 */

contract FundingAllocations is IFundingAllocations, Ownable {
    /* ============== State Variables ============== */

    address payable public override changeDaoWallet;
    /// @notice Shares are stored as basis points (of 10000)
    uint256 public override changeDaoRoyalties = 2000;
    uint256 public override changeDaoFunding = 500;

    /* ============== Constructor ============== */

    /**
     * @notice Sets address for the ChangeDao wallet
     * @param _changeDaoWallet ChangeDao wallet address
     */
    constructor(address payable _changeDaoWallet) {
        changeDaoWallet = _changeDaoWallet;
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice Owner sets royalties share amount for ChangeDao wallet address
     * @dev Share amount over 10000 will cause payment splitter clones to revert. Share amount for ChangeDao should be less than 10000 to allow for recipients to receive shares
     * @param _royaltiesShares Royalties share amount for ChangeDao
     */
    function setChangeDaoRoyalties(uint256 _royaltiesShares)
        external
        override
        onlyOwner
    {
        require(_royaltiesShares <= 10000, "FA: Share amount cannot exceed 10000");
        changeDaoRoyalties = _royaltiesShares;
        emit SetRoyaltiesShares(_royaltiesShares);
    }

    /**
     * @notice Owner sets funding share amount for ChangeDao wallet address
     * @dev Share amount over 10000 will cause payment splitter clones to revert. Share amount for ChangeDao should be less than 10000 to allow for recipients to receive shares
     * @param _fundingShares Funding share amount for ChangeDao
     */
    function setChangeDaoFunding(uint256 _fundingShares)
        external
        override
        onlyOwner
    {
        require(_fundingShares <= 10000, "FA: Share amount cannot exceed 10000");
        changeDaoFunding = _fundingShares;
        emit SetFundingShares(_fundingShares);
    }

    /**
     * @notice Updates the address to which royalties and funding are sent
     * @param _changeDaoWallet Set address for the ChangeDao wallet
     */
    function setChangeDaoWallet(address payable _changeDaoWallet)
        external
        override
        onlyOwner
    {
        changeDaoWallet = _changeDaoWallet;
        emit NewWallet(_changeDaoWallet);
    }
}