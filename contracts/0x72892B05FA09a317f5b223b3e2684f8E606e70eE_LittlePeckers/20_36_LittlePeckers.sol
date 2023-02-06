// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@GJ!^^~7Y#@@@#5?!~!?5#@@@#G5JJYP#@@@@@@@@&&#&&@@@@@&G5YY5G&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@B~   :^.   ?&?.   ..  .?B7.       [email protected]@@#J~:. .:~J#&?:      :?#@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@#.  ^[email protected]@&Y   :   J&@&5      :5GBP!   !55.  :!7!:  .:  :YGGY:  :#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@?   [email protected]@@@@!      ?###J    :^[email protected]@@@&!^.     ^&@@@&~    [email protected]@@@B.  ~?~^::^[email protected]@@@@@@@@@@@@
// @@@@@@@@@@@@@^  ^@@@@@@J        ..   :G&@@@@@@@@@&Y ^[email protected]@@@@#P57 ^@@@@@@~     :^^:.   [email protected]@@@@@@@@@@
// @@@@@@@@@@@@@^  [email protected]@@@@@J^!!:   ?B##P::[email protected]@@@@@@@@@@5 [email protected]@@@@@@@@@@@:[email protected]@@@@@!  ^P#@@@@#P~   [email protected]@@@@@@@@@
// @@@@@@@@@@@@@!  :&@@@@@&@@@&7 [email protected]@@@@P  ^^[email protected]@@@@Y^:  ^J55&@@@@#5Y! [email protected]@@@@@! ^&@@@&5#@@&:  [email protected]@@@@@@@@@
// @@@@@@@&GY?!!:   [email protected]@@@@@@@@@5 [email protected]@@@@#.   [email protected]@@@@7       .&@@@@G    ^@@@@@@^ [email protected]@@@&P##G?   [email protected]@@@@@@@@@
// @@@@@G!.    ....  [email protected]@@@@@&5. ^@@@@@B    :[email protected]@@G.       [email protected]@@@J     [email protected]@@@5  :[email protected]@@@@@&#5   [email protected]@@@@@@@@@
// @@@&7   ~5B#&&&#GJ: ^!??7~:    7G#BP^     .~!~ .^~:     ^YPP?.      :!!^     !YPGBBGP7   :[email protected]@@@@
// @@@!  [email protected]@@@@@@@@@@J                          ~#@@@P  :^.                               ..     ^[email protected]@@
// @@G   [email protected]@@@@&P&@@@@@!  ^J5GGPY!.   ^JPBBBGY^  [email protected]@@@@[email protected]@&?   :?5GGGPJ^  .JGGP!!Y5J^ :JPB###BG7   [email protected]@
// @@?   [email protected]@@@@[email protected]@@@@7 [email protected]@@@@@@@B: [email protected]@@@@@@@G :&@@@@@@@@@@Y  !&@@@@&@@@? [email protected]@@@@@@@@# [email protected]@@@@@&#J   [email protected]@
// @@7  .&@@@@@@@@@@@@G [email protected]@@@@[email protected]@#::@@@@@GJP5^ ^@@@@@@@@@@G:  #@@@@[email protected]@&? [email protected]@@@@BPBG7 :Y#@@@@#Y:   [email protected]@
// @@?   [email protected]@@@@@&##G5!  ^&@@@@@&BP7 [email protected]@@@@&@@#:.&@@@@@@@@@@&7 [email protected]@@@@@#GY: [email protected]@@@@5    .5B&@@@@@@B   [email protected]@
// @@G   [email protected]@@@@@G..      ~P#@@@@@@B. :Y#&@@@@#Y. [email protected]@@@@[email protected]@@@@: JB&@@@@@&! ^#@@@B^    .G&@@@@@&B!   [email protected]@
// @@@?   ?#@@@&7   JGG!   .:^~~^:      :^~^:    .JGBP!  7PGP7    .:^^^:     ^~^   :~   .^~~~^.   ^[email protected]@@
// @@@@Y:   ^~~.  [email protected]@@@#5?~^:..:^~?PP?!^:::^!?J:      ..      ~J7~^:::^~?Y7^:.:^!Y#@BY7~:::::^[email protected]@@@@
// @@@@@&P7~:::^!Y#@@@@@@@@@@@&&@@@@@@@@@@@@@@@@&B5YJYP##PYYYP#@@@@@@@@@@@@@@@&&@@@@@@@@@@&&&@@@@@@@@@@
// @@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
// https://www.littlepeckers.farm
// 2022

import "./ERC721SeaDrop.sol";

contract LittlePeckers is ERC721SeaDrop {
  constructor(string memory name,
      string memory symbol,
      address[] memory allowedSeaDrop) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}
}