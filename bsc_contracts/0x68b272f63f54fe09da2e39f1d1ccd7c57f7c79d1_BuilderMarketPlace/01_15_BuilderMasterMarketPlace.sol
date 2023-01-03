// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./MarketPlaceMain.sol";

/*
  ____            _   _       _                   _        ___  
 | __ )   _   _  (_) | |   __| |   ___   _ __    / |      / _ \ 
 |  _ \  | | | | | | | |  / _` |  / _ \ | '__|   | |     | | | |
 | |_) | | |_| | | | | | | (_| | |  __/ | |      | |  _  | |_| |
 |____/   \__,_| |_| |_|  \__,_|  \___| |_|      |_| (_)  \___/ 
                                                     Tokenbank
 ______    ____       ______      __  __      __  __     
/\__  _\  /\  _`\    /\  _  \    /\ \/\ \    /\ \/\ \    
\/_/\ \/  \ \ \L\ \  \ \ \L\ \   \ \ `\\ \   \ \ \/'/'   
   \ \ \   \ \  _ <'  \ \  __ \   \ \ , ` \   \ \ , <    
    \ \ \   \ \ \L\ \  \ \ \/\ \   \ \ \`\ \   \ \ \\`\  
     \ \_\   \ \____/   \ \_\ \_\   \ \_\ \_\   \ \_\ \_\
      \/_/    \/___/     \/_/\/_/    \/_/\/_/    \/_/\/_/

   /\   /\   
  //\\_//\\     ____      🦊✅ 
  \_     _/    /   /      🦊✅ 
   / * * \    /^^^]       🦊✅ 
   \_\O/_/    [   ]       🦊✅ 
    /   \_    [   /       🦊✅ 
    \     \_  /  /        🦊✅ 
     [ [ /  \/ _/         🦊✅ 
    _[ [ \  /_/    

*/
contract BuilderMarketPlace {

  MarketPlaceMain public NFTmarketPlace;
  uint256 public _price;
  address public _adminWallet;

  //start
  constructor() {
    _adminWallet = 0x528bf9D459e6EB6f60DA063eF0D5d651bA27D04C;
  }
  
  //receiver
  receive() external payable {}

  // Admin
  function setPrice(uint256 price) external { 
    require (_adminWallet == msg.sender,"Admin error");
    _price = price; 
  }
  function setAdminWallet(address adminWallet) external { 
    require (_adminWallet == msg.sender,"Admin error");
    _adminWallet = adminWallet;
  }

  //Send to constructor queue Builder Token
  function sendToQueue(
      address propWallet_
      ) payable external {
      require (msg.value == _price,"No pay");
      payable(_adminWallet).transfer(address(this).balance);
      NFTmarketPlace = new MarketPlaceMain(propWallet_);
  }

 

}