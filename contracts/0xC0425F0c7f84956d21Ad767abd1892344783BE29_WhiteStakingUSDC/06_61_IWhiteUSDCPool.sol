// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface ILiquidityPool {
    struct LockedLiquidity { uint120 amount; uint120 premium; bool locked; }

    event Profit(uint indexed id, uint amount);
    event Loss(uint indexed id, uint amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event Withdraw(address indexed account, uint256 amount, uint256 writeAmount);

    function unlock(uint256 id) external;
    function setLockupPeriod(uint value) external;
    function deleteLockedLiquidity(uint id) external;
    function totalBalance() external view returns (uint256 amount);
    function setAllowedWHAsset(address _whAsset, bool approved) external;
    function send(uint256 id, address payable account, uint256 amount, uint payKeep3r) external;
}


interface IWhiteUSDCPool is ILiquidityPool {
    function lock(uint id, uint256 amountToLock, uint256 premium) external;
    function token() external view returns (IERC20);
    function payKeep3r(address keep3r) external returns (uint amount);
}