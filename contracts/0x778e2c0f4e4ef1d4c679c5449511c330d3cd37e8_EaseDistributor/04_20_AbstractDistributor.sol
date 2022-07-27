// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/utils/PreciseUnitMath.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../dependencies/interfaces/IUniswapV2Router02.sol";

abstract contract AbstractDistributor {
    using SafeMathUpgradeable for uint256;
    event BuyCoverEvent(
        address _productAddress,
        uint256 _productId,
        uint256 _period,
        address _asset,
        uint256 _amount,
        uint256 _price
    );

    uint256 constant MAX_INT = type(uint256).max;

    uint256 constant DECIMALS18 = 10**18;

    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENTAGE_100 = 100 * PRECISION;

    address constant ETH = (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
}