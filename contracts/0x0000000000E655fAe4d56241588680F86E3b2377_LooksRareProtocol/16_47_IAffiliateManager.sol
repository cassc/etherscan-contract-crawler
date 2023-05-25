// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IAffiliateManager
 * @author LooksRare protocol team (👀,💎)
 */
interface IAffiliateManager {
    /**
     * @notice It is emitted when there is an update of affliate controller.
     * @param affiliateController Address of the new affiliate controller
     */
    event NewAffiliateController(address affiliateController);

    /**
     * @notice It is emitted if the affiliate program is activated or deactivated.
     * @param isActive Whether the affiliate program is active after the update
     */
    event NewAffiliateProgramStatus(bool isActive);

    /**
     * @notice It is emitted if there is a new affiliate and its associated rate (in basis point).
     * @param affiliate Address of the affiliate
     * @param rate Affiliate rate (in basis point)
     */
    event NewAffiliateRate(address affiliate, uint256 rate);

    /**
     * @notice It is returned if the function is called by another address than the affiliate controller.
     */
    error NotAffiliateController();

    /**
     * @notice It is returned if the affiliate controller is trying to set an affiliate rate higher than 10,000.
     */
    error PercentageTooHigh();
}