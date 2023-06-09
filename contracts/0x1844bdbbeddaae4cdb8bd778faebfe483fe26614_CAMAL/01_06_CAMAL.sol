// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CAMAL is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000000000 * 10**18;
    uint256 private constant MAX_TAXABLE_TRADES = 6;
    uint256 private _buyTax = 15;
    uint256 private _sellTax = 15;
    uint256 private _numTrades = 0;

    constructor() ERC20("Camal Inu", "CAMAL") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _numTrades++;
        if (_numTrades <= MAX_TAXABLE_TRADES) {
            uint256 tax = (amount * _sellTax) / 100;
            _burn(msg.sender, tax);
            amount -= tax;
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _numTrades++;
        if (_numTrades <= MAX_TAXABLE_TRADES) {
            uint256 tax = (amount * _buyTax) / 100;
            _burn(sender, tax);
            amount -= tax;
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function setBuyTax(uint256 tax) external onlyOwner {
        require(tax <= 100, "Tax must be less than or equal to 100");
        _buyTax = tax;
    }

    function setSellTax(uint256 tax) external onlyOwner {
        require(tax <= 100, "Tax must be less than or equal to 100");
        _sellTax = tax;
    }

    function resetNumTrades() external onlyOwner {
        _numTrades = 0;
    }
}