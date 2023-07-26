// SPDX-License-Identifier: MIT

/*

Welcome to the greatest Bitcoin/memecoin crossover the world has ever seen.

Bitcoin 2.1 // 21,000,000 Supply // 0/0 Tax // 2017 OG Developers

https://t.me/btc21coin
https://twitter.com/btc21coin
http://btc21coin.com

 ____       ______    ____                 ___            _     
/\  _`\    /\__  _\  /\  _`\             /'___`\        /' \    
\ \ \L\ \  \/_/\ \/  \ \ \/\_\          /\_\ /\ \      /\_, \   
 \ \  _ <'    \ \ \   \ \ \/_/_         \/_/// /__     \/_/\ \  
  \ \ \L\ \    \ \ \   \ \ \L\ \           // /_\ \ __    \ \ \ 
   \ \____/     \ \_\   \ \____/          /\______//\_\    \ \_\
    \/___/       \/_/    \/___/           \/_____/ \/_/     \/_/
                                                                   
*/

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Bitcoin21 is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("Bitcoin 2.1", "BTC2.1") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
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