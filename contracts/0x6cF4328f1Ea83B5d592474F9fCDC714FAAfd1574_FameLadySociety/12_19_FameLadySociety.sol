// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;

/*
                                                               ....                                                     
                                                         .......';;...                                                  
                                                       ....       ......                                                
                                                    ...''.        ..   ....                                             
                                               ..........        ...   ......                                           
                                            ...'''.   ..         ..    ..   ....                                        
                                          ......'..  ..         ...    ..     ....                                      
                                      ................          ..     ..        .'....                                 
                                   ...'.....'.........          ..     ..         ..  ...                               
                                ..''......'..........          ..     ...         ...   ...                             
                            ....'''......'..........           ..     ...          ..     ...                           
                         ...............'...........          ..      ...          ..       ..                          
                       ........'..................'.          ..      ...          ..        ...                        
                     .........'...................'.          ..      ...          ..         .....                     
                    .........'......................          ..      ...          ..         ... ...                   
                  .........''........'.............           ..       ..          ..          ..   ...                 
                 ...  .....'........'..............           ..       ..          ..          ..     ...               
                ...   ....'.........'.......... ..           ...       ..          ..          ...      ..              
                ..    .............'..........  ..           ..        ..          ..           ..       ..             
               ..      .'..........'.........  ..            ..        ..          ..           ..        ..            
              ..      ..'...................   ..           ...        ..          ..           ..        ..            
             ..       ............'........    ..           ...        ...         ..           ..        ..            
             ..       ............'.......     ..           ...         ..         ..           ..        ..            
            ..        ............'......     ...          .'.          ..        ...           ..        ..            
            ..       ............''......     ..           .'.         ..         ..           ...        ..            
            ..       ............'....        ..           .'.         ..         ..           ..         ..            
           ...      .............'.           ..           .'.         ..         ..           ..         ..            
            ..      .'.......   ...           ..           .'.         ..         ..           ..         ..            
            ..     ........     ..           ..            ....        ..         ...          ..         .             
            ..    ...'..        ..           ..             ...        ..          ..          ..         .             
            ..    ...'.         ..           ..              ..        ..          ..          ..         .             
            ..      ...         ..           ..                        ..          ..          ..         .             
            ..       ..         ..          ..    .':cllc;,...         ...         ..          ..         ..            
            ..      ...         ..             .'codddddoolcc:;'...     ..         ..           ..       ...            
            ..      ..          ..           .,clllcccccccccllloddo:'.....         ..           ..  .';:;;,.            
           ..      ..           ..        .,:clllllloodddddddddddddddlc:;;,..       .           .,:coddddddc.           
           ..     ..            ..      .;lddddddddddddddddddddddddddddolcldol:;'..          .':lddddddddddc.           
          ..     ..            ..      'ldddollooollllc:;;,''......',;coddllodddddoc:;,,,,,,:ldoc;,''',;:cl:.           
         ...     ..            ..     ,odddl:............',;;,..''..   .,cdoooddddddddddddodo:'.          ..            
          ..     ..            ..    .ldddddoc,.  .coxOKXNWXOdlOXKkxxd,. .'ldodddddddddddddc..':oc;lkOkxl'''.           
          ..    ...            ..    ;dddddddddoc;oKMMMMMMMk;lKW0:..;O0:co,.:ooddddddddddl;'ckXWNdkWKc,:Okdx,           
          ..    ..             ..   .:ddddddddddddoo0WMMMMMk;lKW0,  'O0lkMXx;:oddddddddddcc0WMMMXdOWk. .xOdc.           
          ..    ..             ..    'oddddddddddddooxKWMMMN0xoONXOkOkoxNMWNkclddddddddddoxXWMMMWOd0N0kOOdxc            
          ..    ..             ..     ;ddddddddddddddoldOKWMMW0xxkkxdoxOOkxdoodddddddddddoclxk0XWWKkkkkkkOx'            
          ...   ...            ..      ,odddddddddddddolclodddxxxoololllloddddddddddddddddlcoollodkkkkxxxoc.            
           ..    ..            ...     .,oddddddddddddddddoollcclllooodddddddddddddddddddddlldddoolccccclol'            
           ..    ..             ..     . 'cddddddddddddddddddddddddddddddddddddddoollllloddollodddddddddddo'            
           ..     ..            ..        .,ldddddddddddddddddddddoollll::;;,,'.....  ...'';;;:lodddddol:;.             
           ...     ...          ...         .':loodoollc:;;,,''...... ..                ...    ...',,'..                
           ...      ...          ..       ..    ......    ...         ..                 ...       .......              
            ...       ...         ..         ...           ..         ..                  ..       ..    ...            
              ...       ..        ...         ...          .'.        ..                  ..       ...    ..            
               ....      ...       ...         ..          .'.        ..                  ..        ..     ..           
                  ...     ...       ...        ...         .'.        ..                 ...       .'.     .            
                     ..     ..       ...       ...        ....        ..                ...        .'.    ..            
                      ..     ..       ..       ...        ...         ..                          .'.    ..             
                        ..   ...      ..       ..         ..          ..            ....'''.      ..    ..              
                        ..    ..      ..       ..         ..          ..       .';:clodddddoc'.   ...  ..               
                        ..    ...     ..       ..         ..         ...    .;codddddddddlllllc,.  ..  ..               
                        ..     ..      ..      ...        ..         ..    ,odddddddooooooodooool:......                
                       .....   ..      ..      ...        ...        ..   'odddddocccclooooollllll'.....                
                       .  ... ..      ...       ..        ....       ..  .colccclccloooddddddoodo;...'.                 
                            ....      ..        ..         .'.        .. ,oc:clodddolloooooooooo:. ..'.                 
                             .'.     ..         ..         .'.        .. .:ddddddddddooooooooooc. ....                  
                             .'.    ...          ..        ....       ..   ,odddddddddddddddddo, .....                  
                             ....   ..          ...        ...        ..    .;lodddddddddddddo;......                   
                       ..    ..  . ...          ..         .'.       ..        .',;::::::;;,.. .....                    
                     ..','.  ..   ....         ..         ...        ..                        .'..                     
                      ...''.....   ..          ..        ...         ..                ..     .'..                      
                          .''..    .'.        ...        ..         ..                 ..     ...                       
                          ..'.     ....       ..        .'.         ..                 ..    ...                        
                          .. ...   ...        ..       .'.         ..                  ..    ..                         
                         ..   ...  ..         ..       .'.         ..                  .                                
                         ..     .....        ..       .'.         ...                                                   
                        ..       ...         ..       ...         ..                                                    
                         .        ..         ..      .'.          ..                                                    
                         .       ....        ..      .'.          ..                                                    
                                 ..          ..      ..           ..                                                    
                       ..        ..         ..       ..           ..    .                                               
*/

import {WrappedNFT} from "./WrappedNFT.sol";

contract FameLadySociety is WrappedNFT {
    constructor(
        string memory name,
        string memory symbol,
        address nftContract,
        address tokenRenderer
    ) WrappedNFT(name, symbol, nftContract, tokenRenderer) {}
}