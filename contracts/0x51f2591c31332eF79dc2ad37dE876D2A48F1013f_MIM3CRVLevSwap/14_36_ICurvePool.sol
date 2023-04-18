// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICurvePool {
  function get_virtual_price() external view returns (uint256 price);

  function coins(uint256) external view returns (address);

  function coins(int128) external view returns (address);

  function balances(int128 _id) external view returns (uint256);

  function balances(uint256 _id) external view returns (uint256);

  function calc_withdraw_one_coin(
    uint256 _burn_amount,
    int128 i,
    bool _previous
  ) external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

  function calc_token_amount(
    uint256[2] memory _amounts,
    bool _is_deposit
  ) external view returns (uint256);

  function calc_token_amount(
    uint256[3] memory _amounts,
    bool _is_deposit
  ) external view returns (uint256);

  function calc_token_amount(
    uint256[4] memory _amounts,
    bool _is_deposit
  ) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_amount,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_amount,
    bool _use_underlying
  ) external returns (uint256);

  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;

  /**
   * @dev Index values can be found via the `coins` public getter method
   * @param i Index value for the coin to send
   * @param j Index valie of the coin to recieve
   * @param dx Amount of `i` being exchanged
   * @param min_dy Minimum amount of `j` to receive
   * @return Actual amount of `j` received
   **/
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

  function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

  function add_liquidity(uint256[4] memory amounts, uint256 _min_mint_amount) external;

  function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;
}