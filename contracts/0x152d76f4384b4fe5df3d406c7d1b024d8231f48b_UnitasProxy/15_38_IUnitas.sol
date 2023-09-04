// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IERC20Token.sol";
import "./ISwapFunctions.sol";
import "./ITokenManager.sol";
import "./IOracle.sol";

interface IUnitas is ISwapFunctions {
    enum ReserveStatus {
        Undefined, // When total reserves, total collaterals and total liabilities are zero
        Infinite, // When total liabilities is zero
        Finite // When total reserves, total collaterals and total liabilities are non-zero
    }

    struct InitializeConfig {
        address governor;
        address guardian;
        address timelock;
        address oracle;
        address surplusPool;
        address insurancePool;
        ITokenManager tokenManager;
    }

    function setOracle(address newOracle) external;

    function setSurplusPool(address newSurplusPool) external;

    function setInsurancePool(address newInsurancePool) external;

    function setTokenManager(ITokenManager newTokenManager) external;

    function pause() external;

    function unpause() external;

    function swap(address tokenIn, address tokenOut, AmountType amountType, uint256 amount)
        external
        returns (uint256 amountIn, uint256 amountOut);

    function receivePortfolio(address token, uint256 amount) external;

    function sendPortfolio(address token, address receiver, uint256 amount) external;

    function oracle() external view returns (IOracle);

    function surplusPool() external view returns (address);

    function insurancePool() external view returns (address);

    function tokenManager() external view returns (ITokenManager);

    function estimateSwapResult(address tokenIn, address tokenOut, AmountType amountType, uint256 amount)
        external
        view
        returns (uint256 amountIn, uint256 amountOut, IERC20Token feeToken, uint256 fee, uint24 feeNumerator, uint256 price);

    function getReserve(address token) external view returns (uint256);

    function getPortfolio(address token) external view returns (uint256);

    function getReserveStatus()
        external
        view
        returns (ReserveStatus reserveStatus, uint256 reserves, uint256 collaterals, uint256 liabilities, uint256 reserveRatio);
}