//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OwnerWithdrawable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bridge is Ownable, OwnerWithdrawable {

  event PurchasedTokens(uint256 indexed id, address indexed _address, int256 _price, uint256 _wei);
  event RefundETH(address _address, uint256 _wei);

  AggregatorV3Interface internal priceFeed;

  bool public saleActive;
  address public treasury;

  uint256 public id;

  modifier ifSaleActive {
    require(saleActive == true , "Sale is not active");
    _;
  }

  constructor(address _priceFeed, address _treasury) {
    treasury = _treasury;
    priceFeed = AggregatorV3Interface(_priceFeed);
    transferOwnership(_treasury);
  }

  function tokensReceived() external payable ifSaleActive {
    int256 _price;
    (, _price,,,) = priceFeed.latestRoundData();
    payable(treasury).transfer(msg.value);
    emit PurchasedTokens(id, msg.sender, _price, msg.value); // price - cost of ethereum in busd from pancakeswap
    id++;
  }

  function refund(address _receiver) external payable onlyOwner {
    payable(_receiver).transfer(msg.value);
    emit RefundETH(_receiver, msg.value); // price - cost of ethereum in busd from pancakeswap
  }

  function pauseSale() external onlyOwner {
    saleActive = false;
  }

  function unpauseSale() external onlyOwner {
    saleActive = true;
  }
  
  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  // Withdraw all the balance from the contract
  function withdrawAll() external onlyOwner {
    withdrawCurrency(address(this).balance);
  } 
}