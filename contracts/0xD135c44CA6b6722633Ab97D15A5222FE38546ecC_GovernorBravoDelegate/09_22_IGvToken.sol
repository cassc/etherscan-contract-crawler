/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IGvToken {
    /* ========== STRUCTS ========== */
    struct Deposit {
        uint128 amount;
        uint128 start;
    }
    struct PermitArgs {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* ========== EVENTS ========== */
    event Deposited(address indexed user, uint256 amount);
    event RedeemRequest(address indexed user, uint256 amount, uint256 endTime);
    event RedeemFinalize(address indexed user, uint256 amount);
    event Stake(
        address indexed user,
        address indexed vault,
        uint256 percentage
    );

    event UnStake(
        address indexed user,
        address indexed vault,
        uint256 percentage
    );

    function deposit(uint256 amount, PermitArgs memory args) external;

    function deposit(
        uint256 amount,
        uint256 depositStart,
        bytes32[] memory proof,
        PermitArgs memory args
    ) external;

    function withdrawRequest(uint256 amount) external;

    function withdrawFinalize() external;

    function stake(uint256 balancePercent, address vault) external;

    function unStake(uint256 balancePercent, address vault) external;

    function depositToPot(uint256 amount) external;

    function withdrawFromPot(uint256 amount) external;

    function claimReward() external;

    function claimAndDepositReward() external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setPower(bytes32 root) external;

    function setDelay(uint256 time) external;

    function setTotalSupply(uint256 newTotalSupply) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function powerStaked(address user, address vault)
        external
        view
        returns (uint256);

    function powerAvailableForStake(address user)
        external
        view
        returns (uint256);

    function getUserDeposits(address user)
        external
        view
        returns (Deposit[] memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
}