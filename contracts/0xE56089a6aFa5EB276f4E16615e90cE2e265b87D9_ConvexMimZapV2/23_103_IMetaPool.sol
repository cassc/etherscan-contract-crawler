// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the Curve metapool contract
 * @dev A metapool is sometimes its own LP token
 */
/* solhint-disable func-name-mixedcase */
/* solhint-disable func-param-name-mixedcase */
interface IMetaPool is IERC20 {
    /// @dev the number of coins is hard-coded in curve contracts
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /// @dev the number of coins is hard-coded in curve contracts
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    /// @dev 1st coin is the protocol token, 2nd is the Curve base pool
    function balances(uint256 coin) external view returns (uint256);

    /// @dev 1st coin is the protocol token, 2nd is the Curve base pool
    function coins(uint256 coin) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}
/* solhint-enable */