//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

/*
                    .!5B&@@@&5.                                 :G#7                &@@5
               .~Y#@@@@&[email protected]@@5                                 &@@Y               [email protected]@&
           :7G&@@@&G?:   ^[email protected]@&.    ^&@P                        [email protected]@&               [email protected]@@~             .
       ^Y#@@@@#Y~.     [email protected]@@B!     .&@@Y.:^~7?YPGB#&&@@@@@@@^  [email protected]@@~               [email protected]@B   !?Y5GBB#&&@@5
     [email protected]@@&G7:          .!!???5GB##&@@@@@@@@@@@@&&#BG5J?!~^.   [email protected]@B     ^JGBG!    ^@@@.  [email protected]@@@&&@@@@G:
    &@@@~                ^@@@@@&#&@@@Y7!~^:.                 [email protected]@@.  ^[email protected]@@@@@@.   #@@J    ..  !&@@P:
    &@@@!                        #@@Y      .?G#&@@@@@@@@@Y   &@@J.Y&@@G~ [email protected]@B   [email protected]@&       7&@@5.
    [email protected]@@@BY~:                  [email protected]@&      [email protected]@@#[email protected]@@&   [email protected]@@[email protected]@&7   [email protected]@@:  [email protected]@@~     ?&@@J
      .~5#@@@@@&GJ~.           :@@@^     #@@P     :[email protected]@@@!  [email protected]@@@@#^     [email protected]@P   [email protected]@G   [email protected]@@J.  .:^~!?J5PG#&&@@@@@@
           .~JG&@@@@@&P?^.     #@@G     [email protected]@&    :[email protected]@@@@B   [email protected]@@&^      [email protected]@@:  [email protected]@@[email protected]@@@@&@@@@@@@@@@@@&&#BP5J
                 :!YB&@@@@@#[email protected]@@.    [email protected]@@^  :[email protected]@[email protected]@@.  [email protected]@@G..:^~7Y&@@@@@&@@@@@@@@@&B&#BGPYJ7!^::..
  [email protected]@~               .:!5B&@@@@@J     [email protected]@G ^[email protected]@B: [email protected]@@BG#@@@@@@@@@@@&G!YBBBG57::^:..
 [email protected]@@G                      [email protected]@@@#!!?Y#@@@@@@@B^   ^#&&&&#GPYJ7!~^:.
[email protected]@@P         ..:^~!?J5GB#&@@@@@@@@@@@&GPBB57.
[email protected]@@@BPPGB&&@@@@@@@@@@@&&#BGY7:..:...
 !G&@@@@@&&#GPY?!~^:..
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Stablz token
contract Stablz is ERC20Burnable {

    constructor () ERC20("Stablz", "STABLZ") {
        _mint(msg.sender, 100_000_000 * (10 ** decimals()));
    }
}