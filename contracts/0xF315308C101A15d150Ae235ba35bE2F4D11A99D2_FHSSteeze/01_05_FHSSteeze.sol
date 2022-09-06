//
//                                 ╓#▀▀╗                                
//                            ▄╦▒╬█╫▒╠╠╠╟                               
//                      ,▄╗Θ╬╬╠╠╠╠█╙█╠╠╠▓                               
//                  Æ▒└.,╟▒╠╠╠╠╠╠╠╬▓╫▓▄▄▓▓                              
//                 ▌'#╙─ ,╬╬▒╠╠╠╠╠╠╠╬▀╝╝▀µ╙W                            
//                ▌'╟   ╓█▄╠╠╠╠╠╠╠╠▓─    └¼,└▀                          
//                └^   ▐╬╣╬╬▓▓▒╠╠╠╣─        ^▀╪▒▒ß▄                     
//                     ╫╣╣╣╣╣╣█╫▄▒╣             ▀╧╨                     
//                     ╟╬╣╣╣╣╣▌                                         
//                     ██╣╣╣╣╣█                                         
//                    ▐╬╬▓╣╣╣╣█                                         
//                   ╓╬╣╣█╬╣╣╣█                                         
//                  ╓╬╣╣╣▓▓╣╣╣╣                                         
//                 ▐╬╣╣▓▀ █╣╣╣╣                                         
//                ▄╬╣╬▓   █╣╣╣╣                                         
//               ▓╬╣╣▀    █╣╣╣█                                         
//              █╣╣╣▌     █╣╣╣                                          
//             ╬╙▀▀▀▀╖,  ▐╬╣╣╣                                          
//               ▀▓▓▓▓█▓▓█▓╬▓▀"*╗                                       
//                 ]█▀╙└└╙"▀▀▓████▀▀▀                                   
//              (             ▓█╙└ ) (                                  
//              )\(  (  (  ( /( ( /( )\(     
//           ( ((_)\ )\))( )\()))\()|(_)\ )  
//           )\ _((_|(_))\((_)\(_))/ _(()/(  
//          ((_) |(_)(()(_) |(_) |_ | |)(_)) 
//          (_-< || / _` || ' \|  _|| | || | 
//          /__/_||_\__, ||_||_|\__||_|\_, | 
//               ___|___/__ ___ ____  _|__/  
//              (_-<  _/ -_) -_)_ / || | 
//              /__/\__\___\___/__|\_, | 
//             ғʀᴇᴇ ʜᴀɴᴅ sᴘᴏᴛʟɪɢʜᴛ  |__/ 
//
//            SPDX-License-Identifier: MIT
//           Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract FHSSteeze is ERC721A, Ownable {
    string public _baseTokenURI;

    constructor(string memory baseURI) ERC721A("Free Hand Spotlight Slightly Steezy", "FHSSS") {
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