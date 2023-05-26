pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/safety/Locker.sol";
import "../token/Taxable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract EvnToken is Taxable, ILockerUser {
    uint256 constant CAP = 100000000 * 10 ** 18;
    uint256 public defaultTaxRateOver1000;
    ILocker public override locker;
    constructor () ERC20("Evn Token", "EVN") public {
        _mint(msg.sender, CAP);
    }

    function setDefaultTaxRate(uint256 taxRateOver1000)
    external onlyOwner() {
        defaultTaxRateOver1000 = taxRateOver1000;
    }

    function setLocker(address _locker)
    external onlyOwner() {
        locker = ILocker(_locker);
        // ILocker(_locker).lockOrGetPenalty(msg.sender, address(this)); //verify can be called
    }

    function _transfer(address sender, address recipient, uint256 amount)
    internal virtual override {
        return _transferWithTax(sender, recipient, amount);
    }

    function _transferWithTax(address sender, address recipient, uint256 amount)
    internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount < 2 ** 127, "ERC20: amount too large");
        if (sender == address(taxDistributor)) {
            // Short circuit to save gas
            _transferWithoutTax(sender, recipient, amount);
            return;
        }

        (bool shouldOverridePenalty, uint256 overridenPenaltyOver1000) = locker.lockOrGetPenalty(sender, recipient);
        // get the tax rate.
        uint256 taxRate = shouldOverridePenalty ? overridenPenaltyOver1000 : defaultTaxRateOver1000;
        if (taxRate != 0) {
            uint256 taxAmount = taxRate.mul(amount).div(1000);
            require(tax(sender, taxAmount), "ERC20: Could not apply tax");
            amount = amount.sub(taxAmount);
        }
        _transferWithoutTax(sender, recipient, amount);
    }

    function _transferWithoutTax(address sender, address recipient, uint256 amount)
    internal override {
        return ERC20._transfer(sender, recipient, amount);
    }
}