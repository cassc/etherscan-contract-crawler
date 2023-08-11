// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface for Curve StableSwap pool
 */
interface IStableSwap {
    /**
     * @notice Perform an exchange between two underlying coins
     * @param i Index value for the underlying coin to send
     * @param j Index valie of the underlying coin to receive
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external payable returns (uint256);

    /**
     * @notice Perform an exchange between two underlying coins
     * @param i Index value for the underlying coin to send
     * @param j Index valie of the underlying coin to receive
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external payable returns (uint256);

    /**
     * @notice Deposit coins into the pool
     * @param _amounts List of amounts of coins to deposit
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
     * @return amount of LP tokens received by depositing
     */
    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    /**
     * @notice Withdraw a single coin from the pool
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param _min_received Minimum amount of coin to receive
     * @return Amount of coin received
     */
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external payable returns (uint256);

    /**
     * @notice Calculate addition or reduction in token supply from a deposit or withdrawal
     * @dev This calculation accounts for slippage, but not fees.
     *      Needed to prevent front-running, not for precise calculations!
     * @param _amounts Amount of each underlying coin being deposited
     * @param _is_deposit set True for deposits, False for withdrawals
     * @return Expected amount of LP tokens received
     */
    function calc_token_amount(
        uint256[2] memory _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    /**
     * @notice Calculate the amount received when withdrawing a single coin
     * @param _token_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @return Amount of coin received
     */
    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    /**
     * @notice The current virtual price of the pool LP token
     * @dev Useful for calculating profits
     * @return LP token virtual price normalized to 1e18
     */
    function get_virtual_price() external view returns (uint256);

    /**
     * @notice Get the amount received (“dy”) when swapping between two underlying assets within the pool.
     * @param i Index value of the token to send.
     * @param j Index value of the token to receive.
     * @param dx: The amount of i being exchanged.
     * @return amount of j received
     */
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}