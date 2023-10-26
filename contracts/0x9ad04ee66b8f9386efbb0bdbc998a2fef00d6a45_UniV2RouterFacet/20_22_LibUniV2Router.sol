// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV2Pair} from 'contracts/interfaces/external/IUniswapV2Pair.sol';
import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IWETH} from '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibUniV2Router {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('diamond.storage.LibUniV2Router');

  struct DiamondStorage {
    bool isInitialized;
    IWETH weth;
    IUniswapV2Router02 uniswapV2router02;
    address uniswapV2Factory;
    IPermit2 permit2;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage s) {
    bytes32 position = DIAMOND_STORAGE_POSITION;

    assembly {
      s.slot := position
    }
  }

  // calculates the CREATE2 address for a pair without making any external calls
  // NOTE: Modified to work with newer Solidity
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    if (tokenA > tokenB) {
      (tokenA, tokenB) = (tokenB, tokenA);
    }

    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              factory,
              keccak256(abi.encodePacked(tokenA, tokenB)),
              hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )
          )
        )
      )
    );
  }

  function getPairsAndAmountsFromPath(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (address[] memory pairs, uint256[] memory amounts) {
    uint256 pathLengthMinusOne = path.length - 1;

    pairs = new address[](pathLengthMinusOne);
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;

    for (uint256 index; index < pathLengthMinusOne; ) {
      address token0 = path[index];
      address token1 = path[index + 1];

      pairs[index] = pairFor(factory, token0, token1);

      (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pairFor(factory, token0, token1))
        .getReserves();

      if (token0 > token1) {
        (reserveIn, reserveOut) = (reserveOut, reserveIn);
      }

      unchecked {
        amountIn = ((amountIn * 997) * reserveOut) / ((reserveIn * 1000) + (amountIn * 997));
      }

      // Recycling `amountIn`
      amounts[index + 1] = amountIn;

      unchecked {
        index++;
      }
    }
  }
}