// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../security/Locker.sol";
import "hardhat/console.sol";

contract CFlatsToken is ERC20, Locker, Ownable {
    uint256 private constant _ONE_DAY = 86_400;

    uint256 public constant MARKET_CAP =    1_500_000_000_000_000_000; // 15 billion
    uint256 public constant TEAM_CAP =      120_000_000_000_000_000;   // 1.2 billion (8%)
    uint256 public constant LP_CAP =        570_000_000_000_000_000;   // 5.7 billion (38%)
    uint256 public constant COMUNITY_CAP =  810_000_000_000_000_000;   // 8.1 billion (54%)


    uint24 public constant FEE = 6; // 6%
    uint24 public constant FEE_DENOMINATOR = 100; // 100%


    address public immutable TEAM_WALLET;
    address public LP_ADDRESS;

    constructor(address teamWallet) 
    ERC20("Cryptoflats", "CFLAT") {
        TEAM_WALLET = teamWallet;

        _mint(_msgSender(), MARKET_CAP);
    }

    

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    
    function setLp(address lpAddress) external lockWithDelay(_ONE_DAY * 3) {
        LP_ADDRESS = lpAddress;
    }


    function burn(address account, uint256 amount) external onlyOwner returns (bool) {
        super._burn(account, amount);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // don't do any action just standard transfer event
        if(amount == 0)
        {
            super._transfer(from, to, amount);
            return;
        }

        // 6% tax fee
        // tax = amount * 6% / 100%
        uint256 tax = amount * FEE / FEE_DENOMINATOR;

        // 3% tax fee
        uint256 taxHalfed = tax / 2;

        uint256 transferAmount = tax == 0 ? amount : amount - tax;

        super._transfer(from, to, transferAmount);


        // don't call this events for gas saving if tax is 0
        if(taxHalfed != 0)
        {
            // if there is no lp address setted transfer full tax to team wallet
            // otherwise transfer halfed tax
            bool isLpAddressZero = LP_ADDRESS == address(0);
            uint256 calculatedTax = isLpAddressZero == true ? tax : taxHalfed;

            super._transfer(from, TEAM_WALLET, calculatedTax);

            if(isLpAddressZero == false)
            {
                super._transfer(from, LP_ADDRESS, taxHalfed);
            }
        }
    }

}