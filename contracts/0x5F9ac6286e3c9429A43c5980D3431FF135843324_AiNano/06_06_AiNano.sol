// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiNano is Ownable, ERC20 {
    // Total supply: 100 billion
    uint256 public constant TOTAL_SUPPLY = 100 * (10 ** 9) * (10 ** 18);
    uint256 public maxTransferAmount;

    mapping(address => bool) public blacklists;

    constructor() ERC20("AiNano", "AINANO") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setBlacklist(
        address _address,
        bool isBlacklist
    ) external onlyOwner {
        blacklists[_address] = isBlacklist;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[from] && !blacklists[to], "BL");

        if (from != owner() && to != owner() && maxTransferAmount > 0) {
            require(amount <= maxTransferAmount, "Max");
        }
    }

    function setMaxTransferAmount(
        uint256 _maxTransferAmount
    ) external onlyOwner {
        maxTransferAmount = _maxTransferAmount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}