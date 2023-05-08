// SPDX-License-Identifier: MIT
/*.                     I'm DODO
                  .-'''.
                .'      \_.---.
               /     ()  |     `\
              |          |       |
              |          \_.'`\_/
              |    .-..-'
          .-'.|    |-'.
        _>    `' `'    `\
        \              <_
        `;_.-\_(`-.|\'._/
             /     \  \
            /|      \  \
           ; |       \  \
           | |        \  ;
           | |         | |
           | \_        | |
           |   \_     /  |
     jgs  /      \___/   ;
        .'               /`---.
     .-'              .'  )_)_)_)
   (__..--'`------'`;_ `---.
                      )_)_)_)

*/

pragma solidity =0.6.12;
import "./ERC20.sol";

contract Dodo is ERC20 {
    using SafeMath for uint256;
    uint256 dodo = 0xD0D0;

    constructor (uint256 totalsupply_) public ERC20("DODO", "DODO") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}