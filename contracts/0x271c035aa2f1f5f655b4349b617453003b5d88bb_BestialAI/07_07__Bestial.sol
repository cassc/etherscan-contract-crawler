//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";
import "./Burnable.sol";
import "./FixedTaxable.sol";
import "./TaxDistributor.sol";

contract BestialAI is BaseErc20, FixedTaxable, Burnable {

    uint256 immutable public mhAmount;
    address immutable public deployer;

    constructor () {
        configure(0x307868f2f59239F43920D8a8868F67dDe032Bad5);
        deployer = msg.sender;

        symbol = "BESTAI";
        name = "Bestial AI";
        decimals = 18;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, native, 400, 400);

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 10000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Insight", 158, 158, 0xf5157FB14Aa7Bf18329bbF6853B6b3cd9B8b4E46, true);
        taxDistributor.createWalletTax("Marketing", 158, 158, 0xAd626D137B377906843714303593F040175c0522, true);
        taxDistributor.createWalletTax("Dev", 80, 80, 0xDDE6D88587469f95d43E97C3f48495D8869c5b3b, true);
        taxDistributor.createWalletTax("Neuroni", 4, 4, 0xA281151C22a70d6743F5b31Bc4E3958ce3681985, true);
        autoSwapTax = true;

        // Max Hold
        mhAmount = 100_000 * 10 ** decimals;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (10_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides

    function configure(address _owner) internal override(FixedTaxable, Burnable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(FixedTaxable, BaseErc20) internal {
        
        if (launched && 
            from != owner && to != owner && 
            from != deployer && to != deployer && 
            exchanges[to] == false && 
            to != address(taxDistributor)
        ) {
            require (_balances[to] + value <= mhAmount, "this is over the max hold amount");
        }
        
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(FixedTaxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

    function onOwnerChange(address from, address to) override(FixedTaxable, Burnable, BaseErc20) internal {
        super.onOwnerChange(from, to);
        ableToBurn[deployer] = true;
    } 
} 