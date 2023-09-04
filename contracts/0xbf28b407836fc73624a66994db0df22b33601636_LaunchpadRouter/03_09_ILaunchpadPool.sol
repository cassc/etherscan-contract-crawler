// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

interface ILaunchpadPool {
    struct VestingPhase {
        uint256 fromTimestamp;
        uint256 toTimestamp;
        uint256 percentage;
    }

    struct VestingPlan {
        uint256 length;
        mapping(uint256 => VestingPhase) phases;
    }

    struct PurchasePhase {
        uint256 fromTimestamp;
        uint256 toTimestamp;
    }

    struct PurchasePlan {
        uint256 length;
        mapping(uint256 => PurchasePhase) phases;
    }

    struct PoolDetail {
        string poolId;
        string poolType;
        address tokenAddress;
        uint256[] tokenSupply;
        uint256[] tokenSold;
        uint256[] openAllocation;
        address supportedPayment;
        uint256[] supportedRates;
        PurchasePhase[] purchasePlan;
        VestingPhase[] vestingPlan;
        uint256 bps;
    }

    struct UserDetail {
        string poolId;
        address userAddress;
        uint256[] orderedAmount;
        uint256[] vestedAmount;
        uint256[] accumulatedAmount;
    }

    event SetVerifier(address verifier);

    event NewMerkleRoot(
        bytes32 root,
        string ipfsCID,
        address submitter
    );

    event TokenWithdraw(address token, uint256 amount, address sendTo);
    
    event EtherWithdraw(uint256 amount, address sendTo);

    event NewPoolPlans(
        PurchasePhase[] purchasePlan,
        VestingPhase[] vestingPlan
    );

    event NewPaymentTypes(
        address _paymentToken, 
        uint256[] _paymentRates
    );

    event NewOrder(
        string indexed poolId,
        address recipient, 
        address paymentToken, 
        uint256 paymentAmount, 
        uint256[] purchaseAmount
    );

    // Admin
    function submitMerkleRoot(bytes32 _merkleRoot, string calldata _ipfsCID) external;

    // Actions
    function purchase(
        address buyer,
        address paymentToken,
        uint256 paymentAmount,
        uint256[] calldata purchaseAmount,
        uint256[] calldata purchaseCap,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    ) external payable;

    function vest(address buyer, uint256[] calldata vestAmount) external;

    // Views
    function getPoolDetail() external view returns (PoolDetail memory);

    function getUserDetails(address[] calldata userAddresses) external view returns (UserDetail[] memory);

    function updatePool(uint256[] calldata _openAllocation) external;

    function updatePlans(
        PurchasePhase[] calldata _purchasePlan,
        VestingPhase[] calldata _vestingPlan
    ) external;

    function updateTokenAddress(
        address _tokenAddress
    ) external;

    function updatePayments(address _paymentToken, uint256[] calldata _paymentRates)
        external;

    function getMerkleRoot() external view  returns(bytes32);

    function getIpfsCID() external view returns(string memory);
}