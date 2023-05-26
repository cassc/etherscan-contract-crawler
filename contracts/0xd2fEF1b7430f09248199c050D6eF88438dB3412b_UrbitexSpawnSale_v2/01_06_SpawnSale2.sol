// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "./interface/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract UrbitexSpawnSale_v2 is Context, Ownable
{

  // This contract facilitates the sale of planets via spawning from a host star.
  // The intent is to be used only by the exchange owner to supply greater inventory to the 
  // marketplace without having to first spawn dozens of planets.

  //  SpawnedPurchase: sale has occurred
  //
    event SpawnedPurchase(
      uint32[] _points
    );

  //  azimuth: points state data store
  //
  IAzimuth public azimuth;

  //  price: fixed price to be set across all planets
  //
  uint256 public price;


  //  constructor(): configure the points data store and planet price
  //
  constructor(IAzimuth _azimuth, uint256 _price)
  {
    azimuth = _azimuth;
    setPrice(_price);
  }

    //  purchase(): pay the price, acquire ownership of the planets
    //

    function purchase(uint32[] calldata _points)
      external
      payable
    {
      // amount transferred must match price set by exchange owner
      require (msg.value == price*_points.length);

      //  omitting all checks here to save on gas fees (for example if transfer proxy is approved for the star)
      //  the transaction will just fail in that case regardless, which is intended.
      // 
      IEcliptic ecliptic = IEcliptic(azimuth.owner());

      //  spawn the planets, then immediately transfer to the buyer
      // 
      
      for (uint32 index; index < _points.length; index++) {
          ecliptic.spawn(_points[index], address(this));
          ecliptic.transferPoint(_points[index], _msgSender(), false);
        }

      emit SpawnedPurchase(_points);
    }


    // EXCHANGE OWNER OPERATIONS 

    function setPrice(uint256 _price) public onlyOwner {
      require(0 < _price);
      price = _price;
    }

    function withdraw(address payable _target) external onlyOwner  {
      require(address(0) != _target);
      _target.transfer(address(this).balance);
    }

    function close(address payable _target) external onlyOwner  {
      require(address(0) != _target);
      selfdestruct(_target);
    }
}