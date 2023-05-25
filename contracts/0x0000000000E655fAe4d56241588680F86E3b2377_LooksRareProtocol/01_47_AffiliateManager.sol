// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

// Interfaces
import {IAffiliateManager} from "./interfaces/IAffiliateManager.sol";

// Constants
import {ONE_HUNDRED_PERCENT_IN_BP} from "./constants/NumericConstants.sol";

/**
 * @title AffiliateManager
 * @notice This contract handles the management of affiliates for the LooksRare protocol.
 * @author LooksRare protocol team (👀,💎)
 */
contract AffiliateManager is IAffiliateManager, OwnableTwoSteps {
    /**
     * @notice Whether the affiliate program is active.
     */
    bool public isAffiliateProgramActive;

    /**
     * @notice Address of the affiliate controller.
     */
    address public affiliateController;

    /**
     * @notice It tracks the affiliate rate (in basis point) for a given affiliate address.
     *         The basis point represents how much of the protocol fee will be shared to the affiliate.
     */
    mapping(address => uint256) public affiliateRates;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @notice This function allows the affiliate controller to update the affiliate rate (in basis point).
     * @param affiliate Affiliate address
     * @param bp Rate (in basis point) to collect (e.g. 100 = 1%) per referred transaction
     */
    function updateAffiliateRate(address affiliate, uint256 bp) external {
        if (msg.sender != affiliateController) {
            revert NotAffiliateController();
        }

        if (bp > ONE_HUNDRED_PERCENT_IN_BP) {
            revert PercentageTooHigh();
        }

        affiliateRates[affiliate] = bp;
        emit NewAffiliateRate(affiliate, bp);
    }

    /**
     * @notice This function allows the owner to update the affiliate controller address.
     * @param newAffiliateController New affiliate controller address
     * @dev Only callable by owner.
     */
    function updateAffiliateController(address newAffiliateController) external onlyOwner {
        affiliateController = newAffiliateController;
        emit NewAffiliateController(newAffiliateController);
    }

    /**
     * @notice This function allows the owner to update the affiliate program status.
     * @param isActive Whether the affiliate program is active
     * @dev Only callable by owner.
     */
    function updateAffiliateProgramStatus(bool isActive) external onlyOwner {
        isAffiliateProgramActive = isActive;
        emit NewAffiliateProgramStatus(isActive);
    }
}