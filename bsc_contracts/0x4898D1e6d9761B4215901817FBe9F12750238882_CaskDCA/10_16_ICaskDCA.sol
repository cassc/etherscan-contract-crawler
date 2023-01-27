// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskDCA {

    enum SwapProtocol {
        UNIV2,
        UNIV3,
        GMX,
        JoeV2
    }

    enum DCAStatus {
        None,
        Active,
        Paused,
        Canceled,
        Complete
    }

    enum ManagerCommand {
        None,
        Cancel,
        Skip,
        Pause
    }

    enum SkipReason {
        None,
        AssetNotAllowed,
        PaymentFailed,
        OutsideLimits,
        ExcessiveSlippage,
        SwapFailed
    }

    struct DCA {
        address user;
        address to;
        address router;
        address priceFeed;
        uint256 amount;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 currentQty;
        uint256 numBuys;
        uint256 numSkips;
        uint256 maxSlippageBps;
        uint256 maxPrice;
        uint256 minPrice;
        uint32 period;
        uint32 createdAt;
        uint32 processAt;
        DCAStatus status;
        address[] path;
    }

    struct SwapInfo {
        SwapProtocol swapProtocol;
        bytes swapData;
    }

    function createDCA(
        address[] calldata _assetSpec, // router, priceFeed, path...
        bytes32[] calldata _merkleProof,
        SwapProtocol _swapProtocol,
        bytes calldata _swapData,
        address _to,
        uint256[] calldata _priceSpec
    ) external returns(bytes32);

    function getDCA(bytes32 _dcaId) external view returns (DCA memory);

    function getSwapInfo(bytes32 _dcaId) external view returns (SwapInfo memory);

    function getUserDCA(address _user, uint256 _idx) external view returns (bytes32);

    function getUserDCACount(address _user) external view returns (uint256);

    function cancelDCA(bytes32 _dcaId) external;

    function pauseDCA(bytes32 _dcaId) external;

    function resumeDCA(bytes32 _dcaId) external;

    function managerCommand(bytes32 _dcaId, ManagerCommand _command) external;

    function managerProcessed(bytes32 _dcaId, uint256 _amount, uint256 _buyQty, uint256 _fee) external;

    function managerSkipped(bytes32 _dcaId, SkipReason _skipReason) external;

    event DCACreated(bytes32 indexed dcaId, address indexed user, address indexed to, address inputAsset,
        address outputAsset, uint256 amount, uint256 totalAmount, uint32 period);

    event DCAPaused(bytes32 indexed dcaId, address indexed user);

    event DCAResumed(bytes32 indexed dcaId, address indexed user);

    event DCASkipped(bytes32 indexed dcaId, address indexed user, SkipReason skipReason);

    event DCAProcessed(bytes32 indexed dcaId, address indexed user, uint256 amount, uint256 buyQty, uint256 fee);

    event DCACanceled(bytes32 indexed dcaId, address indexed user);

    event DCACompleted(bytes32 indexed dcaId, address indexed user);

    event AssetAdminChange(address indexed newAdmin);

    event AssetsMerkleRootChanged(bytes32 prevRoot, bytes32 newRoot);

}