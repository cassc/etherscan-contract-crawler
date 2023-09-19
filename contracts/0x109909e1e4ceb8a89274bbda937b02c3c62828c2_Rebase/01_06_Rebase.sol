// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rebase is ERC20, Ownable {
    mapping(address => bool) public isTaxExempt;

    uint256 public tax;
    address public pair;
    address public taxManager;
    address public taxRecipient;

    modifier onlyOwnerOrTaxManager() {
        require(
            msg.sender == owner() || msg.sender == taxManager,
            "Caller is neither the owner nor tax manager"
        );
        _;
    }

    error NotAllowed();
    error InvalidConfig();

    constructor(
        address mintRecipient_,
        address taxRecipient_,
        address taxManager_,
        uint256 tax_
    ) ERC20("Rebase", "REBASE") {
        _mint(mintRecipient_, 1_000_000 * 10 ** decimals());
        setTaxExempt(msg.sender, true);
        setTaxRecipient(taxRecipient_);
        setTaxManager(taxManager_);
        setTax(tax_);
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
    }

    function setTaxRecipient(
        address taxRecipient_
    ) public onlyOwnerOrTaxManager {
        if (taxRecipient_ == address(0)) {
            revert InvalidConfig();
        }
        taxRecipient = taxRecipient_;
    }

    function setTaxManager(address taxManager_) public onlyOwner {
        if (taxManager_ == address(0)) {
            revert InvalidConfig();
        }
        taxManager = taxManager_;
    }

    function setTax(uint256 tax_) public onlyOwnerOrTaxManager {
        if (tax_ > 15) {
            revert InvalidConfig();
        }
        tax = tax_;
    }

    function setTaxExempt(
        address account_,
        bool isTaxExempt_
    ) public onlyOwnerOrTaxManager {
        isTaxExempt[account_] = isTaxExempt_;
    }

    function shouldTakeTax(
        address sender,
        address recipient
    ) public view returns (bool) {
        return
            !isTaxExempt[sender] &&
            !isTaxExempt[recipient] &&
            sender != owner() &&
            recipient != owner() &&
            pair != address(0) &&
            (sender == pair || recipient == pair);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (shouldTakeTax(sender, recipient)) {
            uint256 taxAmount = (amount * tax) / 100;
            super._transfer(sender, recipient, amount - taxAmount);
            super._transfer(sender, taxRecipient, taxAmount);
            return;
        } else {
            super._transfer(sender, recipient, amount);
            return;
        }
    }
}