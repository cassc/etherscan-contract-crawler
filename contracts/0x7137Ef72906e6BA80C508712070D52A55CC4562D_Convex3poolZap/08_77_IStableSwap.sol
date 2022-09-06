// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    // solhint-disable-next-line
    function underlying_coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    // solhint-disable-next-line
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 minMinAmount,
        bool useUnderlyer
    ) external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount,
        bool useUnderlyer
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);
}

// solhint-disable-next-line no-empty-blocks
interface IStableSwap3 is IStableSwap {

}