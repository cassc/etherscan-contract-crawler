// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGloryReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(
        address referrer,
        uint256 commission
    ) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);

    /**
     * @dev Get the referrer total commission.
     */
    function getReferrerTotalCommission(
        address referrer
    ) external view returns (uint256);
}