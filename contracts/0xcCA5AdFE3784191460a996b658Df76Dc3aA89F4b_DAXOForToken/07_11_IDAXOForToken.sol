// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Accepts USDC, USDT and ETH in exchange for the DAL token, at a fixed price.
 */
interface IDAXOForToken {
    event DAXOSold(
        address indexed buyer,
        uint256 dalAmount,
        address indexed quoteToken,
        uint256 quoteTokenAmount 
    );

    function buy(uint8 tokenType, uint256 tokenAmount) external returns (uint256);
    function buyWithETH() external payable returns(uint256);
    function withdrawERC20(address token, uint256 amount) external;
    function withdrawETH() external;
    function getToken(uint8 tokenIndex) external view returns (IERC20Upgradeable);
    function getDAXOToken() external view returns (IERC20Upgradeable);
    function getEstimatedDAXOOut(uint256 ethAmount) external view returns (uint256);
    /**
     * @notice Sets the sellable token.
     * @dev Function can only be called by owner()
     * @param newToken Address of token contract
     */
    function setToken(address[] calldata newToken) external;
    function setDAXOToken(address newDALToken) external;
    function setDAXOPrice(uint256 newPrice) external;
    /**
     * @notice Sets the sellable limit of token for a user per period.
     * @dev Function can only be called by owner()
     * @param newUserSellableLimitPerPeriod Max amount of token a user can sell in a period
     */
    function setUserBuyableLimitPerPeriod(
        uint256 newUserSellableLimitPerPeriod
    ) external;

    /**
     * @notice Sets the global sellable limit of token per period.
     * @dev Function can only be called by owner()
     * @param newGlobalSellableLimitPerPeriod Max amount of token sellable in a period
     */
    function setGlobalBuyableLimitPerPeriod(
        uint256 newGlobalSellableLimitPerPeriod
    ) external;

    /**
     * @notice Sets the period of token sellable duration per limit.
     * @dev Function can only be called by owner()
     * @param newPeriodLength Period of token sellable duration per limit
     */
    function setPeriodLength(uint256 newPeriodLength) external;

    /**
     * @return Price of the sellable token
     */
    function getDAXOPrice() external view returns (uint256);

    /**
     * @return Per-user limit on token sales for a period
     */
    function getUserBuyableLimitPerPeriod() external view returns (uint256);

    /**
     * @return Global limit on token sales for a period
     */
    function getGlobalBuyableLimitPerPeriod() external view returns (uint256);

    /**
     * @return Duration of time a token selling period lasts
     */
    function getPeriodLength() external view returns (uint256);

        /**
     * @param user Address of user to
     * @return Amount of token a user sold in period
     */
    function getUserToTokenAmountThisPeriod(address user)
        external
        view
        returns (uint256);

    /**
     * @return Amount of token global users sold in period
     */
    function getTotalTokenAmountThisPeriod() external view returns (uint256);
}