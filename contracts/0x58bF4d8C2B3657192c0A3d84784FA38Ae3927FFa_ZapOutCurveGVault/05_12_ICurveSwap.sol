interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool removeUnderlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 index)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 tokenAmount,
        int128 index,
        bool _use_underlying
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 index)
        external
        view
        returns (uint256);
}