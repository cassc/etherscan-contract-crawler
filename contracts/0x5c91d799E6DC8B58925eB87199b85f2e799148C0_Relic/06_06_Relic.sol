// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "Ownable.sol";

contract Relic is ERC20, Ownable {
    constructor(uint256 _initialTaxRate) ERC20("Relic", "Relic") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
        setTaxWallet(0xE02a641B18de2D8C4aa9eFB1a577d5eA241e9243);
        setTaxRate(_initialTaxRate);
    }

    function setTaxWallet(address _newTaxWallet) public onlyOwner {
        ERC20.taxWallet = _newTaxWallet;
    }

    function setTaxRate(uint256 _newTaxRate) public onlyOwner {
        require(_newTaxRate <= 15, "Tax Rate cannot be set more than 15%");
        ERC20.taxRate = _newTaxRate;
    }
    
    function setExcludingWallet(address _newExcludingWallet) public onlyOwner {
        ERC20.excludingWallet = _newExcludingWallet;
    }

    function withdraw() public payable onlyOwner {
  
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }  
}