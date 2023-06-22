// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/*                                                                                                                                                                                                                                                                              
                                                          ......'''''''''......                                                                                                                                             
                                                     ..',;:clooooooooooooolllc:;,'...
                                                 ..';cloddolc:;,'''.....'''',,;;:ccc:;'... 
                                             ..';cloddlc:,....                  ....',:cc:,...  
                                          ..,:loddoc;'...                              ..';:c:,..   
                                        .';coddoc,...                                      ..;cc:,.    
                                      .,:loddl;'..                                            .,clc;..    
                                    .,:ldxdc,...                                                .;cll:'.    
                                  .,:ldxdc,..                    ..''....                        .'cloo;.     
                                .':loxdl:::;'..                 .,clllccc,.                        .:cloc'.     
                               .;codxo::lolcllc'.               'codc:ccoo;.                        .;cldl'.     
                              ':loxxc';cod:,:lol'              .,coo,';:ldl.                         .:coxl'.     
                             ':ldxd;..,coo;.;ldo,.              'coo;,::ldl..                         .cloxc..     
                            .:loko;.. .;lo:;cldl'.              .'cllccldd;.                          .,cldd;..    
                           .;coxd;...  .';clodl,.                 .';cllc,.                            .:loxl'.     
                           ,clxxc'..      .'''..                   ......                              .,cldd;..    
                          .:loxo,..     .....                    .,::;,,'.                              .:loxc'.     
                         .,clxxc'.     .;clc:;'.                .:lolcccoc.                             .;clxo,..    
                         .:coxo,..    .:ldl;coo:.               ,cod:;:cldc.                             'cldx:..    
                         ,cldxc'.     'cod;.;cdo,.             .,cdo,'::ldl'.                            .:coxl'..    
                        .;coxd;..     .:oo;':ldo,.              .:lo::ccodc.                             .,clxd;..    
                        .cldkl'..      ':lcccddc..               .;clllodl,.                              'cldx:..    
                        ,clxx:..        ..,:lc;..                  .',;;,..                               .:loxl'.     
                       .;clxd;..            ..                                                            .;llxo,..    
                       .:coxo,..               ..                                                          ,cldx:..    
                       'cldxl'..           ..,;;::;;,,'..                                                  .cloxc..     
                      .,cldxc'.         .';coolllllloooc:,..                                               .:loxl,.     
                      .;clxx;..     ..';loolllclllooc;:cloc:;,'..                                          .;clxd;..    
                      .:clxd;..   .';loolc,.;cclooc'.  ..,cllccc:,'..                                       ,cldx:..    
                      .:coxo,....,coooc,.. .,lodl,..      ..;lllcclc:,'..                                   .cloxc'.     
                      .:loxo'',:lool;..     .;:,..           .;lollcclccc,.                                 .:loxo,..    
                      'cloxo;:looc,..                          .':lollcclll:'.                              .;clxd,..    
                      'clodllooc,.                                .';cloollll:'.                             'cldx:..    
                      'ccclooc,.                                     ...;:llllo:..                           .:coxl'.     
                      ,cclol,..                                           .,cllol;.                          .;llxo,..    
                     .:loo:..                                              'coc:oo:..                         ,cldx:..    
                   .,cooc'.                                              .,coc,;lodc'.                        .cloxc'.     
                 ..:lol,..                                              .;loc'.'ccldl,.                       .:loxo,..    
                .,loo:..                                              ..:lo:..  'clldl,.                      .,cldd;..    
               .:loc'.                                              .':coo;.    .,cloxl'.                      'cloxc..     
             .,coo;.                                               .;lool,.      .:lldd:..                     .:clxo,..    
            .;lol,.                                              ..:looc'.        'clldo,.                     .,cldd;..    
          .':oo:..                                              .,coo:'.          .,lloxl'.                     .cloxc'.     
         .;loo;.                                               .;coo;..            .:lldd;..                    .:llxo,..    
       .'cooc'.                                               .;col,.               'cloxl'.                    .,cldd:..    
      .;loo;.                                                .:lol,.                .:cldd;..                    .cloxl'.     
     .:loc'.                                               .,cloc'.                  'ccoxl'.                    .;llxo,..    
    .:oo:..                                              .':coo:..                   .:clxd;..                    ,cldd:..    
   .:oo;.    ...'',,,,,;,,'''......                    .';cool,.                      ,ccdxc'.                    .:loxl'.     
   .cl:,'.',;cloooooooooooooooollc:;,''.........   ...,;cool;..                       .:loxo,..                   .;llxd;..    
   .:oooollllloolc:;;,,,'',;;::ccllooooollc::::;;;;:cloool;..                         .;lldd;..                    'cldx:..    
    .';::cllloooollcc::;;;,,,,,,,;;:cloollllllloooooool:,..                            ,cldxc..                    .:loxl'.     
         ....',;:cclllloooooooooooooooooooooollcc:;,'...                               'ccoxl'.                    .;llxo,..    
                 ....';::cc;;;;;;;;;;;;;,,'.......                                     .:coxo,..                   .,lldd;..    
                     .:lldo,..                                                         .:clxd;..                    'cldxc..     
                     .:lldd;..                                                         .;ccdx:'.                    .:loxl'.     
                     .;lldx:..                                                         .,ccdxc'.                    .;llxo,..    
                     .;lcoxc'.                                                          ,ccoxl'.                     ,cldd:..    
                     'clcoxo'..                                                         'ccoko,..                    'cloxc..     
                    .;clloxd,..                                                         'cclxd,..                    .:loxl'.     
                    'cllclxd;..                                                         .cclxd;..                    .;clxo,..    
                   .;lolcldx:..                                                         .cclxx:..                    .;clxd;..    
                   .:ldocldxc..                                                         .clldx:..                     ,clxx;..    
                  .;coxoccoxl'.                                                         .:lldxc..                     ,cldx:..    
                  .:ldxoccoxl'..                                                        .:lldxc'.                     'cldxc..     
                  'clxdcccoxo,..                                                        .:lldxc'.                     .cldxc'.     
                 .;coxo:cllxd,..                                                        .:llxx:..                     .:loxl'.     
                 .:ldxc;cllxd;..                                                        .:llxx:..                     .:loxl'..    
                 'cldx:,cclxd;..                                                        .:llxx:..                     .:loxo'..    
                 ,clxd;,:cldx:..                                                        .:llxx;..                     .;loxo,..    
                .;coxo,':cldx:..                                                        .:clxx;..                     .;loxo,..    
                .:loxl'':cldx:..                                                        .:clxd;..                     .,coxo,..    
                .:ldxl'':cldxc'.                                                        'ccoxd;..                      ,coxo,..    
                'cldxc.':cldxc'.                                                        'ccoxd,..                      ,coxo,..    
                'cldx:.';cldxc..                                                        'ccoko,..                      ,coxd,..    
                ,clxx;..;cldx:..                                                        ,ccoko,..                      ,clxd,..    
               .,clxd;..;cldxc..                                                        ,llokl'..                      ,clxd,..    
               .,clxd;..;cldx:..                                                        ,cloxl'..                      ,clxd,..    
               .;clxd,..;cldx:..                                                        ,ccoxl'..                      ,clxd,..    
               .;clxd;..:llxx:..                                                        'ccoxo,..                      ,clxd,..    
               .;clxd,.':llxx:..                                                        .cllxd;..                     .,clxd,..    
               .;clxd,.':llxd;..                                                        .:lldx:..                     .,clxd,..    
               .;llxo,.,cloxd;..                                                        .,cloxc'.                     .,coxo,..    
               .:llxo,.,ccoxd,..                                                         'ccoxo,..                    .,coxo,..    
               .:llxo,.;cloxo'..                                                         .:llxd;..                    .,coxo'..    
               .;llxo,':cldkl'..                                                         .;lldxc..                    .,coxl'..    
               .;llxd,':cldx:..                                                           'cloxo,..                   .;loxl'..    
               .;clxd,,cclxx:..                                                           .:lldd;..                   .;loxl'..    
               .;clxd;,ccoxd;..                                                           .,cloxl'.                   .;loxl'..    
               .,cldx:;cloxo,..                                                            .:lldd;..                  .:loxl'..    
                'cldxc:clokl'..                                                            .,cloxc'.                  .:ldxc'.     
                'cloxl:cldkc'.                                                              .:lldd;..                 .:ldxc'.     
                .:loxdccldx:..                                                               'cloxl'.                 .:ldxc'.     
                .:llxdlclxx;..                                                               .,clod:..                .:ldxc..     
                .;clddlclxd;..                                                                .;cldo;..               .:ldxc..     
                 'clodlcoxd,..                                                                 .;cldo,.               .:ldxc'.     
                 .:coolclxd,..                                                                  .,cldo,.              .:loxl'.     
                 .:llolcoxd,..                                                                   .,cloo;..            .:coxl'.     
                 .;clolcoxd,..                                                                     ':coo:..           .:coxl'.     
                  ,clllclxd,..                                                                      .;clol'.          .:loxl'.     
                  .clllclxd;..                                                                       .':loo:.         .;loxl'..    
                  .;cllllxx:..                                                                         .;cloc,.       .;clxo,..    
                   'clclldxc'.                                                                          ..:lll:'.     .;clxo,..    
                   .;lllloxl'.                                                                            .':lll;..   .;clxo,..    
                    .clccoxo,..                                                                             .':llc;.  .;coxo,..    
                    .,clcldx:..                                                                               ..;clc,'':coxo,..    
                     .;llcoxl'.                                                                                  .,;clcloxxl'..    
                      .;ccoxo,..                                                                                   .'cclodl,..    
                       .:lldd:..                                                                                     .;clloc'.     
                        'ccoxl'.                                                                                       ':clol;.     
                        .;lldd:..                                                                                       .':cllc,.     
                         .cclxo,.                                                                                         .,:lllc'.     
                         .,cloxc'.                                                                                          .,:lll:'.    
                          .;lldd;..                                                                                           ..;clll;.     
                           .:lldo,.                                                                                        ...,;:cloko,..    
                            'clodc'.                                                                                   ..',:cclllodxo;...   
                             ,ccodc'.                                                                               .',:clllodddolc,...   
                             .':llol,.                                                                           .';:cllodddol:,...  
                               .,:cll:'.                ..................                                    .',:cllodxdl:'...  
                                 .';:lc:,'.....''',,,;;:::cccclllllllccc::;;,,'...                        ..,;cclodddoc;'..   
                                    ..,:clooooooodoooolllccccc:::::::::::ccllllllc:;,'...           ...',;ccllodddlc,...   
                                        ..',;;;;,,''.......              .....',;::clllc:;,,,,,,,,,;:cclloodddoc;'..   
                                                                                  ...',;:cloollllllloodddolc;'...  
                                                                                        ...,;;:::cccc::,'...
