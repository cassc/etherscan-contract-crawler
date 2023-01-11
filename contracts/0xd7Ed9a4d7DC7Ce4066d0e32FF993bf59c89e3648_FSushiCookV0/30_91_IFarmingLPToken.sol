// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFarmingLPToken is IERC20 {
    error InvalidPath();
    error InsufficientYield();
    error InsufficientAmount();
    error NoMigratorSet();

    event Deposit(uint256 shares, uint256 amountLP, address indexed beneficiary);
    event Withdraw(uint256 shares, uint256 amountLP, address indexed beneficiary);
    event EmergencyWithdraw(uint256 shares, uint256 amountLP, address indexed beneficiary);
    event ClaimSushi(uint256 shares, uint256 yield, address indexed beneficiary);
    event Migrate(uint256 shares, uint256 amountLP, address indexed beneficiary);
    event EmergencyMigrate(uint256 shares, uint256 amountLP, address indexed beneficiary);

    function initialize(
        address _router,
        address _masterChef,
        uint256 _pid
    ) external;

    function factory() external view returns (address);

    function router() external view returns (address);

    function masterChef() external view returns (address);

    function sushi() external view returns (address);

    function pid() external view returns (uint256);

    function lpToken() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function withdrawableTotalLPs() external view returns (uint256);

    function withdrawableLPsOf(address account) external view returns (uint256);

    function withdrawableTotalYield() external view returns (uint256);

    function withdrawableYieldOf(address account) external view returns (uint256);

    function totalShares() external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function approveMax() external;

    function depositSigned(
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary,
        uint256 deadline
    ) external;

    function depositWithSushi(
        uint256 amount,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountLPMin,
        address beneficiary,
        uint256 deadline
    ) external;

    function withdraw(uint256 shares, address beneficiary) external;

    function emergencyWithdraw(address beneficiary) external;

    function migrate(address beneficiary, bytes calldata params) external;

    function emergencyMigrate(address beneficiary, bytes calldata params) external;

    function checkpoint() external;
}