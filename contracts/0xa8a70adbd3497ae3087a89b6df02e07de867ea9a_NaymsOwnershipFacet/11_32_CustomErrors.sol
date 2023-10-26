// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev The Nayms Diamond (proxy contract) owner (address) must be mutually exclusive with the system admin role.
error OwnerCannotBeSystemAdmin();

/// @dev Passing in a missing role when trying to assign a role.
error RoleIsMissing();

/// @dev Passing in a missing group when trying to assign a role to a group.
error AssignerGroupIsMissing();

/// @dev Role assigner (msg.sender) must be in the assigners group to unassign a role.
/// @param assigner Id of the role assigner, LibHelpers._getIdForAddress(msg sender)
/// @param assignee ObjectId that the role is being assigned to
/// @param context Context that the role is being assigned in
/// @param roleInContext Role that is being assigned
error AssignerCannotUnassignRole(bytes32 assigner, bytes32 assignee, bytes32 context, string roleInContext);

/// @notice Error message for when a sender is not authorized to perform an action with their assigned role in a given context of a group
/// @dev In the assertPrivilege modifier, this error message returns the context and the role in the context, not the user's role in the system context.
/// @param msgSenderId Id of the sender
/// @param context Context in which the sender is trying to perform an action
/// @param roleInContext Role of the sender in the context
/// @param group Group to check the sender's role in
error InvalidGroupPrivilege(bytes32 msgSenderId, bytes32 context, string roleInContext, string group);

/// @dev Passing in a missing address when trying to add a token address to the supported external token list.
error CannotAddNullSupportedExternalToken();

/// @dev Cannot add a ERC20 token to the supported external token list that has more than 18 decimal places.
error CannotSupportExternalTokenWithMoreThan18Decimals();

/// @dev Passing in a missing address when trying to assign a new token address as the new discount token.
error CannotAddNullDiscountToken();

/// @dev The entity does not exist when it should.
error EntityDoesNotExist(bytes32 objectId);

/// @dev Cannot create an entity that already exists.
error CreatingEntityThatAlreadyExists(bytes32 entityId);

/// @dev (non specific) the object is not enabled to be tokenized.
error ObjectCannotBeTokenized(bytes32 objectId);

/// @dev Passing in a missing symbol when trying to enable an object to be tokenized.
error MissingSymbolWhenEnablingTokenization(bytes32 objectId);

/// @dev Passing in 0 amount for deposits is not allowed.
error ExternalDepositAmountCannotBeZero();

/// @dev Passing in 0 amount for withdraws is not allowed.
error ExternalWithdrawAmountCannotBeZero();

/// @dev The receiver of the withdraw must haveGroupPriviledge with the roles entity admin, comptroller combined, or comptroller withdraw.
error ExternalWithdrawInvalidReceiver(address receiver);

/// @dev Cannot create a simple policy with policyId of 0
error PolicyIdCannotBeZero();

/// @dev Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);

/// @dev The total basis points for a fee schedule, policy fee receivers at policy creation, or maker bp cannot be greater than half of LibConstants.BP_FACTOR.
///     This is to prevent the total basis points of a fee schedule with additional fee receivers (policy fee receivers for fee payments on premiums) from being greater than 100%.
error FeeBasisPointsExceedHalfMax(uint256 actual, uint256 expected);

/// @dev The total fees can never exceed the premium payment or the marketplace trade.
error FeeBasisPointsExceedMax(uint256 actual, uint256 expected);

/// @dev When validating an entity, the utilized capacity cannot be greater than the max capacity.
error UtilizedCapacityGreaterThanMaxCapacity(uint256 utilizedCapacity, uint256 maxCapacity);

/// @dev Policy stakeholder signature validation failed
error SimplePolicyStakeholderSignatureInvalid(bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId);

/// @dev When creating a simple policy, the total claims paid should start at 0.
error SimplePolicyClaimsPaidShouldStartAtZero();

/// @dev When creating a simple policy, the total premiums paid should start at 0.
error SimplePolicyPremiumsPaidShouldStartAtZero();

/// @dev The cancel bool should not be set to true when creating a new simple policy.
error CancelCannotBeTrueWhenCreatingSimplePolicy();

/// @dev (non specific) The policyId must exist.
error PolicyDoesNotExist(bytes32 policyId);

/// @dev There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);