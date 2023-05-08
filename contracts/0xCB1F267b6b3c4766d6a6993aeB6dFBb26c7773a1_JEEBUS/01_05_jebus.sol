// SPDX-License-Identifier: MIT

//     \.
//      \'.      ;.
//       \ '. ,--''-.~-~-'-,
//        \,-' ,-.   '.~-~-~~,
//      ,-'   (###)    \-~'~=-.
//  _,-'       '-'      \=~-"~~',
// /o                    \~-""~=-,
// \__                    \=-,~"-~,
//    """===-----.         \~=-"~-.
//                \         \*=~-"
//        jebus    \         "=====----
//           4      \
//                   \

//
//Telegram: https://t.me/jeebusentry

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JEEBUS is ERC20 {
    constructor() ERC20("JEBUS", "JEBUS") {
        uint256 supply = 911_000_000;
        _mint(msg.sender, supply * 10**18);
    }
}