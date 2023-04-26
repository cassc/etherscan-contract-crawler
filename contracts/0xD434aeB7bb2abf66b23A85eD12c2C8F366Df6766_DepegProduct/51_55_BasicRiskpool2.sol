// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "Riskpool2.sol";
import "IBundle.sol";
import "IPolicy.sol";

// basic riskpool always collateralizes one application using exactly one bundle
abstract contract BasicRiskpool2 is Riskpool2 {

    event LogBasicRiskpoolCapitalCheck(uint256 activeBundles, uint256 policies);
    event LogBasicRiskpoolCapitalization(uint256 activeBundles, uint256 capital, uint256 lockedCapital, uint256 collateralAmount, bool capacityIsAvailable);
    event LogBasicRiskpoolCandidateBundleAmountCheck(uint256 index, uint256 bundleId, uint256 maxAmount, uint256 collateralAmount);

    // remember bundleId for each processId
    // approach only works for basic risk pool where a
    // policy is collateralized by exactly one bundle
    mapping(bytes32 /* processId */ => uint256 /** bundleId */) internal _collateralizedBy;
    uint32 private _policiesCounter = 0;

    // will hold a sorted active bundle id array
    uint256[] private _activeBundleIds;

    // informational counter of active policies per bundle
    mapping(uint256 /* bundleId */ => uint256 /* activePolicyCount */) private _activePoliciesForBundle;

    constructor(
        bytes32 name,
        uint256 collateralization,
        uint256 sumOfSumInsuredCap,
        address erc20Token,
        address wallet,
        address registry
    )
        Riskpool2(name, collateralization, sumOfSumInsuredCap, erc20Token, wallet, registry)
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
        require(_activeBundleIds.length > 0, "ERROR:BRP-001:NO_ACTIVE_BUNDLES");

        uint256 capital = getCapital();
        uint256 lockedCapital = getTotalValueLocked();
        bool capacityIsAvailable = capital > lockedCapital + collateralAmount;

        emit LogBasicRiskpoolCapitalization(
            _activeBundleIds.length,
            capital,
            lockedCapital, 
            collateralAmount,
            capacityIsAvailable);

        // ensure there is a chance to find the collateral
        if(!capacityIsAvailable) {
            return false;
        }

        // set default outcome
        success = false;

        IPolicy.Application memory application = _instanceService.getApplication(processId);
        
        // basic riskpool implementation: policy coverage by single bundle only/
        // active bundle arrays with the most attractive bundle at the first place
        for (uint256 i = 0; i < _activeBundleIds.length && !success; i++) {
            uint256 bundleId = _activeBundleIds[i];
            // uint256 bundleId = getActiveBundleId(bundleIdx);
            IBundle.Bundle memory bundle = _instanceService.getBundle(bundleId);
            bool isMatching = bundleMatchesApplication2(bundle, application);
            emit LogRiskpoolBundleMatchesPolicy(bundleId, isMatching);

            if (isMatching) {
                uint256 maxAmount = bundle.capital - bundle.lockedCapital;
                emit LogBasicRiskpoolCandidateBundleAmountCheck(i, bundleId, maxAmount, collateralAmount);

                if (maxAmount >= collateralAmount) {
                    _riskpoolService.collateralizePolicy(bundleId, processId, collateralAmount);
                    _collateralizedBy[processId] = bundleId;
                    success = true;
                    _policiesCounter++;

                    // update active policies counter
                    _activePoliciesForBundle[bundleId]++;
                }
            }
        }
    }

    // hack
    function bundleMatchesApplication2(
        IBundle.Bundle memory bundle, 
        IPolicy.Application memory application
    ) 
        public virtual returns(bool isMatching);

    // manage sorted list of active bundle ids
    function _afterCreateBundle(uint256 bundleId, bytes memory filter, uint256 initialAmount) internal override virtual {
        _addBundleToActiveList(bundleId);
    }

    function _afterLockBundle(uint256 bundleId) internal override virtual {
        _removeBundleFromActiveList(bundleId);
    }
    function _afterUnlockBundle(uint256 bundleId) internal override virtual {
        _addBundleToActiveList(bundleId);
    }
    function _afterCloseBundle(uint256 bundleId) internal override virtual {
        _removeBundleFromActiveList(bundleId);
    }

    function _addBundleToActiveList(uint256 bundleId) internal {
        bool found = false;
        bool inserted = false;

        for (uint256 i = 0; !inserted && !found && i < _activeBundleIds.length; i++) {
            if (bundleId == _activeBundleIds[i]) {
                found = true;
            } 
            else if (isHigherPriorityBundle(bundleId, _activeBundleIds[i])) {
                inserted = true;
                _activeBundleIds.push(10**6);

                for (uint256 j = _activeBundleIds.length - 1; j > i; j--) {
                    _activeBundleIds[j] = _activeBundleIds[j-1];
                }

                // does not work for inserting at end of list ...
                _activeBundleIds[i] = bundleId;
            }
        }

        if (!found && !inserted) {
            _activeBundleIds.push(bundleId);
        }
    }

    // default implementation adds new bundle at the end of the active list
    function isHigherPriorityBundle(uint256 firstBundleId, uint256 secondBundleId) 
        public virtual 
        view 
        returns (bool firstBundleIsHigherPriority) 
    {
        firstBundleIsHigherPriority = false;
    }


    function _removeBundleFromActiveList(uint256 bundleId) internal {
        bool inList = false;
        for (uint256 i = 0; !inList && i < _activeBundleIds.length; i++) {
            inList = (bundleId == _activeBundleIds[i]);
            if (inList) {
                for (; i < _activeBundleIds.length - 1; i++) {
                    _activeBundleIds[i] = _activeBundleIds[i+1];
                }
                _activeBundleIds.pop();
            }
        }
    }

    function getActiveBundleIds() public view returns (uint256[] memory activeBundleIds) {
        return _activeBundleIds;
    }

    function getActivePolicies(uint256 bundleId) public view returns (uint256 activePolicies) {
        return _activePoliciesForBundle[bundleId];
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

        // update active policies counter
        _activePoliciesForBundle[bundleId]--;
    }
}