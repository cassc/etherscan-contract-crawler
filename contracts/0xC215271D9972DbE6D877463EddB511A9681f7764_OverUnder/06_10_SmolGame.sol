// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract SmolGame is Ownable {
  address payable public treasury;
  uint256 public serviceFeeWei;

  function _payServiceFee() internal {
    if (serviceFeeWei > 0) {
      require(msg.value >= serviceFeeWei, 'not able to pay service fee');
      address payable _treasury = treasury == address(0)
        ? payable(owner())
        : treasury;
      (bool success, ) = _treasury.call{ value: serviceFeeWei }('');
      require(success, 'could not pay service fee');
    }
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = payable(_treasury);
  }

  function setServiceFeeWei(uint256 _feeWei) external onlyOwner {
    serviceFeeWei = _feeWei;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amountWei) external onlyOwner {
    _amountWei = _amountWei == 0 ? address(this).balance : _amountWei;
    payable(owner()).call{ value: _amountWei }('');
  }

  receive() external payable {}
}