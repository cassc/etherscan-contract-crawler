/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IBribePot {
    /* ========== structs ========== */
    struct PermitArgs {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* ========== EVENTS ========== */
    event Leased(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event BribeAdded(
        address indexed user,
        address indexed vault,
        uint256 bribePerWeek,
        uint256 startWeek,
        uint256 endWeek
    );
    event BribeCanceled(
        address indexed user,
        address indexed vault,
        uint256 bribePerWeek,
        uint256 expiryWeek, // this will always currentWeek + 1
        uint256 endWeek
    );

    function deposit(address from, uint256 amount) external;

    function withdraw(address to, uint256 amount) external;

    function bribe(
        uint256 bribeRate,
        address vault,
        uint256 numOfWeeks,
        PermitArgs memory permit
    ) external;

    function cancelBribe(address vault) external;

    function getReward(address user, bool toUser) external returns (uint256);

    function earned(address user) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function bribePerWeek() external view returns (uint256);

    function earnable(address user) external view returns (uint256);
}