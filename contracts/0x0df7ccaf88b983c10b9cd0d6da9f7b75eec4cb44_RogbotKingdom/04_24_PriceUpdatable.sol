// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 

abstract contract PriceUpdatable is Ownable {

    uint256 public price = 0 ether;

    // update price
    function updatePrice(uint256 _newPrice)
        external
        onlyOwner
    {
        price = _newPrice;
    }
    

}