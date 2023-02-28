// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
        :::     :::::::::  ::::::::::: ::::::::  
      :+: :+:   :+:    :+:     :+:    :+:    :+: 
     +:+   +:+  +:+    +:+     +:+    +:+        
    +#++:++#++: +#+    +:+     +#+    +#++:++#++ 
    +#+     +#+ +#+    +#+     +#+           +#+ 
    #+#     #+# #+#    #+# #+# #+#    #+#    #+# 
    ###     ### #########   #####      ########  

    UAE NFT - Art Dubai | Jason Seife
    All rights reserved 2023
    Developed by DeployLabs.io ([email protected])
*/

import "./ArtDubai.sol";

/**
 * @title UAE NFT - Art Dubai | Jason Seife
 * @author DeployLabs.io
 *
 * @dev This contract is a collection for Art Dubai by Jason Seife.
 */
contract ArtDubaiJasonSeife is ArtDubai {
	constructor() ArtDubai(0x39431b51cb437b22, 0xb3B322858B8D0b055d492e167a2440192a7Fa642) {}
}