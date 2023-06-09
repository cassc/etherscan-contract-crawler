// SPDX-License-Identifier: MIT
/*
  __    __   ____  ____  _____  ___  ___________  _______   _______       _______   __     ________    _______  _____  ___   
 /" |  | "\ ("  _||_ " |(\"   \|"  \("     _   ")/"     "| /"      \     |   _  "\ |" \   |"      "\  /"     "|(\"   \|"  \  
(:  (__)  :)|   (  ) : ||.\\   \    |)__/  \\__/(: ______)|:        |    (. |_)  :)||  |  (.  ___  :)(: ______)|.\\   \    | 
 \/      \/ (:  |  | . )|: \.   \\  |   \\_ /    \/    |  |_____/   )    |:     \/ |:  |  |: \   ) || \/    |  |: \.   \\  | 
 //  __  \\  \\ \__/ // |.  \    \. |   |.  |    // ___)_  //      /     (|  _  \\ |.  |  (| (___\ || // ___)_ |.  \    \. | 
(:  (  )  :) /\\ __ //\ |    \    \ |   \:  |   (:      "||:  __   \     |: |_)  :)/\  |\ |:       :)(:      "||    \    \ | 
 \__|  |__/ (__________) \___|\____\)    \__|    \_______)|__|  \___)    (_______/(__\_|_)(________/  \_______) \___|\____\) 
                                                                                                                             
      https://t.me/huntertoken123
      https://twitter.com/huntertoken123
      https://hunter.fail/





*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HunterBiden is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("Hunter Biden", "Hunter") ERC20Permit("Hunter Biden") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}