// SPDX-License-Identifier: GPL-3.0

/*                    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@((((((((                @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@    ((((((((                ((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@@    ((((((((                ((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@@                                ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@                                ((((((((@@@@@@@@@@@@
@@@@@@@@((((            ////////////                    @@@@@@@@
@@@@@@@@            ////////////////////                @@@@@@@@
@@@@@@@@            ////////////////////                @@@@@@@@
@@@@@@@@            ////////////////////        ((((((((@@@@@@@@
@@@@@@@@,,,,,,,,    ////////////////////    ((((((((((((@@@@@@@@
@@@@@@@@,,,,,,,,    ////////////////////    ((((((((((((@@@@@@@@
@@@@@@@@@@@@,,,,,,,,    ////////////        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@,,,,,,,,    ////////////        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@,,,,,,,,                        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@@@@@,,,,                            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@,,,,                            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    

        EGGZ, the CryptoPolz and Polzilla utility token.

                Visit https://metapond.io

                
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

interface INFT {
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract Eggz is ERC20, Ownable {
  using SafeMath for uint256;

  // Emission rates
  uint256 constant public FAST = 12 ether;
  uint256 constant public SLOW = 3 ether;
  
  // Time constraints
  uint256 public start;
  uint256 public end;

  // Token burning delegation
  address public eggzillaAddress;
  address public nemezisAddress;

  // Application state
  mapping(uint256 => uint256) private _cryptoPolzHarvests; // Token ID => Day
  mapping(uint256 => uint256) private _polzillaHarvests;   // Token ID => Day

  // Contracts
  INFT public cryptoPolzContract;
  INFT public polzillaContract;

  constructor (
    address cryptoPolzContractAddress,
    address polzillaContractAddress
  ) ERC20("Eggz", "EGGZ") {
    start = block.timestamp.sub(3628800); // 42 days ago
    end = block.timestamp.add(1324512042); // in 42 years and 42 seconds

    cryptoPolzContract = INFT(cryptoPolzContractAddress);
    polzillaContract = INFT(polzillaContractAddress);

    eggzillaAddress = msg.sender;
    nemezisAddress = msg.sender;
  }

  function lastCryptoPolzHarvestByTokenId(uint256 _tokenId) external view returns (uint256) {
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid CryptoPolz ID");

    return _cryptoPolzHarvests[_tokenId];
  }

  function lastPolzillaHarvestByTokenId(uint256 _tokenId) external view returns (uint256) {
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid Polzilla ID");
    
    return _polzillaHarvests[_tokenId];
  }

  function harvestCryptoPolz(uint256 _tokenId) external {
    require (block.timestamp <= end, "Too late");
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid token");
    require (cryptoPolzContract.ownerOf(_tokenId) == msg.sender, "Wrong owner");

    uint256 today = block.timestamp.sub(start).div(86400);
    uint256 amount = today.sub(_cryptoPolzHarvests[_tokenId]).mul(SLOW);

    require (amount > 0, "Empty carton");

    _cryptoPolzHarvests[_tokenId] = today;

    _mint(msg.sender, amount);
  }

  function harvestPolzilla(uint256 _tokenId) external {
    require (block.timestamp <= end, "Too late");
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid token");
    require (polzillaContract.ownerOf(_tokenId) == msg.sender, "Wrong owner");

    uint256 today = block.timestamp.sub(start).div(86400);
    uint256 amount = today.sub(_polzillaHarvests[_tokenId]).mul(SLOW);

    require (amount > 0, "Empty carton");

    _polzillaHarvests[_tokenId] = today;

    _mint(msg.sender, amount);
  }

  function harvestPair(uint256 _tokenId) external {
    require (block.timestamp <= end, "Too late");
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid token");
    require (cryptoPolzContract.ownerOf(_tokenId) == msg.sender, "Wrong owner");
    require (polzillaContract.ownerOf(_tokenId) == msg.sender, "Wrong owner");

    uint256 today = block.timestamp.sub(start).div(86400);
    uint256 amount = today.sub(_polzillaHarvests[_tokenId]).mul(FAST);

    require (amount > 0, "Empty carton");

    _cryptoPolzHarvests[_tokenId] = today;
    _polzillaHarvests[_tokenId] = today;

    _mint(msg.sender, amount);
  }

  function setEggzillaAddress(address _address) external onlyOwner {
    eggzillaAddress = _address;
  }

  function setNemezisAddress(address _address) external onlyOwner {
    nemezisAddress = _address;
  }

  function burn(address _from, uint256 _amount) external {
    require ((msg.sender == eggzillaAddress) || (msg.sender == nemezisAddress), "Forbidden");

    _burn(_from, _amount);
  }
}