// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Olde Craig Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                 //    //
//    //                                                                                                                 //    //
//    //                                                                                                                 //    //
//    //     ::::::::  :::        :::::::::  ::::::::::       ::::::::  :::::::::      :::     ::::::::::: ::::::::      //    //
//    //    :+:    :+: :+:        :+:    :+: :+:             :+:    :+: :+:    :+:   :+: :+:       :+:    :+:    :+:     //    //
//    //    +:+    +:+ +:+        +:+    +:+ +:+             +:+        +:+    +:+  +:+   +:+      +:+    +:+            //    //
//    //    +#+    +:+ +#+        +#+    +:+ +#++:++#        +#+        +#++:++#:  +#++:++#++:     +#+    :#:            //    //
//    //    +#+    +#+ +#+        +#+    +#+ +#+             +#+        +#+    +#+ +#+     +#+     +#+    +#+   +#+#     //    //
//    //    #+#    #+# #+#        #+#    #+# #+#             #+#    #+# #+#    #+# #+#     #+#     #+#    #+#    #+#     //    //
//    //     ########  ########## #########  ##########       ########  ###    ### ###     ### ########### ########      //    //
//    //                                                                                                                 //    //
//    //                                                                                                                 //    //
//    //                                                                                                                 //    //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OCX is ERC1155Creator {
    constructor() ERC1155Creator("Olde Craig Editions", "OCX") {}
}