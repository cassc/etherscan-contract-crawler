// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "IXfaiPool.sol";

library XfaiLibrary {
  /**
   * @notice Calculates the CREATE2 address for a pool without making any external calls
   * @param _token An ERC20 token address
   * @param _factory The factory contract of Xfai
   * @param _poolCodeHash The codehash of the Xfai pool contract
   * @return pool The deterministic pool address for a given _token
   */
  function poolFor(
    address _token,
    address _factory,
    bytes32 _poolCodeHash
  ) internal pure returns (address pool) {
    pool = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              _factory,
              keccak256(abi.encodePacked(_token)),
              _poolCodeHash // init code hash
            )
          )
        )
      )
    );
  }

  function getAdjustedOutput(uint _amountIn, uint _r, uint _w) internal pure returns (uint out) {
    out = (_amountIn * _w) / (_r + _amountIn);
  }

  function getAdjustedInput(uint _amountOut, uint _r, uint _w) internal pure returns (uint input) {
    input = ((_amountOut * _r) / (_w - _amountOut)) + 1;
  }

  function quote(uint _amountIn, uint _a, uint _b) internal pure returns (uint out) {
    out = (_amountIn * _a) / _b;
  }

  /**
   * @notice Calculates the adjusted price of an _amountIn (of a token from _pool0) in terms of the token in _pool1
   * @dev either token0 or token1 must be xfETH
   * @param _reserve0 The reserve of _token0 (can be xfETH)
   * @param _reserve1 The reserve of _token1 (can be xfETH)
   * @param _amountIn The token input amount to _pool0
   * @return output The token output between a token - xfETH interaction
   */
  function getAmountOut(
    uint _reserve0,
    uint _reserve1,
    uint _amountIn,
    uint _totalFee
  ) public pure returns (uint output) {
    require(_amountIn > 0, 'Xfai: INSUFFICIENT_AMOUNT');
    require(_reserve0 > 0, 'Xfai: INSUFFICIENT_LIQUIDITY');
    require(_reserve1 > 0, 'Xfai: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = _amountIn * (10000 - _totalFee);
    uint numerator = amountInWithFee * _reserve1;
    output = numerator / (_reserve0 * 10000 + amountInWithFee);
  }

  /**
   * @notice Calculates the adjusted price of an _amountOut (of a token from _pool1) in terms of the token in _pool0
   * @param _reserve0 The reserve of _token0 (can be xfETH)
   * @param _reserve1 The reserve of _token1 (can be xfETH)
   * @param _amountOut The token output amount from _pool0
   * @return input The token input amount to _pool0
   */
  function getAmountIn(
    uint _reserve0,
    uint _reserve1,
    uint _amountOut,
    uint _totalFee
  ) public pure returns (uint input) {
    require(_amountOut > 0, 'Xfai: INSUFFICIENT_AMOUNT');
    require(_reserve0 > 0, 'Xfai: INSUFFICIENT_LIQUIDITY');
    require(_reserve1 > 0, 'Xfai: INSUFFICIENT_LIQUIDITY');
    uint numerator = _amountOut * _reserve0 * 10000;
    uint denominator = (_reserve1 - _amountOut) * (10000 - _totalFee);
    input = (numerator / denominator) + 1;
  }

  /**
   * @notice Calculates the adjusted price of an _amountIn (of a token from _pool0) in terms of the token in _pool1
   * @param _pool0 A pool address
   * @param _pool1 A pool address
   * @param _amountIn The token input amount to _pool0
   * @return out1 The token output amount from _pool1
   */
  function getAmountsOut(
    address _pool0,
    address _pool1,
    uint _amountIn,
    uint _totalFee
  ) public view returns (uint out1) {
    (uint r0, uint w0) = IXfaiPool(_pool0).getStates();
    (uint r1, uint w1) = IXfaiPool(_pool1).getStates();
    uint weight0Out = getAmountOut(r0, w0, _amountIn, _totalFee);
    out1 = getAdjustedOutput(weight0Out, w1, r1);
  }

  /**
   * @notice Calculates the adjusted price of an _amountOut (of a token from _pool1) in terms of the token in _pool0
   * @param _pool0 A pool address
   * @param _pool1 A pool address
   * @param _amountOut The token output amount from _pool1
   * @return inp0 The token input amount to _pool0
   */
  function getAmountsIn(
    address _pool0,
    address _pool1,
    uint _amountOut,
    uint _totalFee
  ) public view returns (uint inp0) {
    (uint r0, uint w0) = IXfaiPool(_pool0).getStates();
    (uint r1, uint w1) = IXfaiPool(_pool1).getStates();
    uint weight0Out = getAdjustedInput(_amountOut, w1, r1);
    inp0 = getAmountIn(r0, w0, weight0Out, _totalFee);
  }
}