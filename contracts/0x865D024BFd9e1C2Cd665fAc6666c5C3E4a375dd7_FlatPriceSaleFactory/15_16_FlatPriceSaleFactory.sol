// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./FlatPriceSale.sol";

contract FlatPriceSaleFactory {
  address immutable public implementation;
  string public constant VERSION = '2.0';

  event NewSale(address indexed implementation, FlatPriceSale indexed clone, Config config, string baseCurrency, AggregatorV3Interface nativeOracle, bool nativePaymentsEnabled);

  constructor(address _implementation) {
    implementation = _implementation;
  }

  function newSale(
    address _owner,
    Config calldata _config,
    string calldata _baseCurrency,
    bool _nativePaymentsEnabled,
    AggregatorV3Interface _nativeTokenPriceOracle,
    IERC20Upgradeable[] calldata tokens,
    AggregatorV3Interface[] calldata oracles,
    uint8[] calldata decimals
  ) external returns (FlatPriceSale sale) {
    sale = FlatPriceSale(Clones.clone(address(implementation)));

    emit NewSale(implementation, sale, _config, _baseCurrency, _nativeTokenPriceOracle, _nativePaymentsEnabled);

    sale.initialize(
      _owner,
      _config,
      _baseCurrency,
      _nativePaymentsEnabled,
      _nativeTokenPriceOracle,
      tokens,
      oracles,
      decimals
    );

  }
}