// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*



https://twitter.com/FlokiChinaa




RAID



FLOKI TO THE MOOOOOOOOOOOOON

*/
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Votes.sol";

contract CHINAFLOKI is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes {
    constructor() ERC20("CHINA FLOKI", "cFLOKI") ERC20Permit("CHINA FLOKI") {
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