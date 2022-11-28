// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Calladita Sartoshi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnvh#8&*%Bnnnnnxddddoknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnwW&[email protected][email protected]@&qoaaaaaaao#%WoZmCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]%##B%%[email protected]@%WMaaa8%%%%%%BWW###aao8&Qxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnxzqo%@@[email protected]###@@[email protected][     1OmZbW%88%%%%%8Jnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnp&[email protected]@@@@$$$&####@$$$                    .`OaM%%%%B8qnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnncM%[email protected]%[email protected]%####[email protected]$$#                         '+vBBBB8%onnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected](  a#&##%@&##@$$Y                              w8B8%8Zxnnnnnnnnnnnnnnnnnnnnnnnnxvnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]    *#@#@@@8#[email protected]$$f                               idaaaa%WYunnnnnnnnnnnnnnnnnnnO#B%Ynnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno%@@Bh.    ,##@@@$B##[email protected]$$)                                 .Caaa&*oUnnnnnnnnnnnnnnnnOo*%BBMunnnnnnnnnnnnnnnnnnnn    //
//    [email protected]@B;      i&#M%@@B##&@$$)                                   'LoMB8obnnnnnnnnnnnnnnnnna%%BWunnnnnnnnnnnnnnnnnnnn    //
//    [email protected]@Bq^       [email protected]#%%#*[email protected]$Wl                                     "m8BB&[email protected]    //
//    [email protected]%&Y        ;Z%@[email protected]&8B%$o                                        ;a%M*[email protected]    //
//    [email protected][email protected]#W^         <#%@@@[email protected]#[email protected]%$o                                          &B%%nnnnnnnnnnnnnnnnaBBwnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#[email protected]*c           ~&[email protected]%@@@[email protected]$8bp?                                       UoW%dxnnnnnnnnnnnnnn8BBqnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnpBB#%}          l08%[email protected]@[email protected]%[email protected]@[email protected]%%B%Jz.                                   IbaW%Lnnnnnnnnnnnnnu%BBOnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnW%Wan         ;[email protected]%%@[email protected]&&M#[email protected]@%BB%hCl                                  /oM%annnnnnnnnnnnnJ%@@Cnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnMB&a!        [email protected]@[email protected]@@@@@[email protected]#**%@[email protected]%8br.                                 08%8cnnnnnnnnnnnnL%BBznnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%B&a        [email protected]$B#&[email protected]%%%%B######@[email protected]%bd.                                :k%&bnnnnnnnnnnnnO%B%xnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%BWa        bB$$#%[email protected]@@@@M#%@[email protected]#####[email protected]@[email protected]%b/                                z#Bacnnnnnnnnnnnw%BMrnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnc%BWh       [email protected]$B%[email protected]@@@$%@B%@[email protected]%######[email protected][email protected]@@of              .jvf     i".     X%B%annnnnnnnnnnwBBannnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnn*%@&a       [email protected][email protected]@%@@@[email protected]@&%@@#######[email protected]@@Wb|            [email protected]@$$Wl  [email protected]@$p    `[email protected]*cnnnnnnnnnnwBBonnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnn]%@Bq       [email protected][email protected]@@%%@@@@@@@@@@B#####[email protected]&%@@*b/            [email protected]@M! }@$$$a,    #@B#nnnnnnnnnnnmBB*nnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected](       [email protected]@$$%@[email protected]@@@@@@@@[email protected]@[email protected]#MB$8%@@Md              |Bh_.   _%Bq.    >[email protected]%nnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]"       Q&[email protected]@@@@@@@@@@@@[email protected]%&#@[email protected],                                oW%%qnnnnnnnnnnZBB8nnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]@B"       0#[email protected][email protected]@@@@@@@@@@@@@&M%[email protected][email protected]@@@a                                 x&8#knnnnnnnnnnnB%Bvnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]$B"      '[email protected][email protected]@[email protected]@@@@@@@@@@@[email protected]@@[email protected]@@Bt                                 #&B#bnnnnnnnnnnnLM8mnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]%B       Zo%@[email protected]@@@@@@@@@@@@@[email protected][email protected]@[email protected]@@%%bt                                 oBB%&CnnnnnnnnnnnMBwnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%BB8*"      /8W%[email protected]@%[email protected]@@@[email protected]@&%[email protected]@@@BO                                  co**%bnnnnnnnnnnnnxbZnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnb*aBBMh        [email protected][email protected]$$$8$$%M%@@@@%%U                                  .Y*M&Mxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnmJnhBB8Z`       ;q%@@@@B%%@@&*####*&@@@B%W-              ?<`                  !#%&&Cnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnh%B%&`        [email protected]@@#[email protected]@[email protected]@@%al               [email protected][email protected]$z.             ^Y8%%xnnnuvvvz*#&@@@8oQnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnua%@%M:        'cddkk8%@B%%%B%8h[ '                '[email protected]   ![rYb&[email protected]%@%8%[email protected]@@[email protected]$$$$$$$$B0nnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYh&@BB8q.          l+'                             ^|@[email protected]@%%B%@@@[email protected]@%%8pQQJUUaLnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnxp#B8&MdI                                             [email protected][email protected]@[email protected]@BBBBBWbxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnna%BB%8#"                                                        _&[email protected]@8dQnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]&Wo-                                                    <[email protected]    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnJa#%B&@[email protected]@%&x'                                              )O&W8BBhCcnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnC&B8%88%M8&&[email protected]@BMq_                                         Ita8BBBBbunnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnZ%%o#8BW8*8#Jb%[email protected]@Mat`                                   >va*%@@%%mxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnC#B##%[email protected]%o**oYnnb#BBB%*oh?`.                         {h**aa#%BBaknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]%[email protected]&WaW*#Lnnnud*8BBB#aaa[                     j&%%%%%oaUXznnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]*8%8W*a*qnnnnnnn0*#oaa#[email protected]@B&M*ahc1 ][email protected]%%dCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    [email protected]@BB8%**[email protected]@@@@B%#%%%%[email protected]@8%[email protected]    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkBBBB%%%*[email protected]#MCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnqaOo_~!,hvLWbczccCoaoao#%@BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno%#8%B%%*aakcnnnnnnnnnnnnnnnnnnnnnnnZ#%8*8munnnnnnnnnnnnnnnnnnnnnnnnzh0nnnvpoakhkkhhhhBQwcW{;&!d%8BBBB8%%[email protected]%    //
//    [email protected]%o8adnnnnnnnnnnnnnnnnnnnnnnnnno8B%onnnnnnnnnnnnnnnnnnnnnnnYM%BB%M88&MM##8%%B%mWhax{r&&#u%0%%88%%%%&***hmU    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*BwWB&W*aW#[email protected]%%[email protected]@BB8%BBBB%BB8M&8&[email protected]!cWQuxnrnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnwB8#B*&oa&[email protected]%[email protected]@@@@B8%BB8oqpuxrnnnnnnYBrbC1)YUxqoZnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*B%#B#&*%8*nnnnnnnnnnnnnnnnnnnnnnnnnr&@BB%Mvunnnnnnnnno%[email protected][email protected]%#WahbnnnnnnnnnnnnnnnnUBB%%B%vnnnnnnnnnnnnnnunnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#B8%8&W&88#vnnnnnnnnnnnnnnnnnnnnnnnnz8%[email protected]@&aa0nnnJ*%[email protected]@B%&*aaCcnnnnnnnnnnnnnnnnnnnnnjnnUpwZYxncqpdka*&8&8BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnY8B%%W8MBW&pnnnnnnnnnnnnnnnnnnnnnnnnnp#aoM#W&[email protected]@@@@8#aaCvnnnnnu0ZZOWMao#MMMMW&%BB%%[email protected]@@BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnqBBW8%%8%M*qnnnnnnnnnnnnnnnnnnnnnnnnLo#&a%B%@@[email protected]&#*o00OM%%%%%[email protected]&%%%[email protected]@@B%%%8%BBB%BB%%#bkpvnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnW88&oo8B%[email protected]@[email protected]@@@@@@@@@@@@@@@@@@BB8o*M%[email protected]%&&M###opnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnd*&B*o*@B%Cnnnnnnnnnnnnnnnnnnnnnnnnnnuo*%%[email protected]*BBB%%%%%%8W#*oooo*WaoaoodXvvnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnQaM%[email protected]@B%W#*888%%%%%W*M0UUunnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnOaMB8*%[email protected]*%[email protected]@@@@BB8W0unnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnpaoW8BBB%@&LnnnnnnnnnnnnnnnnnnnnnnnnnnnnXba#8%%[email protected]@@@%%%8*Ynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYaa#B%@@BBBBonnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno&%%%[email protected]@%#B%%WCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnc#B%*BBBBBBannnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnXdao*8%[email protected]    //
//    [email protected]#@BBB8B*xnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnXOaoM%%%[email protected]@8MoM8MMwnnnnnnnnnnnnCbJppZnnwYaUwOLLZnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnzWBWk%[email protected]@qnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnzwaaM8%[email protected]@@%8M8%%8oaLJxnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkB%oW%@%%BknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkaoM8%[email protected][email protected]%@B%%%%aOvnnnnnnnnnnnnnnnnnnnnnn    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDST is ERC721Creator {
    constructor() ERC721Creator("Calladita Sartoshi", "CDST") {}
}