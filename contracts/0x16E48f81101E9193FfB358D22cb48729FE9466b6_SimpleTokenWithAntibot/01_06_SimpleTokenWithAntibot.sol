// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGemAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract SimpleTokenWithAntibot is ERC20, Ownable {
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);
    uint8 private _decimals;
    address public gemAntiBot;
    bool public antiBotEnabled;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) payable ERC20(_name, _symbol) {
        feeContract.payFee{value: msg.value}(0);   
        _decimals = __decimals;
        _mint(msg.sender, _totalSupply );
        gemAntiBot = _gemAntiBot;
        IGemAntiBot(gemAntiBot).setTokenOwner(msg.sender);
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