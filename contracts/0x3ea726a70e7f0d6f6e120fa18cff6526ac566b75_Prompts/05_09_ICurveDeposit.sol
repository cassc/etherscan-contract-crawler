pragma solidity ^0.8.13;

interface ICurveDeposit { 
  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable returns (uint256);
  function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external returns (uint256);
  function calc_withdraw_one_coin(uint256 _amounts, int128 i) external returns (uint256);
  function remove_liquidity(uint256 _amount, uint256[2] calldata min_uamounts) external returns (uint256[2] memory);
  function remove_liquidity_one_coin(uint256 _amount, int128 i, uint256 minAmount) external returns (uint256);
  function balances(uint256 i) external returns(uint256);
  function get_virtual_price() external returns(uint256);
}