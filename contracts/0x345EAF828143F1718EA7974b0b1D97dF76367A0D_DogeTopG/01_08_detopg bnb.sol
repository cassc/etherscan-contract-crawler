// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DogeTopG is ERC20, ReentrancyGuard, Initializable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 1300e12;

    uint256 private _burnRate = 2; // 2% burn rate
    uint256 private _taxRate = 4; // 4% tax rate

    mapping(address => bool) private _isExcludedFromTax;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        // Initialize the ERC20 contract
        _mint(msg.sender, INITIAL_SUPPLY * 10**decimals());
    }

    function getTaxRate() public view returns (uint256) {
        return _taxRate;
    }

    function getBurnRate() public view returns (uint256) {
        return _burnRate;
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        uint256 taxAmount = amount * _taxRate / 100;
        uint256 burnAmount = amount * _burnRate / 100;
        uint256 transferAmount = amount - taxAmount;

        super._transfer(sender, address(this), taxAmount);
        super._transfer(sender, recipient, transferAmount);
        _burn(address(this), burnAmount);
    }
}