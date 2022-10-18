// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./PolicyStore.sol";

contract PolicyDecisionPoint is Ownable {
    PolicyStore public store;
    
    function configurePolicyStore(address _store) public onlyOwner {
        require(address(store) == address(0), "policy store is already configured!");
        store = PolicyStore(_store);
    }
    
    function evaluatePolicyForUser(SecurityTypes.Policy memory policy, address user) internal view returns (SecurityTypes.PolicyEffect) {
        for (uint i=0; i < policy.rules.length; i++) {
            if (!store.hasRole(user, policy.rules[i].role)) continue;
            SecurityTypes.PolicyEffect effect = policy.rules[i].effect;
            if (effect == SecurityTypes.PolicyEffect.GRANT || effect == SecurityTypes.PolicyEffect.DENY) return effect;
        }
        return SecurityTypes.PolicyEffect.UNKNOWN;
    }

    function isPolicyDefined(SecurityTypes.Policy memory policy) internal view returns (bool) {
        return policy.rules.length > 0;
    }
    
    function isAuthorized(bytes32 resource, bytes32 action, address user) public view returns (bool) {
        require(address(store) != address(0), "!store");
        SecurityTypes.Policy memory policy = store.fetchPolicy(resource, action);
        SecurityTypes.PolicyEffect effect = SecurityTypes.PolicyEffect.UNKNOWN;
        if (isPolicyDefined(policy)) {
            effect = evaluatePolicyForUser(policy, user);
        }
        if (effect == SecurityTypes.PolicyEffect.UNKNOWN) {
           policy = store.fetchPolicy(resource, SecurityTypes.ANY);
           if (isPolicyDefined(policy)) {
              effect = evaluatePolicyForUser(policy, user);
           }
        }
        if (effect == SecurityTypes.PolicyEffect.UNKNOWN) {
           policy = store.fetchPolicy(SecurityTypes.ANY, SecurityTypes.ANY);
           if (isPolicyDefined(policy)) {
              effect = evaluatePolicyForUser(policy, user);
           }
        }
        return (effect == SecurityTypes.PolicyEffect.GRANT);
    }
}