//
//                               ▄▓▓▓▄
//                      ╓▓█▓▄   ▐█╙╙▀██
//                      █╝▄╫█▌  █¡╙▀▀██     ▄██▓█µ
//                     ]▌▄;╫╫█ ]█▀W▄*██    ▄▀▀▄╬██
//                     ╟░┐└╟██ ╫█▄│'╟█▌   ▐▓▄¡v▓█▌
//                     █└╙▀╣██ █░└╙▀▓█─  ]█¡'╙╫██
//                     █W▄,▐██ █╙▀w▄██   ▓.╙▀▄██       ,
//                     ▌││└╙██▐█▄ƒ│:██  #▀▄ƒ¡╠█▌    ▄▓▀██▓
//                     ▌╙▀═▄██╫▒│└╙▀█▌ ▐▌▄¡└╠██   ,█▀;▀▓█▌
//                     █▄ƒ│▐███╙▀▀w╬█▌╒▌│'╙▀▓█─  ▄▀'▀▄██▀
//       ▄▀#╗▄         █¡└╙╙▀██W▄,░▄█▌▌└▀▄▄╬█▌ ▄▒┐▀▄▓██¬
//      ▓╙▓▒▒╬▀▄      █╙▄,,▄█╙¼,└╙▓█▀█▄¡│¼██▄▌'▀▄▄▓█▀
//      ╙█▌▒▒▒╬█     ▌│'▀▄└╫µ│╙▌╙╫││└▌╙▀███└▓;░▓██╙
//       ╙█▌▒▒▒╫█   ▀▌│││╙▀▄▓││└▀╣░╓ⁿ=▀▄▌│╙▄░╙██▀
//        ╙▒▒▒▒▒╟█▄▀│'▀▄│││╙▓▌││░╠██µ  ╙▌│░╙███`
//          ▓▌▒▒▒▒█└││¡▌╙▓▌  ░╙▄│▐████▄ ]╙▌░░▓█⌐
//           █▒▒╠▀.│░▄▀│▐██▌ ]│╙▓███████▌░╙▌▒██
//           █▓▓▀││▄▀.│╓█████▒│¡████████▌░░╬▓██
//           ╫██⌐j▀└│╓▀░█████▓¡▐████████▓░░▓██
//             ██▓▀│¡▓└│▐████▌'▀▓████████╙▌╫▓██
//             ╙██▒▄▀┐│╓#███▀▄▀╙████████▀░▒███
//             ╙██▄∩▄▀└¡└▄▀╙¡│¡╟██████▌▓╟▓██▀
//               ╙███╗,▄#▀─│▄▄▄│╙█████▀░▐▓██▀
//                ╘╬▀▀█▄;┐│'╙╙└││╙╩╩╨▀▓▓╬██▀
//                 ██▌││╫█▓▀▀▀#w▄▄▄▄▄▄╠███¬
//                 █╫▄;¡▓╬░││││││░▀▌▌░░▓█
//                 █▀T╩▀▀▀æ▄▄▄▄,░╟▌▐▒░▄█▀
//                ╚▄¡│╙▀█µ││││└│││╙╙╙╟█▌
//                  ╙▀▀▀▓▄▄▄▄▄▄▄▄▄▓███▀                             
//                    ____                              
//                  ,'  , `.                            
//               ,-+-,.' _ |ғʀᴇᴇ ʜᴀɴᴅ sᴘᴏᴛʟɪɢʜᴛ ,--,    
//            ,-+-. ;   , ||   ,---.      .--.,--.'|    
//           ,--.'|'   |  ;|  '   ,'\   .--,`||  |,     
//          |   |  ,', |  ': /   /   |  |  |. `--'_     
//          |   | /  | |  ||.   ; ,. :  '--`_ ,' ,'|    
//          '   | :  | :  |,'   | |: :  ,--,'|'  | |    
//          ;   . |  ; |--' '   | .; :  |  | '|  | :    
//          |   : |  | ,    |   :    |  :  | |'  : |__  
//          |   : '  |/      \   \  / __|  : '|  | '.'| 
//          ;   | |`-'        `----'.'__/\_: |;  :    ; 
//          |   ;/                  |   :    :|  ,   /  
//          '---'                    \   \  /  ---`-'   
//                                    `--`-'            
//
//                 SPDX-License-Identifier: MIT
//                Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract FHSMoji is ERC721A, Ownable {
    string public _baseTokenURI;

    constructor(string memory baseURI) ERC721A("Free Hand Spotlight Moji", "FHSMJ") {
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