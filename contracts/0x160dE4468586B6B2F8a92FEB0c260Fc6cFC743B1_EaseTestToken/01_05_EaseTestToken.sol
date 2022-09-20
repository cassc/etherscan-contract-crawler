/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

                               ................                            
                          ..',,;;::::::::ccccc:;,'..                       
                      ..',;;;;::::::::::::cccccllllc;..                    
                    .';;;;;;;,'..............',:clllolc,.                  
                  .,;;;;;,..                    .';cooool;.                
                .';;;;;'.           .....          .,coodoc.               
               .,;;;;'.       ..',;:::cccc:;,'.      .;odddl'              
              .,;;;;.       .,:cccclllllllllool:'      ,odddl'             
             .,:;:;.      .;ccccc:;,''''',;cooooo:.     ,odddc.            
             ';:::'     .,ccclc,..         .':odddc.    .cdddo,            
            .;:::,.     ,cccc;.              .:oddd:.    ,dddd:.           
            '::::'     .ccll:.                .ldddo'    'odddc.           
            ,::c:.     ,lllc'    .';;;::::::::codddd;    ,dxxxc.           
           .,ccc:.    .;lllc.    ,oooooddddddddddddd;    :dxxd:            
            ,cccc.     ;llll'    .;:ccccccccccccccc;.   'oxxxo'            
            'cccc,     'loooc.                         'lxxxd;             
            .:lll:.    .;ooooc.                      .;oxxxd:.             
             ,llll;.    .;ooddo:'.                ..:oxxxxo;.              
             .:llol,.     'coddddl:;''.........,;codxxxxd:.                
              .:lool;.     .':odddddddddoooodddxxxxxxdl;.                  
               .:ooooc'       .';codddddddxxxxxxdol:,.                     
                .;ldddoc'.        ...'',,;;;,,''..                         
                  .:oddddl:'.                          .,;:'.              
                    .:odddddoc;,...              ..',:ldxxxx;              
                      .,:odddddddoolcc::::::::cllodxxxxxxxd:.              
                         .';clddxxxxxxxxxxxxxxxxxxxxxxoc;'.                
                             ..',;:ccllooooooollc:;,'..                    
                                        ......                             
                                                                      
**/

// Just a quick lil messaround--hope this doesn't inconvenience anyone too much.
// If so, hit up [email protected] and I'll make it up to you somehow.
// Not trying to mess up anyone's day.

contract EaseTestToken is ERC20 {

    address public owner;

    constructor() ERC20("Ease Fun Token", "ease.org") {
        owner = 0xc93356BdeaF3cea6284a6cC747fa52dD04Afb2a8;
        _mint(owner, 1000000000 ether);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from == owner || to == owner, "Only owner may interact with this token."); 
        amount;
    }

}