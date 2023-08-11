// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKeyringGuard.sol";
import "../interfaces/IRuleRegistry.sol";
import "../interfaces/IPolicyManager.sol";
import "../interfaces/IUserPolicies.sol";
import "../interfaces/IWalletCheck.sol";
import "../interfaces/IKeyringCredentials.sol";
import "../interfaces/IExemptionsManager.sol";
import "../consent/Consent.sol";

/**
 * @notice KeyringGuard implementation that uses immutable configuration parameters and presents 
 * a simplified modifier for use in derived contracts.
 */

abstract contract KeyringGuard is IKeyringGuard, Consent {
    using AddressSet for AddressSet.Set;

    uint8 private constant VERSION = 1;
    bytes32 private constant NULL_BYTES32 = bytes32(0);
    address internal constant NULL_ADDRESS = address(0);

    address public immutable keyringCredentials;
    address public immutable policyManager;
    address public immutable userPolicies;
    address public immutable exemptionsManager;
    uint32 public immutable admissionPolicyId;
    bytes32 public immutable universeRule;
    bytes32 public immutable emptyRule;

    /**
     * @dev Modifier checks ZK credentials and trader wallets for sender and receiver.
     */
    modifier checkKeyring(address from, address to) {
        if (!isAuthorized(from, to))
            revert Unacceptable({
                reason: "trader not authorized"
            });
        _;
    }

    /**
     * @param config Keyring contract addresses.
     * @param admissionPolicyId_ The unique identifier of a Policy against which user accounts will be compared.
     * @param maximumConsentPeriod_ The upper limit for user consent deadlines. 
     */
    constructor(
        KeyringConfig memory config,
        uint32 admissionPolicyId_,
        uint32 maximumConsentPeriod_
    ) Consent(config.trustedForwarder, maximumConsentPeriod_) {

        if (config.keyringCredentials == NULL_ADDRESS) revert Unacceptable({ reason: "credentials_ cannot be empty" });
        if (config.policyManager == NULL_ADDRESS) revert Unacceptable({ reason: "policyManager_ cannot be empty" });
        if (config.userPolicies == NULL_ADDRESS) revert Unacceptable({ reason: "userPolicies_ cannot be empty" });
        if (config.exemptionsManager == NULL_ADDRESS) 
            revert Unacceptable({ reason: "exemptionsManager_ cannot be empty"});
        if (!IPolicyManager(config.policyManager).isPolicy(admissionPolicyId_))
            revert Unacceptable({ reason: "admissionPolicyId not found" });
        if (IPolicyManager(config.policyManager).policyDisabled(admissionPolicyId_))
            revert Unacceptable({ reason: "admissionPolicy is disabled" });
           
        keyringCredentials = config.keyringCredentials;
        policyManager = config.policyManager;
        userPolicies = config.userPolicies;
        exemptionsManager = config.exemptionsManager;
        admissionPolicyId = admissionPolicyId_;
        (universeRule, emptyRule) = IRuleRegistry(IPolicyManager(config.policyManager).ruleRegistry()).genesis();

        if (universeRule == NULL_BYTES32)
            revert Unacceptable({ reason: "the universe rule is not defined in the PolicyManager's RuleRegistry" });
        if (emptyRule == NULL_BYTES32)
            revert Unacceptable({ reason: "the empty rule is not defined in the PolicyManager's RuleRegistry" });

        emit KeyringGuardConfigured(
            config.keyringCredentials,
            config.policyManager,
            config.userPolicies,
            admissionPolicyId_,
            universeRule,
            emptyRule
        );
    }

    /**
     * @notice Checks keyringCache for cached PII credential. 
     * @param observer The user who must consent to reliance on degraded services.
     * @param subject The subject to inspect.
     * @return passed True if cached credential is new enough, or if degraded service mitigation is possible
     * and the user has provided consent. 
     */
    function checkZKPIICache(address observer, address subject) public override returns (bool passed) {
        passed = IKeyringCredentials(keyringCredentials).checkCredential(
            observer,
            subject,
            admissionPolicyId
        );
    }

    /**
     * @notice Check the trader wallet against all wallet checks in the policy configuration. 
     * @param observer The user who must consent to reliance on degraded services.
     * @param subject The subject to inspect.
     * @return passed True if the wallet check is new enough, or if the degraded service mitigation is possible
     * and the user has provided consent. 
     */
    function checkTraderWallet(address observer, address subject) public override returns (bool passed) {
       
        address[] memory walletChecks = IPolicyManager(policyManager).policyWalletChecks(admissionPolicyId);

        for (uint256 i = 0; i < walletChecks.length; i++) {
            if (!IWalletCheck(walletChecks[i]).checkWallet(
                observer, 
                subject, 
                admissionPolicyId
            )) return false;
        }
        return true;
    }

    /**
     * @notice Check from and to addresses for compliance. 
     * @param from First trader wallet to inspect. 
     * @param to Second trader wallet to inspect. 
     * @return passed True, if both parties are compliant.
     * @dev Both parties are compliant, where compliant means:
     *  - they have a cached credential and if required, a wallet check 
     *  - they are an approved counterparty of the other party
     *  - they can rely on degraded service mitigation, and their counterparty consents
     *  - the policy excepts them from compliance checks, usually reserved for contracts
     */
    function isAuthorized(address from, address to) public override returns (bool passed) {
        
        bool fromIsApprovedByTo;
        bool toIsApprovedByFrom;
        bool fromExempt;
        bool toExempt;

        // A party is compliant if it is exempt. 

        fromExempt = IExemptionsManager(exemptionsManager).isPolicyExemption(
            admissionPolicyId,
            from
        );
        toExempt = IExemptionsManager(exemptionsManager).isPolicyExemption(
            admissionPolicyId,
            to
        );

        // If the policy is disabled and both parties consent, allow all trades.
        // If the policy is disabled and one or more parties does not consent, block trade. 
       
        if(IPolicyManager(policyManager).policyDisabled(admissionPolicyId)) {
            if (
                userConsentDeadlines[from] > block.timestamp || fromExempt &&
                userConsentDeadlines[to] > block.timestamp || toExempt) 
            {
                return true;
            } else {
                return false;
            }
        }

        // If both parties are exempt, allow the trade. 
        
        if(fromExempt && toExempt) return true;

        // A party is compliant if the counterparty approves interactions with them.

        bool policyAllowApprovedCounterparties = 
            IPolicyManager(policyManager).policyAllowApprovedCounterparties(admissionPolicyId);

        if (policyAllowApprovedCounterparties) {
            fromIsApprovedByTo = IUserPolicies(userPolicies).isApproved(to, from);
            toIsApprovedByFrom = IUserPolicies(userPolicies).isApproved(from, to);
        }

        // Is not authorized if wallet check or cached credential does not pass.
        // Cache may rely on degraded service mitigation and user consent.

        if (!fromExempt && !fromIsApprovedByTo) {
            if (!checkTraderWallet(to, from)) return false;
            if (!checkZKPIICache(to, from)) return false;
        }

        if (!toExempt && !toIsApprovedByFrom) {
            if (!checkTraderWallet(from, to)) return false; 
            if (!checkZKPIICache(from, to)) return false;
        }

        // Trade is acceptable
        return true;
    }
}