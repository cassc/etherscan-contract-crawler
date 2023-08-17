// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.7.6;


/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    TwapAdapter02.sol :: 0xdd584de33adb0959b581a4f34403b8e67ebb97f1
 *    etherscan.io verified 2023-08-15
 */ 
import "./TwapLogic02.sol";

contract TwapAdapter02 is TwapLogic02 {

  function getUint256(bytes memory params) public view override returns (uint256) {
    (address uniswapV3Pool, uint32 twapInterval) = abi.decode(params, (address,uint32));
    return getTwapX96(uniswapV3Pool, twapInterval);
  }

}