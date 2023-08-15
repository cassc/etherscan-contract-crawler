pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PremierToken is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("Premier", "PREMIER") {
        _mint(msg.sender, 1000000000000 * 500 * 10 ** 18 );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transferMultiple(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        require(recipients.length > 0, "Invalid input length");
        require(recipients.length == amounts.length, "Invalid amount length");

        for (uint i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
}