*/


interface mintContract {
    function mint(address, uint256) external;
}

contract Q00tsStandWithZach {
    error WrongValueSent();
    error MintZeroItems();

    uint256 public constant PUBLIC_MINT_PRICE = 0.03 ether;

    mintContract private constant Q00NICORNS = mintContract(0xb1b853a1aaC513f2aB91133Ca8AE5d78c24cB828);
    mintContract private constant Q00TANTS = mintContract(0x862c9B564fbDD34983Ed3655aA9F68E0ED86C620);
    address public constant ZACHXBT = 0x6eA158145907a1fAc74016087611913A96d96624;

    function mint(uint256 numQ00tants, uint256 numQ00nicorns) external payable {
        uint256 amount;
        unchecked {
          amount = numQ00nicorns + numQ00tants;
        }

        if (amount == 0) revert MintZeroItems();
        if (msg.value != PUBLIC_MINT_PRICE * amount) revert WrongValueSent();

        if (numQ00tants > 0) Q00TANTS.mint(msg.sender, numQ00tants);
        if (numQ00nicorns > 0) Q00NICORNS.mint(msg.sender, numQ00nicorns);
    }

    function withdraw() public payable {
        (bool success, ) = payable(ZACHXBT).call{value: address(this).balance}("");
        require(success);
    }
}