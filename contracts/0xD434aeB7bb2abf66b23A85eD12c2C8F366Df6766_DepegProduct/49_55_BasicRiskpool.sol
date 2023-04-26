// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "Riskpool.sol";
import "IBundle.sol";
import "IPolicy.sol";

// basic riskpool always collateralizes one application using exactly one bundle
abstract contract BasicRiskpool is Riskpool {

    event LogBasicRiskpoolBundlesAndPolicies(uint256 activeBundles, uint256 bundleId);
    event LogBasicRiskpoolCandidateBundleAmountCheck(uint256 index, uint256 bundleId, uint256 maxAmount, uint256 collateralAmount);

    // remember bundleId for each processId
    // approach only works for basic risk pool where a
    // policy is collateralized by exactly one bundle
    mapping(bytes32 /* processId */ => uint256 /** bundleId */) internal _collateralizedBy;
    uint32 private _policiesCounter = 0;

    constructor(
        bytes32 name,
        uint256 collateralization,
        uint256 sumOfSumInsuredCap,
        address erc20Token,
        address wallet,
        address registry
    )
        Riskpool(name, collateralization, sumOfSumInsuredCap, erc20Token, wallet, registry)
    { }

    

    // needs to remember which bundles helped to cover ther risk
    // simple (retail) approach: single policy covered by single bundle
    // first bundle with a match and sufficient capacity wins
    // Component <- Riskpool <- BasicRiskpool <- TestRiskpool
    // complex (wholesale) approach: single policy covered by many bundles
    // Component <- Riskpool <- AdvancedRiskpool <- TestRiskpool
    function _lockCollateral(bytes32 processId, uint256 collateralAmount) 
        internal override
        returns(bool success) 
    {
        uint256 activeBundles = activeBundles();
        uint256 capital = getCapital();
        uint256 lockedCapital = getTotalValueLocked();

        emit LogBasicRiskpoolBundlesAndPolicies(activeBundles, _policiesCounter);
        require(activeBundles > 0, "ERROR:BRP-001:NO_ACTIVE_BUNDLES");
        require(capital > lockedCapital, "ERROR:BRP-002:NO_FREE_CAPITAL");

        // ensure there is a chance to find the collateral
        if(capital >= lockedCapital + collateralAmount) {
            IPolicy.Application memory application = _instanceService.getApplication(processId);

            // initialize bundle idx with round robin based on active bundles
            uint idx = _policiesCounter % activeBundles;
            
            // basic riskpool implementation: policy coverage by single bundle only/
            // the initial bundle is selected via round robin based on the policies counter.
            // If a bundle does not match (application not matching or insufficient funds for collateral) the next one is tried. 
            // This is continued until all bundles have been tried once. If no bundle matches the policy is rejected.
            for (uint256 i = 0; i < activeBundles && !success; i++) {
                uint256 bundleId = getActiveBundleId(idx);
                IBundle.Bundle memory bundle = _instanceService.getBundle(bundleId);
                bool isMatching = bundleMatchesApplication(bundle, application);
                emit LogRiskpoolBundleMatchesPolicy(bundleId, isMatching);

                if (isMatching) {
                    uint256 maxAmount = bundle.capital - bundle.lockedCapital;
                    emit LogBasicRiskpoolCandidateBundleAmountCheck(idx, bundleId, maxAmount, collateralAmount);

                    if (maxAmount >= collateralAmount) {
                        _riskpoolService.collateralizePolicy(bundleId, processId, collateralAmount);
                        _collateralizedBy[processId] = bundleId;
                        success = true;
                        _policiesCounter++;
                    } else {
                        idx = (idx + 1) % activeBundles;
                    }
                }
            }
        }
    }

    function _processPayout(bytes32 processId, uint256 amount)
        internal override
    {
        uint256 bundleId = _collateralizedBy[processId];
        _riskpoolService.processPayout(bundleId, processId, amount);
    }

    function _processPremium(bytes32 processId, uint256 amount)
        internal override
    {
        uint256 bundleId = _collateralizedBy[processId];
        _riskpoolService.processPremium(bundleId, processId, amount);
    }

    function _releaseCollateral(bytes32 processId) 
        internal override
        returns(uint256 collateralAmount) 
    {        
        uint256 bundleId = _collateralizedBy[processId];
        collateralAmount = _riskpoolService.releasePolicy(bundleId, processId);
    }
}