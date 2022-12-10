// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskSubscriptionPlans {

    enum PlanStatus {
        Enabled,
        Disabled,
        EndOfLife
    }

    enum DiscountType {
        None,
        Code,
        ERC20
    }

    struct Discount {
        uint256 value;
        uint32 validAfter;
        uint32 expiresAt;
        uint32 maxRedemptions;
        uint32 planId;
        uint16 applyPeriods;
        DiscountType discountType;
        bool isFixed;
    }

    struct Provider {
        address paymentAddress;
        uint256 nonce;
        string cid;
    }

    function setProviderProfile(address _paymentAddress, string calldata _cid, uint256 _nonce) external;

    function getProviderProfile(address _provider) external view returns(Provider memory);

    function getPlanStatus(address _provider, uint32 _planId) external view returns (PlanStatus);

    function getPlanEOL(address _provider, uint32 _planId) external view returns (uint32);

    function disablePlan(uint32 _planId) external;

    function enablePlan(uint32 _planId) external;

    function retirePlan(uint32 _planId, uint32 _retireAt) external;

    function verifyPlan(bytes32 _planData, bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof) external view returns(bool);

    function getDiscountRedemptions(address _provider, uint32 _planId,
        bytes32 _discountId) external view returns(uint256);

    function verifyAndConsumeDiscount(address _consumer, address _provider, uint32 _planId,
        bytes32[] calldata _discountProof) external returns(bytes32);

    function verifyDiscount(address _consumer, address _provider, uint32 _planId,
        bytes32[] calldata _discountProof) external returns(bytes32);

    function erc20DiscountCurrentlyApplies(address _consumer, bytes32 _discountValidator) external returns(bool);

    function verifyProviderSignature(address _provider, uint256 _nonce, bytes32 _planMerkleRoot,
        bytes32 _discountMerkleRoot, bytes memory _providerSignature) external view returns (bool);

    function verifyNetworkData(address _network, bytes32 _networkData,
        bytes memory _networkSignature) external view returns (bool);


    /** @dev Emitted when `provider` sets their profile info */
    event ProviderSetProfile(address indexed provider, address indexed paymentAddress, uint256 nonce, string cid);

    /** @dev Emitted when `provider` disables a subscription plan */
    event PlanDisabled(address indexed provider, uint32 indexed planId);

    /** @dev Emitted when `provider` enables a subscription plan */
    event PlanEnabled(address indexed provider, uint32 indexed planId);

    /** @dev Emitted when `provider` end-of-lifes a subscription plan */
    event PlanRetired(address indexed provider, uint32 indexed planId, uint32 retireAt);

}