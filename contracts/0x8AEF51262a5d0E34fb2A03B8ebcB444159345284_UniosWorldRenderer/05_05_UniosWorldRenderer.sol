// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
                                                                    . gg,   
                                                                  =,^//KC   
                                                               ,^  ),$$`    
                                                             .`cgg^]$y      
                                 ,,,,                      /,@g$$$p~*       
                            ,[email protected]$%M%%$M$%%%[email protected]@@@@@@C][email protected]$R4L $wg$$,        
                     ,-  **^"""]%F*$$$$$F *jfg$gM5FgP$g,g%@[email protected],}|**"        
           ,l 1l,    N,        [email protected]$&&[email protected]@@@@@ggP%D$$D$]@*]@$MgL   '      
         , ' !i,$iL                  ,         ``                  ~        
       i  < .i\e$FL<|!<s!{s!'gL>,yi.i>,ilxi|ei||[email protected],grN%,,               
   ,,,., . ([email protected]&",}`.M`.;LjTL.M>.'|"/T!'7L|(,*,"]MP*CM%M`=|L,            
  |||@Kl|$W+<i,iW";T|<T!<=!<T!'Tl\s!l=ii4Lrei8($%gmpN"@[email protected]@][email protected]*TL,          
  A"'"*F*%TL T"Q,LQ,i{}i".i*,i*);G"1f"{|21T'*gz$g%$*N$M$Nr2,][email protected]\k~        
]@|     .  +`.1L`$g.|g.{T,,RLGgL$gw1g#{g|UgN$x$Lg$%m"`]`/CN#QM$&@gL>,,      
 '*4gg |<g! T!yF!aR!%!$|gL%AL{R$l&W$4MW|$gR$g&[email protected]@@|@[email protected]&&A$$g$%[email protected]!L     
   4N$g2',$l.il.$f}[email protected]@MM&@[email protected]&$,L$g$%@[email protected]@[email protected]}$$$K$&$g$%gL`.L    
            `   ygR1g$$)$$g$E%N$}l$Q&[email protected][email protected]$g$1l&$%%[email protected]$$WM"`'L      
               ilk$$($'[email protected]*4$*@$][email protected][email protected][email protected]@G)[email protected]@[&%[email protected]@$g[)@&+          
            ,!.|T[[email protected]$Qg$$g&B(iEA$%[email protected]@T%$g][email protected][email protected]@[email protected]        
          ,|<gl\}$%i$%s&gA|Tk$gg$gg$g$MY!URlE}A$k$Lgi%}M%[email protected]@$L       
      ,,;'"1L,1{$QF$$g&1.'  '"}[email protected][email protected][email protected]+    '"'"  ""[email protected][email protected][email protected]@@L       
 +,|"<+6 TL}g$Ug!U4AfA:'`    '"[email protected]$%@$g             |h$%g&%g$%[email protected]@@@       
 $'(l&ki*hM&"i&hi*" `         |[email protected]$&[email protected]             '[email protected]&ET$*%@@@$       
  }}@g"1g]1gL""     | ||    |,,[email protected]@@@$g-              A"|@[email protected]@$}$F '[email protected][email protected]      
                         !')@&$B$%g$`  |'''''''' .Qgh$%&$g&@@P`  : *BC      
                                    `            '"`""'"```` `      `     
*/

contract UniosWorldRenderer is Ownable {
    string public baseURI;

    constructor() {}

    // Render function
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // Owner functions
    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }
}

//[email protected]_ved