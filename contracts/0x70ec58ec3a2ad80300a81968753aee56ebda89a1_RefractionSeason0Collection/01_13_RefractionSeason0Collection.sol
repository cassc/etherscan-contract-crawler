// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/*
 
               
     ..      ...           ..      .         .....               ..      ...          ..                    ...              .....              .....     .          ....              ...     ...     
  :~"8888x :"%888x      x88f` `..x88. .>  .H8888888x.  '`+    :~"8888x :"%888x     :**888H: `: .xH""     xH88"`~ .x8X     .H8888888h.  ~-.    .d88888Neu. 'L     .x~X88888Hx.       .=*8888n.."%888:   
 8    8888Xf  8888>   :8888   xf`*8888%  :888888888888x.  !  8    8888Xf  8888>   X   `8888k XX888     :8888   .f"8888Hf  888888888888x  `>   F""""*8888888F    H8X 888888888h.    X    ?8888f '8888   
X88x. ?8888k  8888X  :8888f .888  `"`    8~    `"*88888888" X88x. ?8888k  8888X  '8hx  48888 ?8888    :8888>  X8L  ^""`  X~     `?888888hx~  *      `"*88*"    8888:`*888888888:   88x. '8888X  8888>  
'8888L'8888X  '%88X  88888' X8888. >"8x  !      .  `f""""   '8888L'8888X  '%88X  '8888 '8888 `8888    X8888  X888h       '      x8.^"*88*"    -....    ue=:.   88888:        `%8  '8888k 8888X  '"*8h. 
 "888X 8888X:xnHH(`` 88888  ?88888< 888>  ~:...-` :8L <)88:  "888X 8888X:xnHH(``  %888>'8888  8888    88888  !88888.      `-:- X8888x                :88N  ` . `88888          ?>  "8888 X888X .xH8    
   ?8~ 8888X X8888   88888   "88888 "8%      .   :888:>X88!    ?8~ 8888X X8888      "8 '888"  8888    88888   %88888           488888>               9888L   `. ?888%           X    `8" X888!:888X    
 -~`   8888> X8888   88888 '  `8888>      :~"88x 48888X ^`   -~`   8888> X8888     .-` X*"    8888    88888 '> `8888>        .. `"88*         uzu.   `8888L    ~*??.            >   =~`  X888 X888X    
 :H8x  8888  X8888   `8888> %  X88!      <  :888k'88888X     :H8x  8888  X8888       .xhx.    8888    `8888L %  ?888   !   x88888nX"      . ,""888i   ?8888   .x88888h.        <     :h. X8*` !888X    
 8888> 888~  X8888    `888X  `~""`   :     d8888f '88888X    8888> 888~  X8888     .H88888h.~`8888.>   `8888  `-*""   /   !"*8888888n..  :  4  9888L   %888> :"""8888888x..  .x     X888xX"   '8888..: 
 48"` '8*~   `8888!`    "88k.      .~     :8888!    ?8888>   48"` '8*~   `8888!`  .~  `%88!` '888*~      "888.      :"   '    "*88888888*   '  '8888   '88%  `    `*888888888"    :~`888f     '*888*"  
  ^-==""      `""         `""*==~~`       X888!      8888~    ^-==""      `""           `"     ""          `""***~"`             ^"***"`         "*8Nu.z*"           ""***""          ""        `"`    
                                          '888       X88f                                                                                                                                              
                                           '%8:     .8*"                                                                                                                                               
                                              ^----~"`                                                                                                                                                 
       ...               ..      .          ..                     ...                 ....              ...     ...                                                                                   
   .x888888hx    :    x88f` `..x88. .>   :**888H: `: .xH""     .x888888hx    :     .x~X88888Hx.       .=*8888n.."%888:                                                                                 
  d88888888888hxx   :8888   xf`*8888%   X   `8888k XX888      d88888888888hxx     H8X 888888888h.    X    ?8888f '8888                                                                                 
 8" ... `"*8888%`  :8888f .888  `"`    '8hx  48888 ?8888     8" ... `"*8888%`    8888:`*888888888:   88x. '8888X  8888>                                                                                
!  "   ` .xnxx.    88888' X8888. >"8x  '8888 '8888 `8888    !  "   ` .xnxx.      88888:        `%8  '8888k 8888X  '"*8h.                                                                               
X X   .H8888888%:  88888  ?88888< 888>  %888>'8888  8888    X X   .H8888888%:  . `88888          ?>  "8888 X888X .xH8                                                                                  
X 'hn8888888*"   > 88888   "88888 "8%     "8 '888"  8888    X 'hn8888888*"   > `. ?888%           X    `8" X888!:888X                                                                                  
X: `*88888%`     ! 88888 '  `8888>       .-` X*"    8888    X: `*88888%`     !   ~*??.            >   =~`  X888 X888X                                                                                  
'8h.. ``     ..x8> `8888> %  X88!          .xhx.    8888    '8h.. ``     ..x8>  .x88888h.        <     :h. X8*` !888X                                                                                  
 `88888888888888f   `888X  `~""`   :     .H88888h.~`8888.>   `88888888888888f  :"""8888888x..  .x     X888xX"   '8888..:                                                                               
  '%8888888888*"      "88k.      .~     .~  `%88!` '888*~     '%8888888888*"   `    `*888888888"    :~`888f     '*888*"                                                                                
     ^"****""`          `""*==~~`             `"     ""          ^"****""`             ""***""          ""        `"`                                                                                  
                                                                                                                                                                                                       
                                                                                                                                                                                                       
                                                                                                                                                                                                       
                       ..      .          ..      ...             ....                                                                                                                                 
   :~"""88hx.       x88f` `..x88. .>   :~"8888x :"%888x       .x~X88888Hx.                                                                                                                             
 .~      ?888x    :8888   xf`*8888%   8    8888Xf  8888>     H8X 888888888h.                                                                                                                           
 X       '8888k  :8888f .888  `"`    X88x. ?8888k  8888X    8888:`*888888888:                                                                                                                          
   H8h    8888X  88888' X8888. >"8x  '8888L'8888X  '%88X    88888:        `%8                                                                                                                          
  ?888~   8888   88888  ?88888< 888>  "888X 8888X:xnHH(`` . `88888          ?>                                                                                                                         
   %X   .X8*"    88888   "88888 "8%     ?8~ 8888X X8888   `. ?888%           X                                                                                                                         
   .-"``"tnx.    88888 '  `8888>      -~`   8888> X8888     ~*??.            >                                                                                                                         
  :~      8888.  `8888> %  X88!       :H8x  8888  X8888    .x88888h.        <                                                                                                                          
  ~       X8888   `888X  `~""`   :    8888> 888~  X8888   :"""8888888x..  .x                                                                                                                           
 ...      '8888L    "88k.      .~     48"` '8*~   `8888!` `    `*888888888"                                                                                                                            
'888k     '8888f      `""*==~~`        ^-==""      `""            ""***""                                                                                                                              
 8888>    <8888                                                                                                                                                                                        
 `888>    X888~                                                                                                                                                                                        
  '"88...x8""                                                                                                                                                                                          
      ...                  ....               ...            ...            ..      .           ...              .....              .....     .          ....              ...     ...                 
   xH88"`~ .x8X        .x~X88888Hx.       .zf"` `"tu     .zf"` `"tu      x88f` `..x88. .>    xH88"`~ .x8X     .H8888888h.  ~-.    .d88888Neu. 'L     .x~X88888Hx.       .=*8888n.."%888:               
 :8888   .f"8888Hf    H8X 888888888h.    x88      '8N.  x88      '8N.  :8888   xf`*8888%   :8888   .f"8888Hf  888888888888x  `>   F""""*8888888F    H8X 888888888h.    X    ?8888f '8888               
:8888>  X8L  ^""`    8888:`*888888888:   888k     d88&  888k     d88& :8888f .888  `"`    :8888>  X8L  ^""`  X~     `?888888hx~  *      `"*88*"    8888:`*888888888:   88x. '8888X  8888>              
X8888  X888h         88888:        `%8   8888N.  @888F  8888N.  @888F 88888' X8888. >"8x  X8888  X888h       '      x8.^"*88*"    -....    ue=:.   88888:        `%8  '8888k 8888X  '"*8h.             
88888  !88888.     . `88888          ?>  `88888 9888%   `88888 9888%  88888  ?88888< 888> 88888  !88888.      `-:- X8888x                :88N  ` . `88888          ?>  "8888 X888X .xH8                
88888   %88888     `. ?888%           X    %888 "88F      %888 "88F   88888   "88888 "8%  88888   %88888           488888>               9888L   `. ?888%           X    `8" X888!:888X                
88888 '> `8888>      ~*??.            >     8"   "*h=~     8"   "*h=~ 88888 '  `8888>     88888 '> `8888>        .. `"88*         uzu.   `8888L    ~*??.            >   =~`  X888 X888X                
`8888L %  ?888   !  .x88888h.        <    z8Weu          z8Weu        `8888> %  X88!      `8888L %  ?888   !   x88888nX"      . ,""888i   ?8888   .x88888h.        <     :h. X8*` !888X                
 `8888  `-*""   /  :"""8888888x..  .x    ""88888i.   Z  ""88888i.   Z  `888X  `~""`   :    `8888  `-*""   /   !"*8888888n..  :  4  9888L   %888> :"""8888888x..  .x     X888xX"   '8888..:             
   "888.      :"   `    `*888888888"    "   "8888888*  "   "8888888*     "88k.      .~       "888.      :"   '    "*88888888*   '  '8888   '88%  `    `*888888888"    :~`888f     '*888*"              
     `""***~"`             ""***""            ^"**""         ^"**""        `""*==~~`           `""***~"`             ^"***"`         "*8Nu.z*"           ""***""          ""        `"`                
                                                                                                                                                                                                       
                                                                                                                                                                                                       
                                                                                                                                                                                                       
                                                                                                                                                                                 
                                                                                                                                                             
*/

contract RefractionSeason0Collection is ERC1155, Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public totalSupply;
    uint256 public totalMinted = 0;
    mapping(uint => string) public tokenURI;
    string public tokenName;
    string public tokenSymbol;
    bool public paused = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply
        
        
    ) ERC1155("") {
            tokenName = _tokenName;
            tokenSymbol = _tokenSymbol;
            totalSupply = _totalSupply;           
    }  


    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
        require((getTotalMinted() + (receivers.length * mintNumber)) <= totalSupply, "MINT_TOO_LARGE");
        require(!paused, 'CONTRACT_PAUSED');
         // not possible to cast between fixed sized arrays and dynamic size arrays so we need to create a temp dynamic array and then copy the elements
        uint256[] memory ids  = new uint256[](7);
        ids[0] = 1; ids[1] = 2; ids[2] = 3; ids[3] = 4; ids[4] = 5; ids[5] = 6; ids[6] = 7; 
        uint256[] memory amounts  = new uint256[](7);
        amounts[0] = mintNumber; amounts[1] = mintNumber; amounts[2] = mintNumber; amounts[3] = mintNumber; amounts[4] = mintNumber; amounts[5] = mintNumber; amounts[6] = mintNumber;
        for (uint256 i = 0; i < receivers.length; i++) {
            totalMinted += mintNumber;
             _mintBatch(receivers[i], ids, amounts, "");
        }
        
    }

    function setURI(uint _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }

    function getTotalMinted() public view returns(uint256){
        return totalMinted;
    }
    
    function getTotalSupply() public view returns(uint256){
        return totalSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }
 
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {  
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}