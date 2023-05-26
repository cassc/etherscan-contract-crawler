//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20Min.sol";
import "./BasicTaxableMin.sol";

contract Jared is BaseErc20, Taxable {

    uint256 immutable public mhAmount;

    constructor () {
        configure(0xE167B3654fA47F5b14a3120afF2747bb9Bd3C73c);

        symbol = "JARED";
        name = "Jared Coin";
        decimals = 18;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new BasicTaxDistributor(routerAddress, pair, native, 3000, 2000);

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 1 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Marketing", 2000, 3000, 0x55a57dE02C3cD913B846B3Ffcc17110D63625bFa, true);
        autoSwapTax = true;

        // Max Hold
        mhAmount = 8_413_800_005  * 10 ** decimals;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (420_690_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // Overrides

    function configure(address _owner) internal override(Taxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(Taxable, BaseErc20) internal {      
        if (launched && 
            from != owner && to != owner && 
            exchanges[to] == false && 
            to != getRouterAddress()
        ) {
            require (_balances[to] + value <= mhAmount, "this is over the max hold amount");
        }
        
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

} 