// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBananaAntiBot.sol";

contract ERC20TokenOB is Context, ERC20, ERC20Burnable, Ownable {
    address private immutable deployer;
    IBananaAntiBot public immutable antiBot;
    uint8 private constant DECIMALS = 18;
    bool public antiBotActive;

    modifier onlyDeployer {
        require(msg.sender == deployer);
        _;
    }

    constructor(string memory name_, string memory symbol_, uint initialSupply_, address antiBot_) ERC20(name_, symbol_) {
        antiBot = IBananaAntiBot(antiBot_);
        antiBotActive = true;
        deployer = _msgSender();

        _mint(_msgSender(), (initialSupply_ * (10 ** DECIMALS)));
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function setAntiBotState(bool antiBotActive_) public onlyDeployer {
        antiBotActive = antiBotActive_;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        if (amount > 0) {
            super._mint(account, amount);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
        if (antiBotActive) {
            antiBot.beforeTokenTransferCheck(from, to);
        }
    }
}