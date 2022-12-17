// SPDX-License-Identifier: Apache-2.0

/// @notice Fluctuat Nec Mergitur by Charlesai
/// @author transientlabs.xyz

/**

 ____    ___                    __                      __        __  __                                                       __                    
/\  _`\ /\_ \                  /\ \__                  /\ \__    /\ \/\ \                     /'\_/`\                       __/\ \__                 
\ \ \L\_\//\ \    __  __    ___\ \ ,_\  __  __     __  \ \ ,_\   \ \ `\\ \     __    ___     /\      \     __   _ __    __ /\_\ \ ,_\  __  __  _ __  
 \ \  _\/ \ \ \  /\ \/\ \  /'___\ \ \/ /\ \/\ \  /'__`\ \ \ \/    \ \ , ` \  /'__`\ /'___\   \ \ \__\ \  /'__`\/\`'__\/'_ `\/\ \ \ \/ /\ \/\ \/\`'__\
  \ \ \/   \_\ \_\ \ \_\ \/\ \__/\ \ \_\ \ \_\ \/\ \L\.\_\ \ \_    \ \ \`\ \/\  __//\ \__/    \ \ \_/\ \/\  __/\ \ \//\ \L\ \ \ \ \ \_\ \ \_\ \ \ \/ 
   \ \_\   /\____\\ \____/\ \____\\ \__\\ \____/\ \__/.\_\\ \__\    \ \_\ \_\ \____\ \____\    \ \_\\ \_\ \____\\ \_\\ \____ \ \_\ \__\\ \____/\ \_\ 
    \/_/   \/____/ \/___/  \/____/ \/__/ \/___/  \/__/\/_/ \/__/     \/_/\/_/\/____/\/____/     \/_/ \/_/\/____/ \/_/ \/___L\ \/_/\/__/ \/___/  \/_/ 
                                                                                                                        /\____/                      
                                                                                                                        \_/__/                       

*/

pragma solidity 0.8.14;

import "ShatterV2.sol";

contract FluctuatNecMergitur is ShatterV2 {

    constructor (
        address royaltyRecipient,
        uint256 royaltyPercentage,
        address admin,
        uint256 num,
        uint256 time
    )
    ShatterV2(
        "Fluctuat Nec Mergitur",
        "FNM",
        royaltyRecipient,
        royaltyPercentage,
        admin,
        num,
        time
    )
    {}

}