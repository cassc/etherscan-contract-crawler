// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Puppet.sol";
import "./values.sol";

//              ..              ';;,'.;.          ,,               
//              .'...           ,d:,'..        ...'                
//                 ..          'YYOd,          ..                  
//                        ..   .;:oY,    .'...                     
//            ,:.                     .'      ..   ....            
//     .,.  ...::,dd,::,;dd;. :YYYYYYo:..dYdYddd,ddd;        ..    
//      ;d:dYodOY00YYYYYTTTT0YYTTTTTTTTOYTTTTY0YO0T0do:,.';,..     
//      .::dYododdYYYYO0YYYTTTYTTYTTTYTYTTTTYO0OYdYYO0dddd,.  ..   
//      .,.';dddY:'',d0YTYYYTTYYTTTTYYYYTYYT0YYYd;;ddod:d:'..      
//      ....'';dd. ..d0YYYYYTYY0OO0YOYYYYY00YOdd;..,,;;d:'...      
//        ...';:,  'ddodd000YOYYodddddoooYYdoodoY:...'......       
//            ,d'   ,d:dddodd:'.;;. ....:d,,;do:..   ..            
//            .,.      ..;dd:d:ddd,'':odo::d:'.      ..            
//         ....'.         ...;;;do:',:;,:...        .'.'.          
//           .';'    ,Yd;.      .....      .:dOd    ...'.          
//          ':,'...  .dYYYY: ..        ...dYYYd.   ....::..        
//          'Yd.......  .,,.   .ddd::'    .,.   ...,'..d:..        
//          :o.  ......  ..',..oYTYYYd;.......''..... .:;.         
//        ....         ...,;:,':::ddd;';,'';;,;. ..       ..       
//        ..           ..   .';..    ..'.... ..            .       
//                       .  .. ......  ..                          
//          ..                                                     
//           .                                  ..      ..         
//                       .      ..       ..                        
//              .. ..         ....                                 
//             ...                                                 
//           ..'.                .                     ..   .'...  
//         .,'.            ..                          '....oOd;:. 
//       .',.            ..            .   ..         .'.,;..;o:'. 
//     .,,'..                               ..           .:..,;... 
//    .'....        .'.                    ... ..                  
//   ,,....         .'.                    ...,,'             
    
// Seppuku is an ancient geometrical form;  
contract Ghost is Puppet, Sacrifice {

    event Seppuku(address token, uint samuraiId, uint spiritId);
    mapping(uint => uint) private _commits;
    Hand private _samurai;

    function seppuku(uint samuraiId) external {
        // Transfer your samurai to the ghost;
        address you = msg.sender;
        address ghost = address(this);
        _samurai.transferFrom(you, ghost, samuraiId);

        //  Mint a spirit in return;
        uint spiritId = _mint(msg.sender);
        _commits[spiritId] = block.number;

        // Seppuku;
        emit Seppuku(address(_samurai), samuraiId, spiritId);
    }

    function lastCommit(uint spiritId) external view returns (uint) {
        return _commits[spiritId];
    }

    constructor(address origin, Hand samurai, string memory baseURI) Puppet(
        "GHOST", 
        "GHOST",
        origin,
        baseURI
    ) { _samurai = samurai; }
}