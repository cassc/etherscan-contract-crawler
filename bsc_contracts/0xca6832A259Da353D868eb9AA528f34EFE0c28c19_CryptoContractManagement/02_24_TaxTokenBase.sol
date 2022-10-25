// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./ITaxToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

abstract contract TaxTokenBase is ITaxToken, ERC20Upgradeable {

    mapping(address => bool) public isTaxablePair;
    mapping(address => bool) public isExcludedFromRouter;

  function init(address _router, string memory name, string memory symbol) internal initializer {
    __ERC20_init(name, symbol);
    isExcludedFromRouter[msg.sender] = true;
    isExcludedFromRouter[_router] = true;
  }

    function setIsTaxablePair(address pair, bool _isTaxablePair) public {
        isTaxablePair[pair] = _isTaxablePair;
    }

    event TokenTransfer(address, address, uint256);
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
      super._beforeTokenTransfer(from, to, amount);
        // If a pair is part of a token transfer the sender or taget has to excluded.
        // That ensures we're always able to take fees on the router or let excluded
        // users choose a different router if they wish to do so.
        if(isTaxablePair[from] || isTaxablePair[to]){
            require(isExcludedFromRouter[from] || isExcludedFromRouter[to], "CCM: Router required");
        }
        emit TokenTransfer(from, to, amount);
    }


    function onTaxClaimed(address taxableToken, uint amount) external virtual { 
      require(false, "IMP: onTaxClaimed");
    }

    function takeTax(address taxableToken, address from, bool isBuy, uint amount) 
      external virtual returns(uint taxToTake){
        require(false, "IMP: takeTax");
    }

    function withdrawTax(address token, address to, uint amount) external virtual {
      require(false, "IMP: withdrawTax (probably as owner)");
    }

}