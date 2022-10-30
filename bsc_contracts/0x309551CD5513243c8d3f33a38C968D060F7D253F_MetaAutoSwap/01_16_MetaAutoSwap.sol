// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MetaAutoSwap is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function initialize() external initializer {
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        meb = 0x7268B479eb7CE8D1B37Ef1FFc3b82d7383A1162d;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        lp = 0x9b22403637F18020B78696766d2Be7De2F1a67e2;
        router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        swapRouter = IUniswapV2Router01(router);

        IERC20Upgradeable(usdt).approve(router, 2**255);
        IERC20Upgradeable(meb).approve(router, 2**255);
    }

    address public meb;
    address public usdt;
    address public lp;
    address public router;

    IUniswapV2Router01 swapRouter;

    function usdtToLp(uint256 amount, uint256 slippage) external {
        uint256 usdtAmount = calcLpToUsdt(amount, slippage);

        IERC20Upgradeable(usdt).safeTransferFrom(msg.sender, address(this), usdtAmount * 2);

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(meb);
        uint256 mebAmount = swapRouter.swapExactTokensForTokens(usdtAmount, 0, path, address(this), block.timestamp + 30)[1];

        (uint256 amountA, uint256 amountB, uint256 liquidity) = swapRouter.addLiquidity(usdt, meb, usdtAmount, mebAmount, 0, 0, msg.sender, block.timestamp + 30);
        if (liquidity < amount) {
            revert("Slippage too low.");
        }
        if (usdtAmount > amountA) {
            IERC20Upgradeable(usdt).safeTransfer(msg.sender, usdtAmount - amountA);
        }
        if (mebAmount > amountB) {
            IERC20Upgradeable(usdt).safeTransfer(msg.sender, mebAmount - amountB);
        }
    }

    function calcLpToUsdt(uint256 amount, uint256 slippage) public view returns (uint256) {
        return (((IERC20Upgradeable(usdt).balanceOf(lp) * amount) / IERC20Upgradeable(lp).totalSupply()) * slippage) / 1e18;
    }

    function settle(IERC20Upgradeable token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(msg.sender, amount);
    }
}

interface IUniswapV2Router01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}