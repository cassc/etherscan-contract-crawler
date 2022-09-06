// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
                                      ..                                                            
                                    #@@@@=                                                          
                               +%@%#@@[email protected]@:                                                         
                              *@@=+%@@* @@@%%%@@@@@%%%##*+=-:                                       
                              [email protected]@@#-.:  -**+=========++*#%@@@@%*=.                                  
                             .+%@@#-                        .-+%@@%=                                
                            [email protected]@%=                               .=%@@+                              
                          .%@@-                                    [email protected]@%:                            
                         [email protected]@%.                                      .#@@:                           
                         %@%                                         .%@@                           
                        [email protected]@:                             :-           :@@+                          
                        @@%                             [email protected]@%.          #@@                          
                       :@@=      .                      [email protected]@@@:         [email protected]@:                         
                       [email protected]@-    -%@@+                    [email protected]@@@@=        [email protected]@-                         
                       [email protected]@@@@@@@@*%@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@=                         
                        --*@@+--   ---=++---------------=+=  :----==*@@*--                          
                          [email protected]@-      .#@@@%-           .#@@@%:       [email protected]@=                            
                          [email protected]@-      %@@@@@@:          %@@@@@@.      [email protected]@=                            
                          [email protected]@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@=                            
                         -*@@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@*-                           
                       [email protected]@@@@=      @@@@@@@-          @@@@@@@:      [email protected]@@@@+                         
                      [email protected]@[email protected]@+     #@*=--+%@.        %@*=--+%@.     [email protected]@[email protected]@+                        
                      *@@  @@#             .                 .      #@@  @@*                        
  =*#%%%%%#+:         .::. :::                                     .=-: :=-.     @@@@@%#=           
  :*@@@%-*@@@.  [email protected]@@@@=   =******+:  :+******=       #@@@@@:  :#%@@@@# :@@@@%#+  @@@%*%@@% :-=+++=  
   [email protected]@@%.:%@@.  =%@@@@=  [email protected]@@@%@@@%  @@@@%@@@@-      [email protected]@@@@:  #@@*[email protected]@@ [email protected]@@[email protected]@@- @@@+ [email protected]@@[email protected]@@=%@@. 
    @@@@@@@@-    *@@@@-  #@@@= @@@@[email protected]@@% *@@@+       #@@@@:  @@@[email protected]@@.*@@% %@@+ @@@%%@@@% %@@**+=: 
    #@@@@@@@@%+. [email protected]@@@-  %@@@- %@@@:[email protected]@@# [email protected]@@*       #@@@@. [email protected]@@[email protected]@@:*@@@.%@@* %@@@@@@+  :#%%@@@# 
    *@@@*.-*@@@@[email protected]@@@-  *@@@[email protected]@@@ :@@@%-#@@@=       *@@@@. [email protected]@@@@@@@:*@@@@@@@* %@@%+-    -*+=:@@# 
    [email protected]@@% [email protected]@@@[email protected]@@@=:.:@@@@@@@@*  #@@@@@@@%.       [email protected]@@@--.=+*####*.=#####*+: %@@*      [email protected]@@%%#= 
    [email protected]@@@@@@@@*: :+++***:   ...        ....           -+++***.                   +**=       .       
    .====--:.                                                                                                                              
                                                                                                                                                   
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BlooLoopsInterface.sol";

contract BlooLoopsRevival is Ownable, ReentrancyGuard {
  using Strings for uint256;

  address public blooLoopsAddress;
  uint256 public maxSupply = 2900;
  uint256 public currentSupply = 2801;
  bool public sleepMachine = false;
  bool public revivalMachine = false;
  bool public publicRevival = false;
  uint256 public publicRevivalPrice = 0.02 ether;

  address public vault;
  address public beneficiary;

  mapping(address => uint256) public sleepDonuts;
  mapping(address => uint256) public revivalDonuts;

  constructor (address _blooLoopsAddress, address _beneficiary, address _vault) {
    blooLoopsAddress = _blooLoopsAddress;
    beneficiary =_beneficiary;
    vault = _vault;
  }

  function setBlooLoopsAddress(address _blooLoopsAddress) public onlyOwner {
    blooLoopsAddress = _blooLoopsAddress;
  }

  function setbeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCurrentSupply(uint256 _currentSupply) public onlyOwner {
    currentSupply = _currentSupply;
  }

  function setPublicRevivalPrice(uint256 _price) public onlyOwner {
    publicRevivalPrice = _price;
  }

  function setSleepMachine(bool _sleepMachine) public onlyOwner {
    sleepMachine = _sleepMachine;
  }

  function setRevivalMachine(bool _revivalMachine) public onlyOwner {
    revivalMachine = _revivalMachine;
  }

  function setPublicRevival(bool _publicRevival) public onlyOwner {
    publicRevival = _publicRevival;
  }

  function getSleepDounts(address _address) public view returns (uint256) {
      return sleepDonuts[_address];
  }

  function addSleepDonuts(address[] memory addresses, uint256 _donuts) public onlyOwner {
    for (uint256 i; i < addresses.length; i++) {
      sleepDonuts[addresses[i]] = _donuts;
    }
  }

  function getRevivalDounts(address _address) public view returns (uint256) {
      return revivalDonuts[_address];
  }

  function addRevivalDonuts(address[] memory addresses, uint256 _donuts) public onlyOwner {
    for (uint256 i; i < addresses.length; i++) {
      revivalDonuts[addresses[i]] = _donuts;
    }
  }

  function sleepBloo(uint256 tokenId) public {
    uint256 donuts = sleepDonuts[msg.sender];

    require(sleepMachine == true, "Sleeping Machine is off");
    require(donuts > 0, "Not enough Sleep Donuts");
    require(currentSupply < maxSupply, "All bloos have been revived");
    sleepDonuts[msg.sender]--;
    BlooLoopsInterface(blooLoopsAddress).transferFrom(msg.sender, vault, tokenId);
    revivalDonuts[msg.sender]++;
  }

  function reviveBloo() public {
    uint256 donuts = revivalDonuts[msg.sender];

    require(revivalMachine == true, "Revival Machine is off");
    require(donuts > 0, "Not enough Revival Donuts");
    require(currentSupply < maxSupply, "All bloos have been revived");

    revivalDonuts[msg.sender]--;
    BlooLoopsInterface(blooLoopsAddress).transferFrom(vault, msg.sender, currentSupply);
    currentSupply++;
  }

  function revivePublicBloo(uint256 count) public payable {
    require(publicRevival == true, "Revival is finished/paused");
    require(currentSupply + count <= maxSupply, "All bloos have been revived");
    require(msg.value == publicRevivalPrice * count, "Insufficient amount");

    for (uint256 i = 1; i <= count; i++) {
      BlooLoopsInterface(blooLoopsAddress).transferFrom(vault, msg.sender, currentSupply);
      currentSupply++;
    }
  }

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }
}