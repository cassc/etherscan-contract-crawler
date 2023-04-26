// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IRiskpool.sol";
import "Component.sol";

import "IBundle.sol";
import "IPolicy.sol";
import "IInstanceService.sol";
import "IRiskpoolService.sol";

import "IERC721.sol";

abstract contract Riskpool is 
    IRiskpool, 
    Component 
{    
    // used for representation of collateralization
    // collateralization between 0 and 1 (1=100%) 
    // value might be larger when overcollateralization
    uint256 public constant FULL_COLLATERALIZATION_LEVEL = 10**18;
    string public constant DEFAULT_FILTER_DATA_STRUCTURE = "";

    IInstanceService internal _instanceService; 
    IRiskpoolService internal _riskpoolService;
    IERC721 internal _bundleToken;
    
    // keep track of bundles associated with this riskpool
    uint256 [] internal _bundleIds;

    address private _wallet;
    address private _erc20Token;
    uint256 private _collateralization;
    uint256 private _sumOfSumInsuredCap;
    uint256 private _maxNumberOfActiveBundles;

    modifier onlyPool {
        require(
            _msgSender() == _getContractAddress("Pool"),
            "ERROR:RPL-001:ACCESS_DENIED"
        );
        _;
    }

    modifier onlyBundleOwner(uint256 bundleId) {
        IBundle.Bundle memory bundle = _instanceService.getBundle(bundleId);
        address bundleOwner = _bundleToken.ownerOf(bundle.tokenId);

        require(
            _msgSender() == bundleOwner,
            "ERROR:BUC-001:NOT_BUNDLE_OWNER"
        );
        _;
    }

    constructor(
        bytes32 name,
        uint256 collateralization,
        uint256 sumOfSumInsuredCap,
        address erc20Token,
        address wallet,
        address registry
    )
        Component(name, ComponentType.Riskpool, registry)
    { 
        _collateralization = collateralization;

        require(sumOfSumInsuredCap != 0, "ERROR:RPL-002:SUM_OF_SUM_INSURED_CAP_ZERO");
        _sumOfSumInsuredCap = sumOfSumInsuredCap;

        require(erc20Token != address(0), "ERROR:RPL-003:ERC20_ADDRESS_ZERO");
        _erc20Token = erc20Token;

        require(wallet != address(0), "ERROR:RPL-004:WALLET_ADDRESS_ZERO");
        _wallet = wallet;

        _instanceService = IInstanceService(_getContractAddress("InstanceService")); 
        _riskpoolService = IRiskpoolService(_getContractAddress("RiskpoolService"));
        _bundleToken = _instanceService.getBundleToken();
    }

    function _afterPropose() internal override virtual {
        _riskpoolService.registerRiskpool(
            _wallet,
            _erc20Token, 
            _collateralization,
            _sumOfSumInsuredCap
        );
    }

    function createBundle(bytes memory filter, uint256 initialAmount) 
        public virtual override
        returns(uint256 bundleId)
    {
        address bundleOwner = _msgSender();
        bundleId = _riskpoolService.createBundle(bundleOwner, filter, initialAmount);
        _bundleIds.push(bundleId);

        emit LogRiskpoolBundleCreated(bundleId, initialAmount);
    }

    function fundBundle(uint256 bundleId, uint256 amount) 
        external override
        onlyBundleOwner(bundleId)
        returns(uint256 netAmount)
    {
        netAmount = _riskpoolService.fundBundle(bundleId, amount);
    }

    function defundBundle(uint256 bundleId, uint256 amount)
        external override
        onlyBundleOwner(bundleId)
        returns(uint256 netAmount)
    {
        netAmount = _riskpoolService.defundBundle(bundleId, amount);
    }

    function lockBundle(uint256 bundleId)
        external override
        onlyBundleOwner(bundleId)
    {
        _riskpoolService.lockBundle(bundleId);
    }

    function unlockBundle(uint256 bundleId)
        external override
        onlyBundleOwner(bundleId)
    {
        _riskpoolService.unlockBundle(bundleId);
    }

    function closeBundle(uint256 bundleId)
        external override
        onlyBundleOwner(bundleId)
    {
        _riskpoolService.closeBundle(bundleId);
    }

    function burnBundle(uint256 bundleId)
        external override
        onlyBundleOwner(bundleId)
    {
        _riskpoolService.burnBundle(bundleId);
    }

    function collateralizePolicy(bytes32 processId, uint256 collateralAmount) 
        external override
        onlyPool
        returns(bool success) 
    {
        success = _lockCollateral(processId, collateralAmount);
        emit LogRiskpoolCollateralLocked(processId, collateralAmount, success);
    }

    function processPolicyPayout(bytes32 processId, uint256 amount)
        external override
        onlyPool
    {
        _processPayout(processId, amount);
        emit LogRiskpoolPayoutProcessed(processId, amount);
    }

    function processPolicyPremium(bytes32 processId, uint256 amount)
        external override
        onlyPool
    {
        _processPremium(processId, amount);
        emit LogRiskpoolPremiumProcessed(processId, amount);
    }

    function releasePolicy(bytes32 processId) 
        external override
        onlyPool
    {
        uint256 collateralAmount = _releaseCollateral(processId);
        emit LogRiskpoolCollateralReleased(processId, collateralAmount);
    }

    function setMaximumNumberOfActiveBundles(uint256 maximumNumberOfActiveBundles)
        external override
        onlyOwner
    {
        uint256 riskpoolId = getId();
        _riskpoolService.setMaximumNumberOfActiveBundles(riskpoolId, maximumNumberOfActiveBundles);
    }

    function getMaximumNumberOfActiveBundles()
        public view override
        returns(uint256 maximumNumberOfActiveBundles)
    {
        uint256 riskpoolId = getId();
        return _instanceService.getMaximumNumberOfActiveBundles(riskpoolId);
    }

    function getWallet() public view override returns(address) {
        return _wallet;
    }

    function getErc20Token() public view override returns(address) {
        return _erc20Token;
    }

    function getSumOfSumInsuredCap() public view override returns (uint256) {
        return _sumOfSumInsuredCap;
    }

    function getFullCollateralizationLevel() public pure override returns (uint256) {
        return FULL_COLLATERALIZATION_LEVEL;
    }

    function getCollateralizationLevel() public view override returns (uint256) {
        return _collateralization;
    }

    function bundles() public override view returns(uint256) {
        return _bundleIds.length;
    }

    function getBundle(uint256 idx) public override view returns(IBundle.Bundle memory) {
        require(idx < _bundleIds.length, "ERROR:RPL-006:BUNDLE_INDEX_TOO_LARGE");

        uint256 bundleIdx = _bundleIds[idx];
        return _instanceService.getBundle(bundleIdx);
    }

    function activeBundles() public override view returns(uint256) {
        uint256 riskpoolId = getId();
        return _instanceService.activeBundles(riskpoolId);
    }

    function getActiveBundleId(uint256 idx) public override view returns(uint256 bundleId) {
        uint256 riskpoolId = getId();
        require(idx < _instanceService.activeBundles(riskpoolId), "ERROR:RPL-007:ACTIVE_BUNDLE_INDEX_TOO_LARGE");

        return _instanceService.getActiveBundleId(riskpoolId, idx);
    }

    function getFilterDataStructure() external override pure returns(string memory) {
        return DEFAULT_FILTER_DATA_STRUCTURE;
    }

    function getCapital() public override view returns(uint256) {
        uint256 riskpoolId = getId();
        return _instanceService.getCapital(riskpoolId);
    }

    function getTotalValueLocked() public override view returns(uint256) {
        uint256 riskpoolId = getId();
        return _instanceService.getTotalValueLocked(riskpoolId);
    }

    function getCapacity() public override view returns(uint256) {
        uint256 riskpoolId = getId();
        return _instanceService.getCapacity(riskpoolId);
    }

    function getBalance() public override view returns(uint256) {
        uint256 riskpoolId = getId();
        return _instanceService.getBalance(riskpoolId);
    }

    function bundleMatchesApplication(
        IBundle.Bundle memory bundle, 
        IPolicy.Application memory application
    ) public override view virtual returns(bool isMatching);

    function _afterArchive() internal view override { 
        uint256 riskpoolId = getId();
        require(
            _instanceService.unburntBundles(riskpoolId) == 0, 
            "ERROR:RPL-010:RISKPOOL_HAS_UNBURNT_BUNDLES"
            );
    }

    function _lockCollateral(bytes32 processId, uint256 collateralAmount) internal virtual returns(bool success);
    function _processPremium(bytes32 processId, uint256 amount) internal virtual;
    function _processPayout(bytes32 processId, uint256 amount) internal virtual;
    function _releaseCollateral(bytes32 processId) internal virtual returns(uint256 collateralAmount);

}