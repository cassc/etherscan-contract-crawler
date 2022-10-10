pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./Base.sol";

        using SafeMath for uint;

contract DataPlayer is Base{
        struct InvestInfo {
            uint256 id; 
            uint256 amount; 
            uint256 settlementTime; 
             uint256 endTime;
        }

        struct Player{
            uint256 id; 
            address addr; 
            uint256 MiningIncome; 
            InvestInfo[] list; 
            uint256 AllInvestInfo; 

        }



     mapping(uint256 => uint256)  public everydaytotle;

    mapping(uint256 => Player) public _playerMap; 
 
    mapping(address => uint256) public _playerAddrMap; 
    uint256 public _playerCount; 
     
    uint256 public netAlltotle; 
    address public Z_address = address(1); 

    uint256 public oneDay = 60; 


    function getPlayerByAddr(address playerAddr) public view returns(uint256[] memory) { 
        uint256 id = _playerAddrMap[playerAddr];

         uint256[] memory temp = new uint256[](1);

        if(id > 0 ){
        Player memory player = _playerMap[id];
 
        temp[0] = player.MiningIncome;  
            
    
        }
        return temp; 
    }

   function getdayNum(uint256 time) public view returns(uint256) {
        return (time.sub(_startTime)).div(oneDay);
    }
    function getlistByAddr(address playerAddr, uint256 indexid) public view returns(InvestInfo memory  ) { 
        uint256 id = _playerAddrMap[playerAddr];
        InvestInfo memory info = InvestInfo(0, 0, 0, 0);

 
    if(id>0){
        InvestInfo[] memory investList = _playerMap[id].list;
        return investList[indexid]; 

    }else{
 
             return info; 

 }
    
    }

    function getAddrById(uint256 id) public view returns(address) { 
        return _playerMap[id].addr; 
    }
    function getIdByAddr(address addr) public view returns(uint256) { 
        return _playerAddrMap[addr]; 
    }
 
    function setzaddress(address addr) public onlyOwner  { 

            Z_address = addr;

     }
 
}