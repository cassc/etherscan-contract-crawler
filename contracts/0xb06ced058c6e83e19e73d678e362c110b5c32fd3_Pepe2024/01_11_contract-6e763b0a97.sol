// SPDX-License-Identifier: MIT

/*

The greatest meme figure of all time is about to become the leader of the free world.

Join us as we make international history.

Telegram: https://t.me/pepe2024coin
Twitter: https://twitter.com/pepe2024coin
Website: https://pepe2024.org

 ____     ____       ____     ____                    ___        __        ___      __ __      
/\  _`\  /\  _`\    /\  _`\  /\  _`\                /'___`\    /'__`\    /'___`\   /\ \\ \     
\ \ \L\ \\ \ \L\_\  \ \ \L\ \\ \ \L\_\             /\_\ /\ \  /\ \/\ \  /\_\ /\ \  \ \ \\ \    
 \ \ ,__/ \ \  _\L   \ \ ,__/ \ \  _\L             \/_/// /__ \ \ \ \ \ \/_/// /__  \ \ \\ \_  
  \ \ \/   \ \ \L\ \  \ \ \/   \ \ \L\ \              // /_\ \ \ \ \_\ \   // /_\ \  \ \__ ,__\
   \ \_\    \ \____/   \ \_\    \ \____/             /\______/  \ \____/  /\______/   \/_/\_\_/
    \/_/     \/___/     \/_/     \/___/              \/_____/    \/___/   \/_____/       \/_/  

*/

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Pepe2024 is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("Pepe 2024", "PEPE2024") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}