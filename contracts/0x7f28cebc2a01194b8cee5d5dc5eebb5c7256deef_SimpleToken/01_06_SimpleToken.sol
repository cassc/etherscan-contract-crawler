// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//                                                                            .
//   .    .                  j.         j.                                   ,W   t
//   Di   Dt              .. EW,        EW,        f.     ;WE.              i##   EE.
//   E#i  E#i            ;W, E##j       E##j       E#,   i#G               f###   :KW;           :
//   E#t  E#t           j##, E###D.     E###D.     E#t  f#f               G####     G#j         G#j
//   E#t  E#t          G###, E#jG#W;    E#jG#W;    E#t G#i              .K#Ki##      j#D.     .E#G#G
//   E########f.     :E####, E#t t##f   E#t t##f   E#jEW,              ,W#D.,##   itttG#K,   ,W#; ;#E.
//   E#j..K#j...    ;W#DG##, E#t  :K#E: E#t  :K#E: E##E.              i##E,,i##,  E##DDDDG: i#K:   :WW:
//   E#t  E#t      j###DW##, E#KDDDD###iE#KDDDD###iE#G               ;DDDDDDE##DGiE#E       :WW:   f#D.
//   E#t  E#t     G##i,,G##, E#f,t#Wi,,,E#f,t#Wi,,,E#t                      ,##   E#E        .E#; G#L
//   f#t  f#t   :K#K:   L##, E#t  ;#W:  E#t  ;#W:  E#t                      ,##   E##EEEEEEt   G#K#j
//    ii   ii  ;##D.    L##, DWi   ,KK: DWi   ,KK: EE.                      .E#   tffffffffft   j#;
//             ,,,      .,,                        t                          t

// We are getting high today! Smoke Weed in Hogwarts Every Day.
// Telegram: https://t.me/harrypotterganja

contract SimpleToken is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}