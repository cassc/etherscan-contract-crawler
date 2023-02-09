// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGemAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract SimpleTokenWithAntiBot is ERC20Upgradeable, OwnableUpgradeable {
    uint8 private _decimals;
    address public gemAntiBot;
    bool public antiBotEnabled;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) initializer payable public {
        require(msg.value >= 0.1 ether, "not enough fee");
        (bool sent, ) = payable(0x8e89BeEba31C5521601449410215De43D23f4b45).call{value: msg.value}("");
        require(sent, "fail to transfer fee");
        __ERC20_init(_name, _symbol);
        _decimals = __decimals;
        _transferOwnership(tx.origin);
        _mint(owner(), _totalSupply );
        gemAntiBot = _gemAntiBot;
        IGemAntiBot(gemAntiBot).setTokenOwner(owner());
        antiBotEnabled = true;
    }

    function setUsingAntiBot(bool enabled_) external onlyOwner {
        antiBotEnabled = enabled_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (antiBotEnabled) {
            IGemAntiBot(gemAntiBot).onPreTransferCheck(sender, recipient, amount);
        }
        super._transfer(sender, recipient, amount);
    }
}