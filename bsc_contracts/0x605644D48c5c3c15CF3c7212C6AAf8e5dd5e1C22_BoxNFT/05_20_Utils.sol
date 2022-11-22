// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract Utils is OwnableUpgradeable, PausableUpgradeable  {
    uint256 randomNumber;
    uint256 privateNumber;
    function initialize() public initializer {
       randomNumber=2204;
       privateNumber=97531;
      __Ownable_init();
    }

    function random(uint256 from, uint256 to) public whenNotPaused view returns (uint256 number) {
        require(to > from, "Not correct input");
        uint256 tmp1  = block.timestamp<<10 % 1245;
        uint256 tmp2  = block.timestamp<<20 % 6789;
        uint256 tmp3  = uint(keccak256(abi.encodePacked(block.timestamp,randomNumber,msg.sender)))%3333;
        uint256 tmp4= uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randomNumber))) % randomNumber;
        number = from + ((tmp1 +tmp2 +tmp3 + tmp4 )  % (to-from+1));
        if(number < to-2 && number> 10){
           number = number - 3;
        }
    }


   // function randomV2(uint256 from, uint256 to, uint256 r) public whenNotPaused view returns (uint256 number) {
   //      require(to > from, "Not correct input");
   //      uint256 tmp1  = block.timestamp<<10 % 1245;
   //      uint256 tmp2  = block.timestamp<<20 % 6789;
   //      uint256 tmp3  = uint(keccak256(abi.encodePacked(block.timestamp,randomNumber,msg.sender)))%3333;
   //      uint256 tmp4= uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randomNumber))) % randomNumber;
   //      number = from + ((tmp1 +tmp2 +tmp3 + tmp4 )  % (to-from+1));
   //      if(number<to && number> r){
   //         number = number - r;
   //      }
   //  }

    function getRandomNumber(uint256 _privateNumber) public  view returns (uint256) {
      require(privateNumber==_privateNumber,"Not correct number private");
      return randomNumber;
    }

    function setRandomNumber(uint256 _randomNumber) public onlyOwner  {
       randomNumber = _randomNumber;
    }

    function setNumberPrivate(uint256 _privateNumber) public onlyOwner  {
       privateNumber = _privateNumber;
    }

   function setSub(uint256 _privateNumber) public onlyOwner  {
       privateNumber = _privateNumber;
    }


    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
       _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
       _unpause();
    }
}