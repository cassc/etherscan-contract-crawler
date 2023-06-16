pragma solidity 0.5.15;

// checked for busd zap
interface ICrvPoolZap {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}