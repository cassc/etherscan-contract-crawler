// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IConsent.sol";
import "../access/KeyringAccessControl.sol";

contract Consent is IConsent, KeyringAccessControl {

    uint256 private constant MINIMUM_MAX_CONSENT_PERIOD = 1 hours;
    uint256 public immutable override maximumConsentPeriod;

    /**
     * @dev Mapping of Traders to their associated consent deadlines.
     */
    mapping(address => uint256) public override userConsentDeadlines;

    /**
     * @param trustedForwarder The address of a trustedForwarder contract.
     * @param maximumConsentPeriod_ The upper limit for user consent deadlines. 
     */
    constructor(
        address trustedForwarder, 
        uint256 maximumConsentPeriod_
    ) 
        KeyringAccessControl(trustedForwarder)
    {
        if (maximumConsentPeriod_ < MINIMUM_MAX_CONSENT_PERIOD)
            revert Unacceptable({
                reason: "The maximum consent period must be at least 1 hour"
            });

        maximumConsentPeriod = maximumConsentPeriod_;
    }

    /**
     * @notice A user may grant consent to service mitigation measures. 
     * @dev The deadline must be no further in the future than the maximumConsentDeadline.
     * @param revocationDeadline The consent will automatically expire at the deadline. 
     */
    function grantDegradedServiceConsent(uint256 revocationDeadline) external override {
        if(revocationDeadline < block.timestamp)
            revert Unacceptable({
                reason: "revocation deadline cannot be in the past"
            });
        if(revocationDeadline > block.timestamp + maximumConsentPeriod)
            revert Unacceptable({
                reason: "revocation deadline is too far in the future"
            });
        userConsentDeadlines[_msgSender()] = revocationDeadline;
        emit GrantDegradedServiceConsent(_msgSender(), revocationDeadline);
    }

    /**
     * @notice A user may revoke their consent to mitigation measures. 
     */
    function revokeMitigationConsent() external override {
        userConsentDeadlines[_msgSender()] = 0;
        emit RevokeDegradedServiceConsent(_msgSender());
    }

    /**
     * @param user The user to inspect. 
     * @return doesIndeed True if the user's consent deadline is in the future.
     */
    function userConsentsToMitigation(address user) public view override returns (bool doesIndeed) {
        doesIndeed = userConsentDeadlines[user] >= block.timestamp;
    }

}