// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {AggregatorV3Interface} from '../../interfaces/IAggregatorV3Interface.sol';

/**
 * @title Coineru Token
 * @notice Coineru Token based in Gold value
 */

contract CGLD is ERC20Burnable, Ownable {
  address public receiver;
  uint256 public cgldAmount;

  AggregatorV3Interface internal priceFeed;

  /*/////////////////////////////////
                    ERRORS           
    /////////////////////////////////*/
  error CGLD__AmountMustBeMoreThanZero();
  error CGLD__BurnAmountExceedsBalance();
  error CGLD__NotZeroAddress();

  constructor(address _receiver, address _priceFeed) ERC20('Coineru', 'CGLD') {
    /**
     * @notice XAU/USD chainlink price feed
     */
    receiver = _receiver;
    priceFeed = AggregatorV3Interface(_priceFeed);
    cgldAmount = 1;
    _mint(_receiver, 230_000e18);
  }

  /**
   * @return price of CGLD in USD
   */
  function getLatestCgldUSDPrice() public view returns (int256) {
    (, int256 price,,,) = priceFeed.latestRoundData();
    return price;
  }

  /**
   * @return price of CGLD in wei
   */
  function getPriceCgldWei() public view returns (uint256) {
    uint256 cgld = uint256(getLatestCgldUSDPrice());
    return (cgldAmount * 10 ** 26 / cgld);
  }

  /**
   * @return totalPrice
   */
  function getTotalPrice() public view returns (uint256) {
    return getPriceCgldWei() + uint256(getLatestCgldUSDPrice() * 10) / 100;
  }

  /**
   * @return price of the CGLD
   */
  function setCorrectPrice() public view returns (int256) {
    int256 setPrice = getLatestCgldUSDPrice() * 10 ** 10;
    int256 replacePrice = setPrice * 1;
    return replacePrice;
  }
}