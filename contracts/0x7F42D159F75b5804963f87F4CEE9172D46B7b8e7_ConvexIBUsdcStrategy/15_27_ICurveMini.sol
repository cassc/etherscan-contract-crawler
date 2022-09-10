pragma solidity >=0.8.0 <0.9.0;

interface ICurveMini {
    function balances(uint256) external view returns (uint256);

    function coins(uint256) external view returns (address);

    function get_dy(
        uint256 from,
        uint256 to,
        uint256 _from_amount
    ) external view returns (uint256);

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);

    // CRV-ETH and CVX-ETH
    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external;

    function calc_withdraw_one_coin(uint256 amount, uint256 i) external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;
}