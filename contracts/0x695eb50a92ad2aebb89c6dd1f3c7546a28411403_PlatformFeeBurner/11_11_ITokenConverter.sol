// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITokenConverter {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice The address of Converter Registry.
  function registry() external view returns (address);

  /// @notice Return the input token and output token for the route.
  /// @param route The encoding of the route.
  /// @return tokenIn The address of input token.
  /// @return tokenOut The address of output token.
  function getTokenPair(uint256 route) external view returns (address tokenIn, address tokenOut);

  /// @notice Query the output token amount according to the encoding.
  ///
  /// @dev See the comments in `convert` for the meaning of encoding.
  ///
  /// @param encoding The encoding used to convert.
  /// @param amountIn The amount of input token.
  /// @param amountOut The amount of output token received.
  function queryConvert(uint256 encoding, uint256 amountIn) external view returns (uint256 amountOut);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Convert input token to output token according to the encoding.
  /// Assuming that the input token is already in the contract.
  ///
  /// @dev encoding for single route
  /// |   8 bits  | 2 bits |  246 bits  |
  /// | pool_type | action | customized |
  ///
  /// + pool_type = 0: UniswapV2, only action = 0
  ///   customized = |   160 bits   | 24 bits |     1 bit    | 1 bit | ... |
  ///                | pool address | fee_num | zero_for_one | twamm | ... |
  /// + pool_type = 1: UniswapV3, only action = 0
  ///   customized = |   160 bits   | 24 bits |     1 bit    | ... |
  ///                | pool address | fee_num | zero_for_one | ... |
  /// + pool_type = 2: BalancerV1, only action = 0
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  | ... |
  ///                | pool address | tokens | index in | index out | ... |
  /// + pool_type = 3: BalancerV2, only action = 0
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  | ... |
  ///                | pool address | tokens | index in | index out | ... |
  /// + pool_type = 4: CurvePlainPool or CurveFactoryPlainPool
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  |  1 bit  | ... |
  ///                | pool address | tokens | index in | index out | use_eth | ... |
  /// + pool_type = 5: CurveAPool
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  |     1 bits     | ... |
  ///                | pool address | tokens | index in | index out | use_underlying | ... |
  /// + pool_type = 6: CurveYPool
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  |     1 bits     | ... |
  ///                | pool address | tokens | index in | index out | use_underlying | ... |
  /// + pool_type = 7: CurveMetaPool or CurveFactoryMetaPool
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  | ... |
  ///                | pool address | tokens | index in | index out | ... |
  /// + pool_type = 8: CurveCryptoPool or CurveFactoryCryptoPool
  ///   customized = |   160 bits   | 3 bits |  3 bits  |   3 bits  |  1 bit  | ... |
  ///                | pool address | tokens | index in | index out | use_eth | ... |
  /// + pool_type = 9: ERC4626
  ///   customized = |   160 bits   | ... |
  ///                | pool address | ... |
  ///
  /// Note: tokens + 1 is the number of tokens of the pool
  ///
  /// + action = 0: swap
  /// + action = 1: add liquidity / wrap / stake
  /// + action = 2: remove liquidity / unwrap / unstake
  ///
  /// @param encoding The encoding used to convert.
  /// @param amountIn The amount of input token.
  /// @param recipient The address of token receiver.
  /// @return amountOut The amount of output token received.
  function convert(
    uint256 encoding,
    uint256 amountIn,
    address recipient
  ) external payable returns (uint256 amountOut);

  /// @notice Withdraw dust assets in this contract.
  /// @param token The address of token to withdraw.
  /// @param recipient The address of token receiver.
  function withdrawFund(address token, address recipient) external;
}