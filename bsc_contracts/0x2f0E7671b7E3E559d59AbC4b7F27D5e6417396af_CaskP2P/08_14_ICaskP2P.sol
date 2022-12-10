// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskP2P {

    enum P2PStatus {
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

    struct P2P {
        address user;
        address to;
        uint256 amount;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 numPayments;
        uint256 numSkips;
        uint32 period;
        uint32 createdAt;
        uint32 processAt;
        P2PStatus status;
    }

    function createP2P(
        address _to,
        uint256 _amount,
        uint256 _totalAmount,
        uint32 _period
    ) external returns(bytes32);

    function getP2P(bytes32 _p2pId) external view returns (P2P memory);

    function getUserP2P(address _user, uint256 _idx) external view returns (bytes32);

    function getUserP2PCount(address _user) external view returns (uint256);

    function cancelP2P(bytes32 _p2pId) external;

    function pauseP2P(bytes32 _p2pId) external;

    function resumeP2P(bytes32 _p2pId) external;

    function managerCommand(bytes32 _p2pId, ManagerCommand _command) external;

    function managerProcessed(bytes32 _p2pId, uint256 amount, uint256 _fee) external;


    event P2PCreated(bytes32 indexed p2pId, address indexed user, address indexed to,
        uint256 amount, uint256 totalAmount, uint32 period);

    event P2PPaused(bytes32 indexed p2pId, address indexed user);

    event P2PResumed(bytes32 indexed p2pId, address indexed user);

    event P2PSkipped(bytes32 indexed p2pId, address indexed user);

    event P2PProcessed(bytes32 indexed p2pId, address indexed user, uint256 amount, uint256 fee);

    event P2PCanceled(bytes32 indexed p2pId, address indexed user);

    event P2PCompleted(bytes32 indexed p2pId, address indexed user);
}