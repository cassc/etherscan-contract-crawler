pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AntPepeToken is ERC20, Ownable {
    bool public limited;
    address public pool;
    uint256 public maxHoldingAmount;

    constructor() ERC20("Ant Pepe", "ANTPEPE") {
        _mint(msg.sender, 420697400000000 * 10**18);
        transferOwnership(msg.sender);
    }

    function setRule(bool _limited, address _pool, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        pool = _pool;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (pool == address(0)) {
            require(from == owner() || to == owner(), "trading has not started");
            return;
        }

        if (limited && from == pool) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbidden");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}