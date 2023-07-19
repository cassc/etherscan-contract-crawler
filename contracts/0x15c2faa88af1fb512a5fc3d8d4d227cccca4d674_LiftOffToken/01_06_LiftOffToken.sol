// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
              ,,      ,...                         ,...  ,...
`7MMF'        db    .d' ""mm         .g8""8q.    .d' "".d' ""
  MM                dM`   MM       .dP'    `YM.  dM`   dM`
  MM        `7MM   mMMmmmmMMmm     dM'      `MM mMMmm mMMmm
  MM          MM    MM    MM       MM        MM  MM    MM
  MM      ,   MM    MM    MM       MM.      ,MP  MM    MM
  MM     ,M   MM    MM    MM       `Mb.    ,dP'  MM    MM
.JMMmmmmMMM .JMML..JMML.  `Mbmo      `"bmmd"'  .JMML..JMML.

*/
contract LiftOffToken is ERC20, Ownable {
    constructor() ERC20("Lift Off", "LIFTOFF") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}