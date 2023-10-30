// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IDoughV1Index {
    function owner() external view returns (address);

    function TREASURY() external view returns (address);

    function SHIELD_EXECUTOR() external view returns (address);

    function SUPPLY_FEE() external view returns (uint256);

    function WITHDRAW_FEE() external view returns (uint256);

    function BORROW_FEE() external view returns (uint256);

    function REPAY_FEE() external view returns (uint256);

    function SWAP_FEE() external view returns (uint256);

    function FLASHLOAN_FEE() external view returns (uint256);

    function SHIELD_FEE() external view returns (uint256);

    function SHIELD_EXECUTE_FEE() external view returns (uint256);

    function getShieldInfo(address dsa) external view returns (uint256, uint256, address, address);

    function getDoughV1Connector(uint256 _connectorId) external view returns (address);
}

interface IDoughV1Dsa {
    function TREASURY() external view returns (address);

    function SHIELD_EXECUTOR() external view returns (address);

    function DoughV1Index() external view returns (address);

    function executeAction(address loanToken, uint256 inAmount, uint256 outAmount, uint256 funcId, bool isShield) external;
}

interface IAaveV3DataProvider {
    function getUserReserveData(
        address asset,
        address user
    ) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
}

interface IAaveV3Pool {
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    function getUserAccountData(address user) external view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
}

interface IAaveV3Oracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IConnectorV1Flashloan {
    function flashloanReq(address _loanToken, uint256 _loanAmount, uint256 _funcId, bool _isShield) external;
}