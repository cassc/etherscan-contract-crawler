// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// This is a fun contract deployed as part of the hardware wallet sent to lindridge's classroom
// https://www.candorcs.org/
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract CandorCoin is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("CandorCoin", "CAN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}