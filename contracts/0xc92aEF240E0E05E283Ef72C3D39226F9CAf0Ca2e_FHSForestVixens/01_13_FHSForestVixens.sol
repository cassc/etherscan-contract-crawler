//
//                                 µ▄,                                            
//                                ╟▌ ╙█▓▄▄╟╗▄     ╓                               
//                                ▐╬█▓╝█╫██▓╬█▄ ' █⌐                              
//                           ▄▓▓╬╬▓█╫╫██╬█╫╫██╬▓█▄▒▓' ▌                           
//                         .▓╬╣▓▓╣█╣╬╫███▓█╬▓╫█╣█╬█▓██╬▌                          
//                         █▀╙╙╙╙██╬╬███▓█████╬╬▓╬╬██▓╬╫                          
//                       @╬╬╬╬╣█╬█╬█╬█████▓██▓╬╬█╬╬╬╬╬▓▌▄                         
//                       ╙▓╬╠██▓▓█╫█╬╬██▓███▓▓█╬▓█╬╬█╬███▌                        
//                      @▒╬▓╬╣▓▓╫╬╬██╫█╬╬╬╬▓▓╬████▓╬██╣███▓⌐                      
//                    .▓░▒╟███╬█╬╬▀▀╝█╬╬╬╣╬╬▓▓▓██▓█╬█╬█╬███╗⌐                     
//                   ²╙└.'╙^▌╚██│░│'''╙▀█╬╬╬╣█▓██╬╬╬╬╬╬██╬██M╦▓▀                  
//                       ▄#▀█▀██▄░░│     ▀╩╩╙╚█╬╬╣╬╬╬╬▒█╣██╬▌└'                   
//                      █└  ╙▄  ╙█⌐░.▄▄mR█▄▄│░░█╬╬╬╬╬▓█╬█╬█▀*                     
//                     j▌    ╠▌O▄█▄ƒ▓      ╙█µ░░░╠█╣▀▐██╬▌                        
//                      ▀▄ ╓▀┌░.▓▀│╫ O       █▄░░╠▒█░▐╬╬╣                         
//                       └▀███▀▀│░░╙▌░      ╓▀▀░▌╠▒░░░▄▀╙                         
//                        φ▌╠▒▒░░░░░╙▀▄▄▄▄▄▀│φ½╬╫▒░░.█^                           
//                       .╠▌╠▒▒░░░░░░░░│││░░░#▒╠▒░░▓▀                             
//                        ╚╫▒▒▒░░░░░░░░░░░░░▒▒▒╚╓#╙                               
//                         ╙▀▄╡░▒▒░░░▄░░░░░▒▒▄▀╙└                                 
//                          └└▀▓▄▒▒▒░░▒▒φ▄▓╝▀└]▌                                  
//                              .╙╙▀▀▀╙╙└█░░░░▐▒░                                 
//                                      j▌░░░░╙▌                                  
//                                     ╓█░░░░░░▓▄                                 
//                    ,▄▄▄▄▄        .▄▀│░░░░░░░░╙▓▄                               
//             ,▓████▄████████▄, ,▄▀░░░░░░░░░░░░▒░│▀╗µ                            
//            ▐███╜╟╫███████╬██████▒▒▒▒▒▒░░'░░░░▐░▀▄▒╚▀╗▄                         
//                           ғʀᴇᴇ ʜᴀɴᴅ sᴘᴏᴛʟɪɢʜᴛ
//   ________     ,-----.    .-------.        .-''-.    .-'''-.,---------.  
//  |        |  .'  .-,  '.  |  _ _   \     .'_ _   \  / _     \          \ 
//  |   .----' / ,-.|  \ _ \ | ( ' )  |    / ( ` )   '(`' )/`--'`--.  ,---' 
//  |  _|____ ;  \  '_ /  | :|(_ o _) /   . (_ o _)  (_ o _).      |   \    
//  |_( )_   ||  _`,/ \ _/  || (_,_).' __ |  (_,_)___|(_,_). '.    :_ _:    
//  (_ o._)__|: (  '\_/ \   ;|  |\ \  |  |'  \   .---.---.  \  :   (_I_)    
//  |(_,_)     \ `"/  \  ) / |  | \ `'   / \  `-'    |    `-'  |  (_(=)_)   
//  |   |       '. \_/``".'  |  |  \    /   \       / \       /    (_I_)    
//  '---'-.  ,--- '--/`)-'____''-' __`'-'-''-.`'-..-'   `-...-'.-''''---'    
//    |   /  |   |\ .-.')\   _\   /  /.'_ _   \ |    \  |  |  / _     \ 
//    |  |   |  .'/ `-' \.-./ ). /  '/ ( ` )   '|  ,  \ |  | (`' )/`--' 
//    |  | _ |  |  `-'`"`\ '_ .') .'. (_ o _)  ||  |\_ \|  |(_ o _).    
//    |  _( )_  |  .---.(_ (_) _) ' |  (_,_)___||  _( )_\  | (_,_). '.  
//    \ (_ o._) /  |   |  /    \   \'  \   .---.| (_ o _)  |.---.  \  : 
//     \ (_,_) /   |   |  `-'`-'    \\  `-'    /|  (_,_)\  |\    `-'  | 
//      \     /    |   | /  /   \    \\       / |  |    |  | \       /  
//       `---`     '---''--'     '----'`'-..-'  '--'    '--'  `-...-'   
// 
//                      SPDX-License-Identifier: MIT
//                    Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticketed.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();

contract FHSForestVixens is ERC721, Ownable {
    uint256 public nextTokenId = 1;

    string public _baseTokenURI;

    constructor(string memory baseURI) ERC721("Free Hand Spotlight Forest Vixens", "FHSFV") {
        _baseTokenURI = baseURI;
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        uint256 _nextTokenId = nextTokenId;

        for (uint256 i = 0; i < qty; i++) {
            _mint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        nextTokenId = _nextTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = nextTokenId - 1;
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }
}