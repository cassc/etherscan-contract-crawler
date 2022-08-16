//
//                        ,                                                  
//                       ███     ,,       å██▌                               
//                     ,▄▄█ ,#▓╬╬╠╬▒╠░░▒╠▓ ╙▀▄╓╖╖,                           
//                    ▄╬╬╠╫█╬╬▒▒▒▒▒▒▒▒▒▒Å█δ╬░░▒▒▒░╟µ                         
//                   ⌠╬▒╠▒╠█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓ `~                       
//                  ,█╬▒▒▒▒█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▓     ",                    
//                ,^ ▓╬▒▒▒▒╫▌▒╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒Å▓         %                   
//               ∩    █╬▒▒▒╠█╬╬╬╬╬▒▒▒▒▒▒╠╠╬▒▒▒╬╬╣         └                  
//             ╓      ▓█╬╬▒▒█╬╬▓█▓█▓╬╬╠╬╬▓▓╬╬╬╬▓           ▐                 
//            ╒       █╬▒▒▒▒╫▓█╬╬╬╬╬██▓█▀╠╬╬▀▄              ▌                
//            ┌        ╙█▒▒╠╬╬█╬╬╠╠╠╠╠╠╠▒╠╠╠Å▓╬╕             ╫                
//                      `▀▀█╬█╣▒╠╠╠╠╠╠╬██╠╠╫█▒╟                              
//          ┌              █╬╫▒╠╠╠╠╠╠╠╠█▀▒▒▄█▄▓▄,,,         ┌                
//          ║              ╙█▒▒╠╠╠╠╠╠╠╠╠▀╬╬▒╠╠╠▒▄▓████▄╖,   ▌                
//          ╫               └█▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╣██`▄█████████▓                 
//          ╘                 ▓▌╠╠╠╠╠╠╠╠╠╠╠╠╠██▄████████████                 
//           }                 █╬╠╠╠╠╠╠╠╠╠╠╠╠▒╬███████████                   
//            ╕               ▐█╬╠╠╠▄╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬▓▀                    
//             ¼        , ,,,,█╬╬╠╠╠╬█▓▄▄▒╠╠╠╠╠╠╠▒▒╝╜,Æ                      
//              ^w  ╓@▒     ╒█╬╬╬╠╠╠╠╠▄╓▄▄╠╠^`     ,Θ ,                      
//                ▐╬░      ,█╬╬╬╬╠╠╠╠▌░░╙`  ╙≥╖ ,∞` ∞`                       
//                █░░      ▀█╬╬╬╬╠╠╠╠█░        ╫╓⌐                           
//                 ▒░≥      └█╬╬╬▒╠╠╠█░       ╛▓                             
//                 A▀▄░≥,     ▀█╬╬╬╠╣▌      δ,▀                              
//               ╓▓░░│▀▀▄▒φ»,.  ╙▀╫▓█     µ╗╬│╙▀╗                            
//              ┌█░░░░╚╚╚╩▀▀▓▓▄▄▒░'▀     ╙   `"╚╠╙▌                          
//              ▓░φ"                             ≥▐▌                         
//               `7╧                              '                          
//                   `ⁿⁿ"φ                   "`                              
//             ___    ______   ______                         
//           .'   `..' ____ \ |_   _ `.  ғʀᴇᴇ ʜᴀɴᴅ sᴘᴏᴛʟɪɢʜᴛ                     
//          /  .-.  \ (___ \_|  | | `. \ .--.   .--./) .--.   
//          | |   | |_.____`.   | |  | / .'`\ \/ /'`\;( (`\]  
//          \  `-'  / \____) | _| |_.' / \__. |\ \._// `'.'.  
//           `.___.' \______.'|______.' '.__.' .',__` [\__) ) 
//                                            ( ( __))        
//                   SPDX-License-Identifier: MIT
//                  Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract FHSOSDogs is ERC721A, Ownable {
    string public _baseTokenURI;

    constructor(string memory baseURI) ERC721A("Free Hand Spotlight OS Dogs", "FHSOSD") {
        _baseTokenURI = baseURI;
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        _mint(receiver, qty);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}