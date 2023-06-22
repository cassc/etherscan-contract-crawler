// SPDX-License-Identifier: MIT

/*
  A Managed Token, part of the AI Managed Token Suite - AIMM.

  AIMM is a DeFi market maker with community engagement tooling built in, anyone can create a ManagedToken using our factories
  permissionlessly onchain, and benefit from our on and offchain tooling to provide intelligent tax settings, buyback and liquidity
  functions. By deriving your project's ERC20 token from a ManagedToken, users can be sure by checking the verified Solidity code of:
   - Tax is hard coded as max 5/5.
   - Visibility of Maximum Tx Amount is surfaced
   - Check whether Maximum Tx Amount is frozen.
   - Check whether Tax is frozen.

  Using our ManagedTokenTreasury, users can be sure that the portion of Tax's raised to be part of the protocol cannot be rugged by
  project owners, as there are no functions to withdraw either ETH or ERC20 from the Treasury. Protocols have to enter, before Tax is taken
  on a sale, the portion they are taking for their project. This is hard coded to be capped at 50%.

  AIMM takes a revenue share of 1% of the Tax collected by the treasury, for future development of the protocol and maintence costs.

  Website: https://aimm.tech/
  Twitter: https://twitter.com/AIMMtech
  Telegram: https://t.me/AIMMtech
  GitHub: https://github.com/aimm-evm/
*/

pragma solidity >=0.8.16;

import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {IManagedTokenTreasury} from "src/interfaces/IManagedTokenTreasury.sol";
import {IManagedTokenTaxProvider} from "src/interfaces/IManagedTokenTaxProvider.sol";

contract ManagedToken is ERC20Burnable {
    IManagedTokenTreasury public treasury;
    IManagedTokenTaxProvider public taxProvider;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply, address mintTo)
        ERC20(name_, symbol_)
    {
        if (totalSupply > 0) {
            _mint(mintTo, totalSupply);
        }
    }

    function setTreasury(IManagedTokenTreasury treasury_) public {
        require(address(treasury) == address(0), "Treasury is already set.");
        treasury = treasury_;
    }

    function setTaxProvider(IManagedTokenTaxProvider taxProvider_) public {
        require(address(taxProvider) == address(0), "Tax Provider is already set.");
        taxProvider = taxProvider_;
    }

    /**
     * This overridden internal function `_transfer` uses the `IManagedTokenTaxProvider` to calculate the tax,
     * then uses the default `_transfer` function to send the tax and original transfer.
     * The `onTaxSent` function is invoked to allow the `IManagedTokenTreasury` to process any sent funds.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        IManagedTokenTaxProvider _taxProvider = taxProvider;
        if (address(_taxProvider) != address(0)) {
            uint256 tax = _taxProvider.getTax(from, to, amount);
            uint256 amountTransferring = amount - tax;

            if (tax > 0) {
                IManagedTokenTreasury _treasury = treasury;
                super._transfer(from, address(_treasury), tax);
                _treasury.onTaxSent(tax, _msgSender());
            }

            super._transfer(from, to, amountTransferring);
        } else {
            super._transfer(from, to, amount);
        }
    }
}