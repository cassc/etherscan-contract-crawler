// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Groot is ERC20, Ownable {

    uint public constant MAX_ANTIWHALE = 4000;
    uint public antiWhalePercent = 4000;

    event MaxTransferAntiWhale(address indexed devPower, uint256 oldAntiWhalePercent, uint256 newAntiWhalePercent);

    constructor(uint256 initialSupply) ERC20("Groot", "GROOT") {
        _mint(msg.sender, initialSupply);
    }

    function maxTokensTransferAmountAntiWhaleMethod() public view returns (uint256) {
        return totalSupply() * (antiWhalePercent) / (10000);
    }

    function updateMaxTransferAntiWhale(uint16 _newAntiWhalePercent) public onlyOwner {
        require(_newAntiWhalePercent <= MAX_ANTIWHALE, "Antiwhale percent too high");
        antiWhalePercent = _newAntiWhalePercent;
        emit MaxTransferAntiWhale(msg.sender, antiWhalePercent, _newAntiWhalePercent);
    }

    modifier antiWhale(address sender, address recipient, uint256 q) {
        require(q <= maxTokensTransferAmountAntiWhaleMethod() || sender == owner() || recipient == owner(), "Antiwhale. You are trying to transfer too many tokens");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        super._transfer(sender, recipient, amount);
    }
}