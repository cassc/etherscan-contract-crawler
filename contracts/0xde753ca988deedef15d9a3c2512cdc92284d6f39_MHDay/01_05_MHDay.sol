// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: M.H.Day
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                      *&&&&@@@&&&&*                                     //
//                                        *       *                                       //
//                                        (#/,,*/%)                                       //
//                                      #%%&&%%%&&%%#,..                                  //
//               *#%..*%%#(*,,,,,**/((####(((((((((####(//**,,,,,*(#%%*..%#*              //
//                #&(#(///*.,*//****//((#############((//****//*,.*//*(#(&#               //
//                .#&((((//**,,,,,*************************,,,,,**//(((#&#.               //
//                .#&((((//***,,,,,,,,,,,............,,,,,,,,,,***//(((#&#.               //
//                .(((//**,,,,.............       .............,,,,**//((/.               //
//                .**,,.....                                     ......,**.               //
//                .**,......          . ,*..  ... .,             ......,**.               //
//                .**,......   ,*.. /%%#%* ##**,, ,**,,(#&#,,.   ......,**.               //
//                .**,..... */*///**#/(##*/(/ %(//*%(/(////*//*,......,,**.               //
//                .**,.../***/*, *#((*,/(*%((**/*/..,,.,%(//**/*//,...,,**.               //
//                .**,/ ((./%///*,%/((/*,*(%,,(..%&#%%#%//***/*.(%*, .,,**.               //
//                .*****#/*,*,,,,.,,,,,,#... .%#*,,.#/**.**,.%(/*.(*/,,,**.               //
//                .***,/%%%(,,...,*(* .(%#(((/**,,.   *&%&%*,,,,,/**./.,**.               //
//                .**,*,.,,.  ./,.  .%(*,**,.  .&##/#,.,,,...,#%/*,,/// **.               //
//                .**.*.        ...**,.*#..&(((..... %###%,*/(#%#..,(/*.**.               //
//                .**,,/.  *.  ..  .. .../..... #/*,.            ./ .,, **.               //
//                .**,,,           .... ..         .,,,.*, /,(,.*/(*  ,,**.               //
//                .**,,,.......,**,*   .**,.    ... ,,...  ,.,,. ,  .,,,**.               //
//                .**,,,.......   .......,. .   .            .   . ..,,,**.               //
//                .**,,,.......                 .   .      .    .....,,,**.               //
//                .**,,,,.......                      .      .......,,,,**.               //
//                .**,,,,........                            .......,,,,**.               //
//                .***,,,......,,,,*,,,,,,,,,,,,,,,,,,,,,*,,,,......,,****.               //
//                *,###(((///((((((((((((***********(((((((((((////(((%##,,               //
//                ...##%##(#%%%%%##########################%%%%%%((####(...               //
//                ,#(.                                                 .##,               //
//                *##(/*****,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*****/(##*               //
//                   *#%####%%#############%%%%%%%#############%%####%#,                  //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MHDay is ERC721Creator {
    constructor() ERC721Creator("M.H.Day", "MHDay") {}
}