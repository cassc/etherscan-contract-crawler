// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "PolicyController.sol";
import "CoreController.sol";
import "BundleToken.sol";

import "IProduct.sol";
import "IBundle.sol";
import "PoolController.sol";


contract BundleController is 
    IBundle,
    CoreController
{

    PolicyController private _policy;
    BundleToken private _token; 

    mapping(uint256 /* bundleId */ => Bundle /* Bundle */) private _bundles;
    mapping(uint256 /* bundleId */ => uint256 /* activePolicyCount */) private _activePolicies;
    mapping(uint256 /* bundleId */ => mapping(bytes32 /* processId */ => uint256 /* lockedCapitalAmount */)) private _valueLockedPerPolicy;
    mapping(uint256 /* riskpoolId */ => uint256 /* numberOfUnburntBundles */) private _unburntBundlesForRiskpoolId;
    

    uint256 private _bundleCount;

    modifier onlyRiskpoolService() {
        require(
            _msgSender() == _getContractAddress("RiskpoolService"),
            "ERROR:BUC-001:NOT_RISKPOOL_SERVICE"
        );
        _;
    }

    modifier onlyFundableBundle(uint256 bundleId) {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-002:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.state != IBundle.BundleState.Burned 
            && bundle.state != IBundle.BundleState.Closed, "ERROR:BUC-003:BUNDLE_BURNED_OR_CLOSED"
        );
        _;
    }

    function _afterInitialize() internal override onlyInitializing {
        _policy = PolicyController(_getContractAddress("Policy"));
        _token = BundleToken(_getContractAddress("BundleToken"));
    }

    function create(address owner_, uint riskpoolId_, bytes calldata filter_, uint256 amount_) 
        external override
        onlyRiskpoolService
        returns(uint256 bundleId)
    {   
        // will start with bundleId 1.
        // this helps in maps where a bundleId equals a non-existing entry
        bundleId = _bundleCount + 1;
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt == 0, "ERROR:BUC-010:BUNDLE_ALREADY_EXISTS");

        // mint corresponding nft with bundleId as nft
        uint256 tokenId = _token.mint(bundleId, owner_);

        bundle.id = bundleId;
        bundle.tokenId = tokenId;
        bundle.riskpoolId = riskpoolId_;
        bundle.state = BundleState.Active;
        bundle.filter = filter_;
        bundle.capital = amount_;
        bundle.balance = amount_;
        bundle.createdAt = block.timestamp;
        bundle.updatedAt = block.timestamp;

        // update bundle count
        _bundleCount++;
        _unburntBundlesForRiskpoolId[riskpoolId_]++;

        emit LogBundleCreated(bundle.id, riskpoolId_, owner_, bundle.state, bundle.capital);
    }


    function fund(uint256 bundleId, uint256 amount)
        external override 
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-011:BUNDLE_DOES_NOT_EXIST");
        require(bundle.state != IBundle.BundleState.Closed, "ERROR:BUC-012:BUNDLE_CLOSED");

        bundle.capital += amount;
        bundle.balance += amount;
        bundle.updatedAt = block.timestamp;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundleCapitalProvided(bundleId, _msgSender(), amount, capacityAmount);
    }


    function defund(uint256 bundleId, uint256 amount) 
        external override 
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-013:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.capital >= bundle.lockedCapital + amount
            || (bundle.lockedCapital == 0 && bundle.balance >= amount),
            "ERROR:BUC-014:CAPACITY_OR_BALANCE_TOO_LOW"
        );

        if (bundle.capital >= amount) { bundle.capital -= amount; } 
        else                          { bundle.capital = 0; }

        bundle.balance -= amount;
        bundle.updatedAt = block.timestamp;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundleCapitalWithdrawn(bundleId, _msgSender(), amount, capacityAmount);
    }

    function lock(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        _changeState(bundleId, BundleState.Locked);
    }

    function unlock(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        _changeState(bundleId, BundleState.Active);
    }

    function close(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        require(_activePolicies[bundleId] == 0, "ERROR:BUC-015:BUNDLE_WITH_ACTIVE_POLICIES");
        _changeState(bundleId, BundleState.Closed);
    }

    function burn(uint256 bundleId)    
        external override
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.state == BundleState.Closed, "ERROR:BUC-016:BUNDLE_NOT_CLOSED");
        require(bundle.balance == 0, "ERROR:BUC-017:BUNDLE_HAS_BALANCE");

        // burn corresponding nft -> as a result bundle looses its owner
        _token.burn(bundleId);
        _unburntBundlesForRiskpoolId[bundle.riskpoolId] -= 1;

        _changeState(bundleId, BundleState.Burned);
    }

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 amount)
        external override 
        onlyRiskpoolService
    {
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.riskpoolId == _getPoolController().getRiskPoolForProduct(metadata.productId), "ERROR:BUC-019:BUNDLE_NOT_IN_RISKPOOL");
        require(bundle.createdAt > 0, "ERROR:BUC-020:BUNDLE_DOES_NOT_EXIST");
        require(bundle.state == IBundle.BundleState.Active, "ERROR:BUC-021:BUNDLE_NOT_ACTIVE");        
        require(bundle.capital >= bundle.lockedCapital + amount, "ERROR:BUC-022:CAPACITY_TOO_LOW");

        // might need to be added in a future relase
        require(_valueLockedPerPolicy[bundleId][processId] == 0, "ERROR:BUC-023:INCREMENTAL_COLLATERALIZATION_NOT_IMPLEMENTED");

        bundle.lockedCapital += amount;
        bundle.updatedAt = block.timestamp;

        _activePolicies[bundleId] += 1;
        _valueLockedPerPolicy[bundleId][processId] = amount;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundlePolicyCollateralized(bundleId, processId, amount, capacityAmount);
    }


    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount)
        external override
        onlyRiskpoolService
        onlyFundableBundle(bundleId)
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state != IPolicy.PolicyState.Closed,
            "ERROR:POL-030:POLICY_STATE_INVALID"
        );

        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-031:BUNDLE_DOES_NOT_EXIST");
        
        bundle.balance += amount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line
    }


    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) 
        external override 
        onlyRiskpoolService
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state != IPolicy.PolicyState.Closed,
            "ERROR:POL-040:POLICY_STATE_INVALID"
        );

        // check there are policies and there is sufficient locked capital for policy
        require(_activePolicies[bundleId] > 0, "ERROR:BUC-041:NO_ACTIVE_POLICIES_FOR_BUNDLE");
        require(_valueLockedPerPolicy[bundleId][processId] >= amount, "ERROR:BUC-042:COLLATERAL_INSUFFICIENT_FOR_POLICY");

        // make sure bundle exists and is not yet closed
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-043:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.state == IBundle.BundleState.Active
            || bundle.state == IBundle.BundleState.Locked, 
            "ERROR:BUC-044:BUNDLE_STATE_INVALID");
        require(bundle.capital >= amount, "ERROR:BUC-045:CAPITAL_TOO_LOW");
        require(bundle.lockedCapital >= amount, "ERROR:BUC-046:LOCKED_CAPITAL_TOO_LOW");
        require(bundle.balance >= amount, "ERROR:BUC-047:BALANCE_TOO_LOW");

        _valueLockedPerPolicy[bundleId][processId] -= amount;
        bundle.capital -= amount;
        bundle.lockedCapital -= amount;
        bundle.balance -= amount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line

        emit LogBundlePayoutProcessed(bundleId, processId, amount);
    }


    function releasePolicy(uint256 bundleId, bytes32 processId) 
        external override 
        onlyRiskpoolService
        returns(uint256 remainingCollateralAmount)
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state == IPolicy.PolicyState.Closed,
            "ERROR:POL-050:POLICY_STATE_INVALID"
        );

        // make sure bundle exists and is not yet closed
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-051:BUNDLE_DOES_NOT_EXIST");
        require(_activePolicies[bundleId] > 0, "ERROR:BUC-052:NO_ACTIVE_POLICIES_FOR_BUNDLE");

        uint256 lockedForPolicyAmount = _valueLockedPerPolicy[bundleId][processId];
        // this should never ever fail ...
        require(
            bundle.lockedCapital >= lockedForPolicyAmount,
            "PANIC:BUC-053:UNLOCK_CAPITAL_TOO_BIG"
        );

        // policy no longer relevant for bundle
        _activePolicies[bundleId] -= 1;
        delete _valueLockedPerPolicy[bundleId][processId];

        // update bundle capital
        bundle.lockedCapital -= lockedForPolicyAmount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundlePolicyReleased(bundleId, processId, lockedForPolicyAmount, capacityAmount);
    }

    function getOwner(uint256 bundleId) public view returns(address) { 
        uint256 tokenId = getBundle(bundleId).tokenId;
        return _token.ownerOf(tokenId); 
    }

    function getState(uint256 bundleId) public view returns(BundleState) {
        return getBundle(bundleId).state;   
    }

    function getFilter(uint256 bundleId) public view returns(bytes memory) {
        return getBundle(bundleId).filter;
    }   

    function getCapacity(uint256 bundleId) public view returns(uint256) {
        Bundle memory bundle = getBundle(bundleId);
        return bundle.capital - bundle.lockedCapital;
    }

    function getTotalValueLocked(uint256 bundleId) public view returns(uint256) {
        return getBundle(bundleId).lockedCapital;   
    }

    function getBalance(uint256 bundleId) public view returns(uint256) {
        return getBundle(bundleId).balance;   
    }

    function getToken() external view returns(BundleToken) {
        return _token;
    }

    function getBundle(uint256 bundleId) public view returns(Bundle memory) {
        Bundle memory bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-060:BUNDLE_DOES_NOT_EXIST");
        return bundle;
    }

    function bundles() public view returns(uint256) {
        return _bundleCount;
    }

    function unburntBundles(uint256 riskpoolId) external view returns(uint256) {
        return _unburntBundlesForRiskpoolId[riskpoolId];
    }

    function _getPoolController() internal view returns (PoolController _poolController) {
        _poolController = PoolController(_getContractAddress("Pool"));
    }

    function _changeState(uint256 bundleId, BundleState newState) internal {
        BundleState oldState = getState(bundleId);

        _checkStateTransition(oldState, newState);
        _setState(bundleId, newState);

        // log entry for successful state change
        emit LogBundleStateChanged(bundleId, oldState, newState);
    }

    function _setState(uint256 bundleId, BundleState newState) internal {
        _bundles[bundleId].state = newState;
        _bundles[bundleId].updatedAt = block.timestamp;
    }

    function _checkStateTransition(BundleState oldState, BundleState newState) 
        internal 
        pure 
    {
        if (oldState == BundleState.Active) {
            require(
                newState == BundleState.Locked || newState == BundleState.Closed, 
                "ERROR:BUC-070:ACTIVE_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Locked) {
            require(
                newState == BundleState.Active || newState == BundleState.Closed, 
                "ERROR:BUC-071:LOCKED_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Closed) {
            require(
                newState == BundleState.Burned, 
                "ERROR:BUC-072:CLOSED_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Burned) {
            revert("ERROR:BUC-073:BURNED_IS_FINAL_STATE");
        } else {
            revert("ERROR:BOC-074:INITIAL_STATE_NOT_HANDLED");
        }
    }
}