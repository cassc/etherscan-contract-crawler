// SPDX-License-Identifier: MIT

/*
 * Super simple on-line wallet
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IOnChainWallet.sol';

contract OnChainWallet is Ownable, IOnChainWallet {
  function deposite() external payable override {
  }

  function withdraw(uint _amount) public override onlyOwner {
    address payable payableTo = payable(owner());
    payableTo.transfer(_amount);
  }

  function withdrawAll() external override onlyOwner {
    withdraw(address(this).balance);
  }

  function transfer(address payable _payableTo, uint amount) public override onlyOwner {
    _payableTo.transfer(amount);
  }

  function transferAll(address payable _payableTo) external override onlyOwner {
    transfer(_payableTo, address(this).balance);
  }
}