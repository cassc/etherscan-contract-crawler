// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;


/**
 * @title IMarketplace
 * @author aarora
 * @notice IMarketplace contains all external function interfaces and events
 */
interface IMarketplace {
    /**
    * @dev Emit an event whenever a listing is sold and royalties are transferred out.
    *
    * @param tokenId   The ID of the token for which the royalties were sent.
    * @param collector Address of the royalty collector
    * @param share     Share of the royalties sent out.
    * @param amount    Amount in Wei sent out.
    **/
    event TransferToRoyaltiesCollector(uint256 indexed tokenId, address indexed collector, uint256 share, uint256 amount);

    /**
    * @dev Emit an event whenever a listing is sold and funds are transferred to the seller.
    *
    * @param listingId The ID of the listing for which the funds were transferred to the seller.
    * @param collector Address of the seller
    * @param amount    Amount in Wei sent out.
    **/
    event TransferToPreviousOwner(uint256 indexed listingId, address indexed collector, uint256 indexed amount);

    /**
    * @dev Emit an event whenever a listing is sold.
    *
    * @param listingId The ID of the listing for which the funds were transferred to the seller.
    * @param buyer     Address of the buyer
    **/
    event Swap(uint256 indexed listingId, address indexed buyer);

    /**
     * @notice Validate a listing by performing the following checks:
     *         - The owner of the tokens in the listing should match the listing owner
     *         - The listing should have isListed set to true
     *         - The listing should have validUntil greater than the block timestamp. Otherwise the listing has expired.
     *         - The owner of listing should have provided approval to contract address on BlockBarBTL contract
     *
     * @param  listingId ID of the listing to validate.
     *
     * @return isValid Returns whether the listing can be purchase or not.
     */
    function validate(uint256 listingId) external view returns (bool isValid);

    /**
     * @notice Swap function is used to purchase a valid listing. A valid listing equates to the following being true:
     *                 - The owner of the tokens in the listing should match the listing owner
     *                 - The listing should have isListed set to true
     *                 - The listing should have validUntil greater than the block timestamp.
     *                   Otherwise the listing has expired.
     *                 - The owner of listing should have provided approval to contract address on BlockBarBTL contract
     *                 - The buyer should send exact amount of funds (as the listing amount) if the listing currency
     *                   is in ETH.
     *                 - The buyer should send within the threshold of slippage if the listing is in USD
     *          If all of the above are true, the swap function will send out royalties and
     *          transfer remainder to the previous owner before transferring the tokens from the seller to the buyer.
     *          Once all of the above is done, the function will increment the total sales counter.
     *
     * @param  listingId ID of the listing for sale.
     */
    function swap(uint256 listingId) external payable;

    /**
    * @notice Drain function used for dust collection. Any remainder funds in the wallet can be drained by the admin.
    */
    function drain() external;

    /**
    * @notice Get number of sales on this contract
    *
    * @return numberOfSales Number of sales generated
    */
    function getSales() external view returns (uint256 numberOfSales);
}