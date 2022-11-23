// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStakeMaster {

    function createStakingPool(
        IERC20Upgradeable _stakingToken,
        IERC20Upgradeable _poolToken,
        uint256 _startTime,
        uint256 _finishTime,
        uint256 _poolTokenAmount,
        bool _hasWhitelisting,
        uint256 _depositFeeBP,
        address _feeTo
    ) external;

    function profitSharingBP(address _address) external view returns (uint256);

    function feeWallet() external view returns (address);

    function owner() external view returns (address);

    function maxDepositFee() external view returns (uint256);

    function resetStartOnce(address _user) external;

    function getStartByUpdaters(address _user) external view returns (uint256);

    function tierCalculator() external view returns (address);
}