// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IProduct.sol";
import "Component.sol";
import "IPolicy.sol";
import "IInstanceService.sol";
import "IProductService.sol";

abstract contract Product is
    IProduct, 
    Component 
{    
    address private _policyFlow; // policy flow contract to use for this procut
    address private _token; // erc20 token to use for this product
    uint256 private _riskpoolId; // id of riskpool responsible for this product

    IProductService internal _productService;
    IInstanceService internal _instanceService;

    modifier onlyPolicyHolder(bytes32 policyId) {
        address policyHolder = _instanceService.getMetadata(policyId).owner;
        require(
            _msgSender() == policyHolder, 
            "ERROR:PRD-001:POLICY_OR_HOLDER_INVALID"
        );
        _;
    }

    modifier onlyLicence {
        require(
             _msgSender() == _getContractAddress("Licence"),
            "ERROR:PRD-002:ACCESS_DENIED"
        );
        _;
    }

    modifier onlyOracle {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:PRD-003:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address token,
        bytes32 policyFlow,
        uint256 riskpoolId,
        address registry
    )
        Component(name, ComponentType.Product, registry)
    {
        _token = token;
        _riskpoolId = riskpoolId;

        // TODO add validation for policy flow
        _policyFlow = _getContractAddress(policyFlow);
        _productService = IProductService(_getContractAddress("ProductService"));
        _instanceService = IInstanceService(_getContractAddress("InstanceService"));

        emit LogProductCreated(address(this));
    }

    function getToken() public override view returns(address) {
        return _token;
    }

    function getPolicyFlow() public view override returns(address) {
        return _policyFlow;
    }

    function getRiskpoolId() public override view returns(uint256) {
        return _riskpoolId;
    }

    // default callback function implementations
    function _afterApprove() internal override { emit LogProductApproved(getId()); }

    function _afterPropose() internal override { emit LogProductProposed(getId()); }
    function _afterDecline() internal override { emit LogProductDeclined(getId()); }

    function _newApplication(
        address applicationOwner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes memory metaData, 
        bytes memory applicationData 
    )
        internal
        returns(bytes32 processId)
    {
        processId = _productService.newApplication(
            applicationOwner, 
            premiumAmount, 
            sumInsuredAmount, 
            metaData, 
            applicationData);
    }

    function _collectPremium(bytes32 processId) 
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        IPolicy.Policy memory policy = _getPolicy(processId);

        if (policy.premiumPaidAmount < policy.premiumExpectedAmount) {
            (success, feeAmount, netAmount) 
                = _collectPremium(
                    processId, 
                    policy.premiumExpectedAmount - policy.premiumPaidAmount
                );
        }
    }

    function _collectPremium(
        bytes32 processId,
        uint256 amount
    )
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        (success, feeAmount, netAmount) = _productService.collectPremium(processId, amount);
    }

    function _adjustPremiumSumInsured(
        bytes32 processId,
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) internal {
        _productService.adjustPremiumSumInsured(processId, expectedPremiumAmount, sumInsuredAmount);
    }

    function _revoke(bytes32 processId) internal {
        _productService.revoke(processId);
    }

    function _underwrite(bytes32 processId) internal returns(bool success) {
        success = _productService.underwrite(processId);
    }

    function _decline(bytes32 processId) internal {
        _productService.decline(processId);
    }

    function _expire(bytes32 processId) internal {
        _productService.expire(processId);
    }

    function _close(bytes32 processId) internal {
        _productService.close(processId);
    }

    function _newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes memory data
    ) 
        internal
        returns (uint256 claimId)
    {
        claimId = _productService.newClaim(
            processId, 
            claimAmount, 
            data);
    }

    function _confirmClaim(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount
    )
        internal
    {
        _productService.confirmClaim(
            processId, 
            claimId, 
            payoutAmount);
    }

    function _declineClaim(bytes32 processId, uint256 claimId) internal {
        _productService.declineClaim(processId, claimId);
    }

    function _closeClaim(bytes32 processId, uint256 claimId) internal {
        _productService.closeClaim(processId, claimId);
    }

    function _newPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 amount,
        bytes memory data
    )
        internal
        returns(uint256 payoutId)
    {
        payoutId = _productService.newPayout(processId, claimId, amount, data);
    }

    function _processPayout(
        bytes32 processId,
        uint256 payoutId
    )
        internal
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        )
    {
        (
            feeAmount,
            netPayoutAmount
        ) = _productService.processPayout(processId, payoutId);
    }

    function _request(
        bytes32 processId,
        bytes memory input,
        string memory callbackMethodName,
        uint256 responsibleOracleId
    )
        internal
        returns (uint256 requestId)
    {
        requestId = _productService.request(
            processId,
            input,
            callbackMethodName,
            address(this),
            responsibleOracleId
        );
    }

    function _cancelRequest(uint256 requestId)
        internal
    {
        _productService.cancelRequest(requestId);
    }

    function _getMetadata(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Metadata memory metadata) 
    {
        return _instanceService.getMetadata(processId);
    }

    function _getApplication(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Application memory application) 
    {
        return _instanceService.getApplication(processId);
    }

    function _getPolicy(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Policy memory policy) 
    {
        return _instanceService.getPolicy(processId);
    }

    function _getClaim(bytes32 processId, uint256 claimId) 
        internal 
        view 
        returns (IPolicy.Claim memory claim) 
    {
        return _instanceService.getClaim(processId, claimId);
    }

    function _getPayout(bytes32 processId, uint256 payoutId) 
        internal 
        view 
        returns (IPolicy.Payout memory payout) 
    {
        return _instanceService.getPayout(processId, payoutId);
    }

    function getApplicationDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }

    function getClaimDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }    
    function getPayoutDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }

    function riskPoolCapacityCallback(uint256 capacity) external override virtual { }
}