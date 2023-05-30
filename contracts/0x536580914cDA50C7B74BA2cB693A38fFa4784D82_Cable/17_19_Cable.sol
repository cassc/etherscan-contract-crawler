//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./Controller.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

----------------------------------------------------------------------------------------------------

                                                      (                                              
                                                                                                   
        ==-.-               CABLE        
                                                                                           
                                                     t                  ~¬`        ` ~              
  `{¬                                         .      =`                                             
       >²~-,-               Ç       `¬¬ ^`  `ⁿm⌐╙▀║▄,  ╤¬¬                                          
,,,,,,,,,,,,╠▄,,                   ,  ,╓µ#@▓▄▄▄▄▓-╙                                         .'   ,, 
╠╬╬╬╬╬╬╬╠╬╣╬▒╬╩▌              ╓▄▄▓▓█╣╣╢╠╢╣╝╜╙╠░`' .▄≈    ╒¬─ⁿ                         - ô  ,▄▓╬╬╬╬╬L
           -`└▐╟▄            ╩╙╙Ñ└└└       " ▒╬▀^"`'└▀███▄╓e                       <Q▄ ,▄▀▀╠╜╙      
.      ╓#╝²"╠≈^  .         ,█▓╢>▒           ⌠▓─           '%   "╖╖,                ╓╣╬╠╣▌^ /    ` ~ 
ⁿ"^^^║╚,─^          -,   ]½ç-╣Σ▓╦,"╦       ,▓               ▀    ,╫█▀╗     b     ██▀▀╩└ └ ╧  ,,╓-»= 
   ,`/                  ⌠- ╩ª▀╙≈⌐╚¼,\╙╖   . ╣                 ²▀╟▌   ╟▄ {=≡▌╠² .█╬╜%µ ,≈M╙╙--.      
  ƒ^,'                   ..#         ╙%╙µ    ╙▒ε╗╗█wε          ▄╩     ╜▀█▒╢▀└▀╟▀┘` ═╠,      `       
«/;'                      ╠            ╙╟▓ ─     ~ ╘m        N╚─¬    `,       └╩¥K╦.░^"╕  τⁿ~`      
,╓~      ,                 ∩τ          -╬╬        ' ╠        [``              '     '^    "-, ▐   / 
,²,  ─¬ .                   │`[       ,▄╩           ╠        │  /¬¬         .  └  '         │] ,⌐^Γ 
                             ╘       ╩^              %    ┌═ⁿ~¬                 ╚           ╟▀«",¬  
                             ;    ""`                  ~⌐`                       `¬¬¬¬¬~  ,┘`"¬¬~~  
                             `                                                               ¬   '  
                              .                                                                     



----------------------------------------------------------------------------------------------------
  
      
By Joan Heemskerk
Presented by Folia.app
                                    
*/

/// @title CABLE
/// @notice https://cable.folia.app
/// @author @okwme / okw.me, artwork by @joanheemskerk / https://w3b4.net/cable-/
/// @dev standard 721 token and permissions for Minting and Metadata as controlled by external contracts

contract Cable is ERC721Enumerable, Ownable, ERC2981 {
  address public controller;
  address public metadata;
  uint256 public constant MAX_SUPPLY = 545;

  constructor(address controller_, address metadata_) ERC721("Cable", "CBL") {
    controller = controller_;
    metadata = metadata_;
    _setDefaultRoyalty(Controller(controller).splitter(), 1000); // 10%
  }

  /// @dev overwrites the tokenURI function from ERC721 Solmate
  /// @param id the id of the NFT
  function tokenURI(uint256 id) public view override returns (string memory) {
    return Metadata(metadata).getMetadata(id);
  }

  /// @dev mint token
  /// @param recipient the recipient of the NFT
  function mint(address recipient) public {
    require(msg.sender == controller, "NOT CONTROLLER");
    uint256 tokenId = totalSupply() + 1;
    require(tokenId <= MAX_SUPPLY, "MAX SUPPLY REACHED");
    _safeMint(recipient, tokenId);
  }

  function setController(address controller_) public onlyOwner {
    controller = controller_;
  }

  function setMetadata(address metadata_) public onlyOwner {
    metadata = metadata_;
  }

  function setRoyaltyPercentage(address royaltyReceiver, uint96 royaltyPercentage) public onlyOwner {
    _setDefaultRoyalty(royaltyReceiver, royaltyPercentage);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}