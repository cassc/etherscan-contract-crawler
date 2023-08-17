// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/*

                    _.---._     .---.
            __...---' .---. `---'-.   `.
  ~ -~ -.-''__.--' _.'( | )`.  `.  `._ :
 -.~~ .'__-'_ .--'' ._`---'_.-.  `.   `-`.
  ~ ~_~-~-~_ ~ -._ -._``---. -.    `-._   `.
    ~- ~ ~ -_ -~ ~ -.._ _ _ _ ..-_ `.  `-._``--.._
     ~~-~ ~-_ _~ ~-~ ~ -~ _~~_-~ -._  `-.  -. `-._``--.._.--''. ~ -~_
         ~~ -~_-~ _~- _~~ _~-_~ ~-_~~ ~-.___    -._  `-.__   `. `. ~ -_~
       jgs   ~~ _~- ~~- -_~  ~- ~ - _~~- _~~ ~---...__ _    ._ .` `. ~-_~
                ~ ~- _~~- _-_~ ~-_ ~-~ ~_-~ _~- ~_~-_~  ~--.....--~ -~_ ~
                     ~ ~ - ~  ~ ~~ - ~~-  ~~- ~-  ~ -~ ~ ~ -~~-  ~- ~-~

          _____                   _______                   _____                   _______         
         /\    \                 /::\    \                 /\    \                 /::\    \        
        /::\    \               /::::\    \               /::\    \               /::::\    \       
       /::::\    \             /::::::\    \             /::::\    \             /::::::\    \      
      /::::::\    \           /::::::::\    \           /::::::\    \           /::::::::\    \     
     /:::/\:::\    \         /:::/~~\:::\    \         /:::/\:::\    \         /:::/~~\:::\    \    
    /:::/  \:::\    \       /:::/    \:::\    \       /:::/  \:::\    \       /:::/    \:::\    \   
   /:::/    \:::\    \     /:::/    / \:::\    \     /:::/    \:::\    \     /:::/    / \:::\    \  
  /:::/    / \:::\    \   /:::/____/   \:::\____\   /:::/    / \:::\    \   /:::/____/   \:::\____\ 
 /:::/    /   \:::\    \ |:::|    |     |:::|    | /:::/    /   \:::\    \ |:::|    |     |:::|    |
/:::/____/     \:::\____\|:::|____|     |:::|    |/:::/____/     \:::\____\|:::|____|     |:::|    |
\:::\    \      \::/    / \:::\    \   /:::/    / \:::\    \      \::/    / \:::\    \   /:::/    / 
 \:::\    \      \/____/   \:::\    \ /:::/    /   \:::\    \      \/____/   \:::\    \ /:::/    /  
  \:::\    \                \:::\    /:::/    /     \:::\    \                \:::\    /:::/    /   
   \:::\    \                \:::\__/:::/    /       \:::\    \                \:::\__/:::/    /    
    \:::\    \                \::::::::/    /         \:::\    \                \::::::::/    /     
     \:::\    \                \::::::/    /           \:::\    \                \::::::/    /      
      \:::\    \                \::::/    /             \:::\    \                \::::/    /       
       \:::\____\                \::/____/               \:::\____\                \::/____/        
        \::/    /                 ~~                      \::/    /                 ~~              
         \/____/                                           \/____/                                  


Words from KERO:
  After Mumu,Bobo,Dodo,Pepe you see where i got the name from. 
  I thought there must be a meme that fits for web 3 and nobody did it before.
  Then it occurred to me a crocodile is just the thing the ultimate predator
  he snaps, flips and drag you under the water...

Join the COCO community! https://t.me/cocomemecoin
View the amazing artwork the community is making: rarecoco.wtf

*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CocoDrop is Ownable {

  constructor() {}

  IERC20 coco = IERC20(0xE6DBeAdD1823B0BCfEB27792500b71e510AF55B3);

  // send it
  function cocodrop(address[] memory addresses, uint[] memory values) public {
    for (uint i = 0; i < addresses.length; i++){
      coco.transferFrom(msg.sender, addresses[i], values[i]);
    }      
  }

  // Contract cannot send its own tokens
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return IERC20(tokenAddress).transfer(msg.sender, tokens);
  }

}