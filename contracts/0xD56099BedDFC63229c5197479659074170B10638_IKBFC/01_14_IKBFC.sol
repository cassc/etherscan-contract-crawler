// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//   , ,  , ,-.  ,-.  ,-.  
//   | | /  |  )    )    ) 
//   | |<   |-<    /    /  
//   | | \  |  )  /    /   
//   ' '  ` `-'  '--' '--' 
//    FOUNDERS COLLECTION
//                                                                                
//                        *****/                                                  
//                      **,,,,*,**,****/                                          
//                    %#***,,,*,*,**,*****(/////////(#%%                          
//               #%%&     ./*/**,,,,,,*,**((////******///##%%                     
//             %&/              ****,,,,**%%&%///*******///((%%%                  
//           %&&                    *,,,*/(((%%%%%/******////((#%&.               
//          %&.                       ,**/(//////#%******/*////#%%%%              
//          %&                          **((///////*******/////#(#%%&             
//         %&                             (#////////*****//////((#%%&/            
//         %&                              ((/////*/////////(/((##%&&/            
//         %&                               %////////////(((####%&&&&             
//         %%%                               //(/(/(////((####%%%&&@              
//          %&                               &((//(((((/(##%%&&&@@                
//          %%%                               %#(######(#%&&&&@@                  
//           %&                               .%%%%%%%&&%&&&@                     
//            %&                               &&&&&&&&&&@                        
//             %&                               &&&&&&(                           
//              %&                                                                
//               %&                                                               
//                %%%                                                             
//                 %%&                                                            
//                   %%/                                                          
//                    %%&                                                         
//                      %%#                                                       
//                       ,%&                                                      
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract IKBFC is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    
    // Constants
    uint256 public constant TOTAL_SUPPLY = 77;
    
    Counters.Counter private currentTokenId;
    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    
    constructor() ERC721("IKB22 Founders Collection", "IKBFC") {
    baseTokenURI = "";
    }

    
    function mintTo(address recipient) public onlyOwner returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    
    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    } 


    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }  
    

    /** PAYOUT **/
    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }


    /** ROYALTIES **/
    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount)  {
        return (address(owner()), (salePrice * 500) / 10000);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }
      
}