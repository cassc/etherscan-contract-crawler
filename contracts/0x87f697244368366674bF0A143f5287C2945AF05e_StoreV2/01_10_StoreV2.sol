// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Storage} from "../Storage.sol";

contract StoreV2 is Ownable, Pausable {
  /// @notice Storage contract
  Storage public info;

  /// @notice Products.
  mapping(uint8 => uint256) public products;

  event StorageChanged(address indexed info);

  event ProductChanged(uint8 indexed product, uint256 priceUSD);

  event Buy(uint8 indexed product, address indexed recipient);

  /**
   * @param _info New storage contract address.
   */
  function initialize(address _info) public initializer {
    require(_info != address(0), "Store::initialize: invalid storage contract address");
    __Ownable_init();
    __Pausable_init();
    info = Storage(_info);
  }

  /**
   * @notice Change storage contract address.
   * @param _info New storage contract address.
   */
  function changeStorage(address _info) external onlyOwner {
    require(_info != address(0), "Store::changeStorage: invalid storage contract address");
    info = Storage(_info);
    emit StorageChanged(_info);
  }

  /**
   * @notice Update product price.
   * @param id Product identificator.
   * @param priceUSD Product price in USD with price feed oracle decimals (zero if product is not for sale).
   */
  function changeProduct(uint8 id, uint256 priceUSD) external onlyOwner {
    products[id] = priceUSD;
    emit ProductChanged(id, priceUSD);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Get current product price.
   * @param product Target product.
   * @return Product price in network native token.
   */
  function price(uint8 product) public view returns (uint256) {
    (, int256 answer, , , ) = AggregatorV3Interface(info.getAddress(keccak256("DFH:Fee:PriceFeed"))).latestRoundData();
    require(answer > 0, "Store::price: invalid price feed response");

    return (products[product] * 1e18) / uint256(answer);
  }

  /**
   * @notice Buy product.
   * @param product Target product.
   * @param recipient Product recipient.
   */
  function buy(uint8 product, address recipient) external payable whenNotPaused {
    require(products[product] > 0, "Store::buy: undefined product");
    uint256 currentPrice = price(product);
    require(msg.value >= currentPrice, "Store::buy: insufficient funds to pay product price");
    address treasury = info.getAddress(keccak256("DFH:Contract:Treasury"));
    require(treasury != address(0), "Store::buy: invalid treasury contract address");

    // solhint-disable-next-line avoid-low-level-calls
    (bool sentTreasury, ) = payable(treasury).call{value: currentPrice}("");
    require(sentTreasury, "Store::buy: transfer of product funds to the treasury failed");
    if (msg.value > currentPrice) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool sentRemained, ) = payable(msg.sender).call{value: msg.value - currentPrice}("");
      require(sentRemained, "Store::buy: transfer of remained tokens to the sender failed");
    }
    emit Buy(product, recipient);
  }
}