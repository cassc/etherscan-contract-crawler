// SPDX-License-Identifier: MIT
/**

Website: https://ercsimple.xyz
Telegram: https://t.me/ercsimple
Twitter: https://twitter.com/ercsimple

* Simple (SIMPLE)
*
*In the crypto world, scams are everyehre. Trust is scarce. 95% of new tokens aim to deceive or profit at your expense.
*
* Simple stands out - clean code, rigorous audits, no hidden traps. Simplicity is perfection in crypto.
*
* Every line of code ensures transparency and trust. We redefine the standards for a safe and reliable investment.
*
* Contract Features:
* - Clean and Audited Code 
* - No Team Tokens -> 100% tokens Pink Pre-Sale -> Liquidity -> No massive selloffs
* - Locked Liquidity -> Pink Lock -> No Rug Pulls
* - 5% burn tax on every transaction -> Hyper-deflationary -> Moon
* - Contract Ownership Renounced -> No owner privileges or functions
*
* Join us in our mission to redefine trust and create a brighter future for the community.
*
* Learn more at ercsimple.xyz.
*
**/

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Import Ownable contract, Ownership will be renounced after the presale is finalized

contract Simple is ERC20, Ownable(address(msg.sender)) { // Needed to set the Pink Sale presale address. Ownership will be renounced after the presale is finalized
    uint256 private constant BURN_RATE = 5; // 5% burn rate

    address private pinkSaleAddress;

    constructor(uint256 initialSupply) ERC20("Simple", "SIMPLE") {
    _mint(msg.sender, initialSupply * (10**uint256(decimals())));
    pinkSaleAddress = address(0); 
    }


    // Set the Pink Sale address after deployment
    function setPinkSaleAddress(address _pinkSaleAddress) external onlyOwner { // Pink Sale presale address
        pinkSaleAddress = _pinkSaleAddress;
    }

    // Transfer function with burn mechanism
    function transfer(address to, uint256 value) public override returns (bool) {
        require(value > 0, "ERC20: Transfer value must be greater than zero");

        uint256 burnvalue;
        uint256 transfervalue;

        if (
            msg.sender != owner() && // Check if the sender is not the owner
            msg.sender != pinkSaleAddress &&
            to != owner() && // Check if the recipient is not the owner
            to != pinkSaleAddress
        ) {
            burnvalue = (value * BURN_RATE) / 100;
            transfervalue = value - burnvalue;
        } else {
            burnvalue = 0;
            transfervalue = value;
        }

        if (burnvalue > 0) {
            _burn(msg.sender, burnvalue);
        }

        _transfer(msg.sender, to, transfervalue);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(value > 0, "ERC20: Transfer value must be greater than zero");

        uint256 burnvalue;
        uint256 transfervalue;

        address spender = _msgSender();

        if (
            from != owner() && // Check if the sender is not the owner
            from != pinkSaleAddress &&
            to != owner() && // Check if the recipient is not the owner
            to != pinkSaleAddress
        ) {
            burnvalue = (value * BURN_RATE) / 100;
            transfervalue = value - burnvalue;
        } else {
            burnvalue = 0;
            transfervalue = value;
        }

        if (burnvalue > 0) {
            _burn(from, burnvalue);
        }
        

        _spendAllowance(from, spender, value);
        _transfer(from, to, transfervalue);

        return true;
    }

}