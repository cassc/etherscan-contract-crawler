//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
// import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

interface Presale {
  function stagePrice() external returns(uint);
  function buyWithCoinDirectPay(uint256 amount, address sender) external payable;
  function ethBuyHelper(uint256 amount) external view returns (uint256);
  function getLatestPrice() external view returns (uint256);
}

contract PaymentUpgradable is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  Presale public presale;

  event Pay(address indexed sender, uint amount, uint ethCost, uint timestamp);

  event SetPresale(address presale, uint timestamp);

  function initialize(address _presale) external initializer {
    require(_presale != address(0), 'zero address presale');

    __Ownable_init_unchained();
    __ReentrancyGuard_init_unchained();

    presale = Presale(_presale);
    emit SetPresale(_presale, block.timestamp);
  }

  function changePresaleAddress(address _presale) external onlyOwner() {
    require(_presale != address(0), 'zero address presale');
    presale = Presale(_presale);

    emit SetPresale(_presale, block.timestamp);
  }

  receive() external payable nonReentrant {
    uint price = presale.stagePrice();
    require(price > 0, 'not set value stagePrice in presale contract');
    uint priceCoin = presale.getLatestPrice();
    uint amount = (msg.value * priceCoin / price) / 10 ** 18;
    require(amount > 0, 'failed to count amount of tokens');

    uint cost = presale.ethBuyHelper(amount);
    require(cost < msg.value, 'less payment');

    try presale.buyWithCoinDirectPay{ value: cost }(amount, _msgSender()) {
        if (msg.value > cost) {
            (bool success, ) = payable(_msgSender()).call{ value: msg.value - cost }("");
            require(success, 'refund failed');
        }

        emit Pay(_msgSender(), amount, cost, block.timestamp);
    } catch Error(string memory reason) {
      revert(reason);
    }
  }
}