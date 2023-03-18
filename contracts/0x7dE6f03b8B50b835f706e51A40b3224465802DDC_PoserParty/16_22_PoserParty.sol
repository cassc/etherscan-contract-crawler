// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721PartnerSeaDrop } from "./ERC721PartnerSeaDrop.sol";

/** 
  __   .__                                                                                 __           
_/  |_ |  |__    ____   ______    ____    ______  ____  _______  ______  _____   _______ _/  |_  ___.__.
\   __\|  |  \ _/ __ \  \____ \  /  _ \  /  ___/_/ __ \ \_  __ \ \____ \ \__  \  \_  __ \\   __\<   |  |
 |  |  |   Y  \\  ___/  |  |_> >(  <_> ) \___ \ \  ___/  |  | \/ |  |_> > / __ \_ |  | \/ |  |   \___  |
 |__|  |___|  / \___  > |   __/  \____/ /____  > \___  > |__|    |   __/ (____  / |__|    |__|   / ____|
            \/      \/  |__|                 \/      \/          |__|         \/                 \/     
 **/
contract PoserParty is ERC721PartnerSeaDrop {

    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    )
        ERC721PartnerSeaDrop(name, symbol, administrator, allowedSeaDrop)
    {}
}