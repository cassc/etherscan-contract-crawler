// SPDX-License-Identifier: GPL-3.0

/*                     
                   @@@@              @@@@@@@@@(                        
               @@@@@@@@@@@@        @@@@@@@@@@@@@@                      
              @@@@@    @@@@@      @@@@@      @@@@@                     
             @@@@        @@@@     @@@@@      @@@@@                     
             @@@@        @@@@      @@@@@@@@@@@@@@                      
              @@          @@         &@@@@@@@@*                        
                                                                      
                   @@@@                                                
                   @@@@           @@@@        @@@@                     
             @@@@@@@@@@@@@@@@     @@@@       %@@@@                     
              @@@@@@@@@@@@@@       @@@@@@//@@@@@@                      
                   @@@@              @@@@@@@@@@                        
                   @@@@                       


                  Created by no+u @notuart    
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IKongzilla {
  function ownerOf(uint256 tokenId) external view returns (address);
  function walletOfOwner(address owner) external view returns (uint256[] memory);
  function caged(uint256 tokenId) external view returns (uint256);
  function free(uint256 tokenId) external;
}

contract Rage is ERC20, Ownable {
  using SafeMath for uint256;

  uint256 public daily = 100 ether;
  uint256 public cap = 100; // days
  address public nemezisAddress;
  IKongzilla public kongzillaContract;

  constructor (
    address _kongzillaContractAddress
  ) ERC20("Rage", "RAGE") {
    setKongzillaContract(_kongzillaContractAddress);
  }

  function setDaily(uint256 _daily) external onlyOwner {
    daily = _daily;
  }

  function setCap(uint256 _cap) external onlyOwner {
    cap = _cap;
  }

  function setKongzillaContract(address _address) public onlyOwner {
    kongzillaContract = IKongzilla(_address);
  }

  function setNemezisAddress(address _address) public onlyOwner {
    nemezisAddress = _address;
  }

  function gauge(uint256 _tokenId) public view returns (uint256) {
    require ((_tokenId > 0) && (_tokenId <= 6969), "Invalid token");

    uint256 amount = 0 ether;
    uint256 cagedSince = kongzillaContract.caged(_tokenId);
    
    if (cagedSince == 0) {
      return amount;
    }

    uint256 daysCaged = block.timestamp.sub(cagedSince).div(86400);

    if (daysCaged >= cap) {
      daysCaged = cap;
    }

    amount = daysCaged.mul(daily);

    return amount;
  }

  function gaugeAll(address _user) public view returns (uint256) {
    uint256[] memory tokenIds = kongzillaContract.walletOfOwner(_user);
    uint256 total = 0 ether;

    for (uint256 i; i < tokenIds.length; i++) {
      total.add(gauge(tokenIds[i]));
    }

    return total;
  }

  function unleash(uint256 _tokenId) public {
    require (kongzillaContract.ownerOf(_tokenId) == msg.sender, "Wrong owner");

    uint256 amount = gauge(_tokenId);
    kongzillaContract.free(_tokenId);
    _mint(msg.sender, amount);
  }

  function unleashAll() public {
    uint256[] memory tokenIds = kongzillaContract.walletOfOwner(msg.sender);
    uint256 total = 0 ether;
    
    for (uint256 i; i < tokenIds.length; i++) {
      total.add(gauge(tokenIds[i]));
      kongzillaContract.free(tokenIds[i]);
    }
    
    _mint(msg.sender, total);
  }

  function burn(address _from, uint256 _amount) public {
    require (msg.sender == nemezisAddress, "Forbidden");

    _burn(_from, _amount);
  }
}