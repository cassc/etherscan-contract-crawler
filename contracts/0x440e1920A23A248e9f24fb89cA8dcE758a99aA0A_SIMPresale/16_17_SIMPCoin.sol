// contracts/SIMPCoin.sol
// SPDX-License-Identifier: MIT

/*
  ______   ______  __       __  _______          ______    ______   ______  __    __ 
 /      \ /      |/  \     /  |/       \        /      \  /      \ /      |/  \  /  |
/$$$$$$  |$$$$$$/ $$  \   /$$ |$$$$$$$  |      /$$$$$$  |/$$$$$$  |$$$$$$/ $$  \ $$ |
$$ \__$$/   $$ |  $$$  \ /$$$ |$$ |__$$ |      $$ |  $$/ $$ |  $$ |  $$ |  $$$  \$$ |
$$      \   $$ |  $$$$  /$$$$ |$$    $$/       $$ |      $$ |  $$ |  $$ |  $$$$  $$ |
 $$$$$$  |  $$ |  $$ $$ $$/$$ |$$$$$$$/        $$ |   __ $$ |  $$ |  $$ |  $$ $$ $$ |
/  \__$$ | _$$ |_ $$ |$$$/ $$ |$$ |            $$ \__/  |$$ \__$$ | _$$ |_ $$ |$$$$ |
$$    $$/ / $$   |$$ | $/  $$ |$$ |            $$    $$/ $$    $$/ / $$   |$$ | $$$ |
 $$$$$$/  $$$$$$/ $$/      $$/ $$/              $$$$$$/   $$$$$$/  $$$$$$/ $$/   $$/                                                                                                                                                           

Website: https://simp.trade/
Twitter: https://twitter.com/simpcoinETH_
*/

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SIMPCoin is ERC20, ERC20Capped, ERC20Burnable, ERC20Permit, Ownable {
    constructor(uint256 cap) ERC20("SIMP", "SIMP") ERC20Capped(cap * (10 ** decimals())) ERC20Permit("SIMP") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }

    // These functions have overrides that are required by Solidity due to inheritence. 
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }

    function renounceOwnership() public override onlyOwner {

        _transferOwnership(address(0));
    }

}