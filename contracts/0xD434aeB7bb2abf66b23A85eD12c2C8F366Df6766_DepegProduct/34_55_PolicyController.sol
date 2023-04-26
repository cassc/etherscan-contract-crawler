// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "CoreController.sol";
import "ComponentController.sol";
import "IPolicy.sol";

contract PolicyController is 
    IPolicy, 
    CoreController
{
    // bytes32 public constant NAME = "PolicyController";

    // Metadata
    mapping(bytes32 /* processId */ => Metadata) public metadata;

    // Applications
    mapping(bytes32 /* processId */ => Application) public applications;

    // Policies
    mapping(bytes32 /* processId */ => Policy) public policies;

    // Claims
    mapping(bytes32 /* processId */ => mapping(uint256 /* claimId */ => Claim)) public claims;

    // Payouts
    mapping(bytes32 /* processId */ => mapping(uint256 /* payoutId */ => Payout)) public payouts;
    mapping(bytes32 /* processId */ => uint256) public payoutCount;

    // counter for assigned processIds, used to ensure unique processIds
    uint256 private _assigendProcessIds;

    ComponentController private _component;

    function _afterInitialize() internal override onlyInitializing {
        _component = ComponentController(_getContractAddress("Component"));
    }

    /* Metadata */
    function createPolicyFlow(
        address owner,
        uint256 productId,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
        returns(bytes32 processId)
    {
        require(owner != address(0), "ERROR:POL-001:INVALID_OWNER");

        require(_component.isProduct(productId), "ERROR:POL-002:INVALID_PRODUCT");
        require(_component.getComponentState(productId) == IComponent.ComponentState.Active, "ERROR:POL-003:PRODUCT_NOT_ACTIVE");
        
        processId = _generateNextProcessId();
        Metadata storage meta = metadata[processId];
        require(meta.createdAt == 0, "ERROR:POC-004:METADATA_ALREADY_EXISTS");

        meta.owner = owner;
        meta.productId = productId;
        meta.state = PolicyFlowState.Started;
        meta.data = data;
        meta.createdAt = block.timestamp; // solhint-disable-line
        meta.updatedAt = block.timestamp; // solhint-disable-line

        emit LogMetadataCreated(owner, processId, productId, PolicyFlowState.Started);
    }

    /* Application */
    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-010:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt == 0, "ERROR:POC-011:APPLICATION_ALREADY_EXISTS");

        require(premiumAmount > 0, "ERROR:POC-012:PREMIUM_AMOUNT_ZERO");
        require(sumInsuredAmount > premiumAmount, "ERROR:POC-013:SUM_INSURED_AMOUNT_TOO_SMALL");

        application.state = ApplicationState.Applied;
        application.premiumAmount = premiumAmount;
        application.sumInsuredAmount = sumInsuredAmount;
        application.data = data;
        application.createdAt = block.timestamp; // solhint-disable-line
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Active;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationCreated(processId, premiumAmount, sumInsuredAmount);
    }

    function collectPremium(bytes32 processId, uint256 amount) 
        external override
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-110:POLICY_DOES_NOT_EXIST");
        require(policy.premiumPaidAmount + amount <= policy.premiumExpectedAmount, "ERROR:POC-111:AMOUNT_TOO_BIG");

        policy.premiumPaidAmount += amount;
        policy.updatedAt = block.timestamp; // solhint-disable-line
    
        emit LogPremiumCollected(processId, amount);
    }
    
    function revokeApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-014:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-015:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-016:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Revoked;
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationRevoked(processId);
    }

    function underwriteApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-017:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-018:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Underwritten;
        application.updatedAt = block.timestamp; // solhint-disable-line

        emit LogApplicationUnderwritten(processId);
    }

    function declineApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-019:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-020:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-021:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Declined;
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationDeclined(processId);
    }

    /* Policy */
    function createPolicy(bytes32 processId) 
        external override 
        onlyPolicyFlow("Policy")
    {
        Application memory application = applications[processId];
        require(application.createdAt > 0 && application.state == ApplicationState.Underwritten, "ERROR:POC-022:APPLICATION_ACCESS_INVALID");

        Policy storage policy = policies[processId];
        require(policy.createdAt == 0, "ERROR:POC-023:POLICY_ALREADY_EXISTS");

        policy.state = PolicyState.Active;
        policy.premiumExpectedAmount = application.premiumAmount;
        policy.payoutMaxAmount = application.sumInsuredAmount;
        policy.createdAt = block.timestamp; // solhint-disable-line
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPolicyCreated(processId);
    }

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    )
        external override
        onlyPolicyFlow("Policy")
    {
        Application storage application = applications[processId];
        require(
            application.createdAt > 0 
            && application.state == ApplicationState.Underwritten, 
            "ERROR:POC-024:APPLICATION_ACCESS_INVALID");

        require(
            sumInsuredAmount <= application.sumInsuredAmount, 
            "ERROR:POC-026:APPLICATION_SUM_INSURED_INCREASE_INVALID");

        Policy storage policy = policies[processId];
        require(
            policy.createdAt > 0 
            && policy.state == IPolicy.PolicyState.Active, 
            "ERROR:POC-027:POLICY_ACCESS_INVALID");
        
        require(
            expectedPremiumAmount > 0 
            && expectedPremiumAmount >= policy.premiumPaidAmount
            && expectedPremiumAmount < sumInsuredAmount, 
            "ERROR:POC-025:APPLICATION_PREMIUM_INVALID");

        if (sumInsuredAmount != application.sumInsuredAmount) {
            emit LogApplicationSumInsuredAdjusted(processId, application.sumInsuredAmount, sumInsuredAmount);
            application.sumInsuredAmount = sumInsuredAmount;
            application.updatedAt = block.timestamp; // solhint-disable-line

            policy.payoutMaxAmount = sumInsuredAmount;
            policy.updatedAt = block.timestamp; // solhint-disable-line
        }

        if (expectedPremiumAmount != application.premiumAmount) {
            emit LogApplicationPremiumAdjusted(processId, application.premiumAmount, expectedPremiumAmount);
            application.premiumAmount = expectedPremiumAmount;
            application.updatedAt = block.timestamp; // solhint-disable-line

            emit LogPolicyPremiumAdjusted(processId, policy.premiumExpectedAmount, expectedPremiumAmount);
            policy.premiumExpectedAmount = expectedPremiumAmount;
            policy.updatedAt = block.timestamp; // solhint-disable-line
        }
    }

    function expirePolicy(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-028:POLICY_DOES_NOT_EXIST");
        require(policy.state == PolicyState.Active, "ERROR:POC-029:APPLICATION_STATE_INVALID");

        policy.state = PolicyState.Expired;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPolicyExpired(processId);
    }

    function closePolicy(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-030:METADATA_DOES_NOT_EXIST");

        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-031:POLICY_DOES_NOT_EXIST");
        require(policy.state == PolicyState.Expired, "ERROR:POC-032:POLICY_STATE_INVALID");
        require(policy.openClaimsCount == 0, "ERROR:POC-033:POLICY_HAS_OPEN_CLAIMS");

        policy.state = PolicyState.Closed;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogPolicyClosed(processId);
    }

    /* Claim */
    function createClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
        returns (uint256 claimId)
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-040:POLICY_DOES_NOT_EXIST");
        require(policy.state == IPolicy.PolicyState.Active, "ERROR:POC-041:POLICY_NOT_ACTIVE");
        // no validation of claimAmount > 0 here to explicitly allow claims with amount 0. This can be useful for parametric insurance 
        // to have proof that the claim calculation was executed without entitlement to payment.
        require(policy.payoutAmount + claimAmount <= policy.payoutMaxAmount, "ERROR:POC-042:CLAIM_AMOUNT_EXCEEDS_MAX_PAYOUT");

        claimId = policy.claimsCount;
        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt == 0, "ERROR:POC-043:CLAIM_ALREADY_EXISTS");

        claim.state = ClaimState.Applied;
        claim.claimAmount = claimAmount;
        claim.data = data;
        claim.createdAt = block.timestamp; // solhint-disable-line
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.claimsCount++;
        policy.openClaimsCount++;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimCreated(processId, claimId, claimAmount);
    }

    function confirmClaim(
        bytes32 processId,
        uint256 claimId,
        uint256 confirmedAmount
    ) 
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-050:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-051:POLICY_WITHOUT_OPEN_CLAIMS");
        // no validation of claimAmount > 0 here as is it possible to have claims with amount 0 (see createClaim()). 
        require(policy.payoutAmount + confirmedAmount <= policy.payoutMaxAmount, "ERROR:POC-052:PAYOUT_MAX_AMOUNT_EXCEEDED");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-053:CLAIM_DOES_NOT_EXIST");
        require(claim.state == ClaimState.Applied, "ERROR:POC-054:CLAIM_STATE_INVALID");

        claim.state = ClaimState.Confirmed;
        claim.claimAmount = confirmedAmount;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.payoutAmount += confirmedAmount;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimConfirmed(processId, claimId, confirmedAmount);
    }

    function declineClaim(bytes32 processId, uint256 claimId)
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-060:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-061:POLICY_WITHOUT_OPEN_CLAIMS");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-062:CLAIM_DOES_NOT_EXIST");
        require(claim.state == ClaimState.Applied, "ERROR:POC-063:CLAIM_STATE_INVALID");

        claim.state = ClaimState.Declined;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimDeclined(processId, claimId);
    }

    function closeClaim(bytes32 processId, uint256 claimId)
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-070:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-071:POLICY_WITHOUT_OPEN_CLAIMS");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-072:CLAIM_DOES_NOT_EXIST");
        require(
            claim.state == ClaimState.Confirmed 
            || claim.state == ClaimState.Declined, 
            "ERROR:POC-073:CLAIM_STATE_INVALID");

        require(
            (claim.state == ClaimState.Confirmed && claim.claimAmount == claim.paidAmount) 
            || (claim.state == ClaimState.Declined), 
            "ERROR:POC-074:CLAIM_WITH_UNPAID_PAYOUTS"
        );

        claim.state = ClaimState.Closed;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.openClaimsCount--;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimClosed(processId, claimId);
    }

    /* Payout */
    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    )
        external override 
        onlyPolicyFlow("Policy") 
        returns (uint256 payoutId)
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-080:POLICY_DOES_NOT_EXIST");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-081:CLAIM_DOES_NOT_EXIST");
        require(claim.state == IPolicy.ClaimState.Confirmed, "ERROR:POC-082:CLAIM_NOT_CONFIRMED");
        require(payoutAmount > 0, "ERROR:POC-083:PAYOUT_AMOUNT_ZERO_INVALID");
        require(
            claim.paidAmount + payoutAmount <= claim.claimAmount,
            "ERROR:POC-084:PAYOUT_AMOUNT_TOO_BIG"
        );

        payoutId = payoutCount[processId];
        Payout storage payout = payouts[processId][payoutId];
        require(payout.createdAt == 0, "ERROR:POC-085:PAYOUT_ALREADY_EXISTS");

        payout.claimId = claimId;
        payout.amount = payoutAmount;
        payout.data = data;
        payout.state = PayoutState.Expected;
        payout.createdAt = block.timestamp; // solhint-disable-line
        payout.updatedAt = block.timestamp; // solhint-disable-line

        payoutCount[processId]++;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPayoutCreated(processId, claimId, payoutId, payoutAmount);
    }

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    )
        external override 
        onlyPolicyFlow("Policy")
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-090:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-091:POLICY_WITHOUT_OPEN_CLAIMS");

        Payout storage payout = payouts[processId][payoutId];
        require(payout.createdAt > 0, "ERROR:POC-092:PAYOUT_DOES_NOT_EXIST");
        require(payout.state == PayoutState.Expected, "ERROR:POC-093:PAYOUT_ALREADY_PAIDOUT");

        payout.state = IPolicy.PayoutState.PaidOut;
        payout.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPayoutProcessed(processId, payoutId);

        Claim storage claim = claims[processId][payout.claimId];
        claim.paidAmount += payout.amount;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        // check if claim can be closed
        if (claim.claimAmount == claim.paidAmount) {
            claim.state = IPolicy.ClaimState.Closed;

            policy.openClaimsCount -= 1;
            policy.updatedAt = block.timestamp; // solhint-disable-line

            emit LogClaimClosed(processId, payout.claimId);
        }
    }

    function getMetadata(bytes32 processId)
        public
        view
        returns (IPolicy.Metadata memory _metadata)
    {
        _metadata = metadata[processId];
        require(_metadata.createdAt > 0,  "ERROR:POC-100:METADATA_DOES_NOT_EXIST");
    }

    function getApplication(bytes32 processId)
        public
        view
        returns (IPolicy.Application memory application)
    {
        application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-101:APPLICATION_DOES_NOT_EXIST");        
    }

    function getNumberOfClaims(bytes32 processId) external view returns(uint256 numberOfClaims) {
        numberOfClaims = getPolicy(processId).claimsCount;
    }
    
    function getNumberOfPayouts(bytes32 processId) external view returns(uint256 numberOfPayouts) {
        numberOfPayouts = payoutCount[processId];
    }

    function getPolicy(bytes32 processId)
        public
        view
        returns (IPolicy.Policy memory policy)
    {
        policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-102:POLICY_DOES_NOT_EXIST");        
    }

    function getClaim(bytes32 processId, uint256 claimId)
        public
        view
        returns (IPolicy.Claim memory claim)
    {
        claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-103:CLAIM_DOES_NOT_EXIST");        
    }

    function getPayout(bytes32 processId, uint256 payoutId)
        public
        view
        returns (IPolicy.Payout memory payout)
    {
        payout = payouts[processId][payoutId];
        require(payout.createdAt > 0, "ERROR:POC-104:PAYOUT_DOES_NOT_EXIST");        
    }

    function processIds() external view returns (uint256) {
        return _assigendProcessIds;
    }

    function _generateNextProcessId() private returns(bytes32 processId) {
        _assigendProcessIds++;

        processId = keccak256(
            abi.encodePacked(
                block.chainid, 
                address(_registry),
                _assigendProcessIds
            )
        );
    } 
}