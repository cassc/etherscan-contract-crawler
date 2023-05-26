// SPDX-License-Identifier: Unlicensed
/*
                                   .......                               .            .         .°°. 
     °*******°       ..          °*ooooOOoo°.   .°*°    .*°.     °°. O     .°..   .  *oo° °     oOOo 
   .*ooOOOOOOoo. o  °oo° #. °*.  .*ooo°.°ooO*   °OOO° . *OOo   .*oO* #   .°oOOo*.    OoO°     ° oOoo 
   .oooo°...°oo.   °ooo.   .ooo°   *oo   .oo*   .ooo.   *ooo   °Ooo*  # °oooooooo*   oooo°      oooo 
   .ooo°     *° . .ooo.  o  ooo°   *oo*.*o**.   .ooo.   *ooo   .*ooo.  °ooo*..*ooo.  °oooo°   .oooo* 
    .°oo°.        oooo      ooo.   *ooo°oo..    .oo°   *oooo    .ooo° .*oo°   .oooo    .*oo***oo**o  
       .****°°.   *oo*      o*o.  .*o*°°oooo°   .oo*  .*oooo*   .ooo° °ooo****oooo*      °oooooo.*o  
          .*oo.    *o*.   °**o*.  °oo.    °oo°   °oo**ooo**oo*.°**oo° °o*oo*. °ooo*       °o*oo. **  
 ....       °**.   °******o***.   °**.     *o*   .***oo*°  **ooooo*.  °o**.    ****     .°**o*°  °   
 ******°°°°°**°     .*******°     °***°°°°***.    .***°     *****.    °o*o.    ****   .°*o**°    °   
  .**********°        ......      ..°*****...                 .°       °*°     ****  .****°.     °   
      ..°°.                                                                     ..     .         °   
        ..   ..    ..........               .                            .                       ° .   
        ..      .°°°°°°°..°°°°.           .°°°...      .......   .....      ..°°°°°..                
                .°°°°°°    .°°°.       .°°°°°°°°°°.  .°°°°°°°°°°°°°°°°°   .°°°°°..°°°°  .            
                   °°°°     .°°.      °°°°°    .°°°.  .°°°°°°°°°°°°°°.°. °°°°°                       
                   °°°°    .°°.      .°°°°°    .*°*°    .°   °°°°°    .. .°°°°.                      
                   °****°°°**°       °******°.°°**°*.    °    °**°  . ..  °***°..                    
                    °*********°°.    °**************° .  .    ***°         .°°***°°..                
                    °****°.°.°***°   .****.    .°****. .   .  ***°  °    .     .*****°               
                    °***°      .°*°   °***      .****°        ***°               ****°               
                    °****        °**. °***       °****.      °**°        °°°    °****.               
                    °.***°       °**.  °*. .     .*****      ***°       °o**********°                
                    ° .*o°         .    .          °**°      .*.      o .°°*o****°..                 
                    *   ..                           °.                     ...*                     
                    °                                °.                        °                     
                                                     °.                        .                     
                                                     .                                                                                                                                            
*/
pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract SubwayRatsNYC is ERC721AQueryable, Ownable {

    constructor() ERC721A("SubwayRatsNYC", "SRNYC") {}
   
    string public baseURI = "https://subwayrats.io/api/land/";

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function landMint(uint amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
}