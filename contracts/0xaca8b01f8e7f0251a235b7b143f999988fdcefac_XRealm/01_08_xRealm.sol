// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Blacklister.sol";

contract XRealm is ERC20, Ownable, Blacklistable, ERC20Burnable {
    error Unauthorized();

    constructor(address _owner) ERC20("xRealm.ai Token", "XRLM") {
        transferOwnership(_owner);
        _mint(_owner, 10000000 * 10 ** decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) notBlacklisted(from) notBlacklisted(to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}