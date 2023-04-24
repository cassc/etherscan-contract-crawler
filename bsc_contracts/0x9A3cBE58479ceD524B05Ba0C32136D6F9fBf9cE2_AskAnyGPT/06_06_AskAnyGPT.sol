// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract AskAnyGPT is Context, Ownable, ERC20 {

    mapping(address => bool) public pairs;
    address public feeRecipient;
    uint256 public constant BUY_FEE = 3;
    uint256 public constant SELL_FEE = 4;

    constructor(address _feeRecipient) ERC20("AskAnyGPT", "ASK") {
        _mint(_msgSender(), 500_000_000e18);
        feeRecipient = _feeRecipient;
    }

    function setPair(address _pair, bool _value) external onlyOwner {
        pairs[_pair] = _value;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 amountToTransfer = amount;
        uint256 feePercent = pairs[sender] ? BUY_FEE : pairs[recipient] ? SELL_FEE : 0;
        uint256 fee = (amount * feePercent) / 100;
        amountToTransfer -= fee;
        super._transfer(sender, address(feeRecipient), fee);
        super._transfer(sender, recipient, amountToTransfer);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}