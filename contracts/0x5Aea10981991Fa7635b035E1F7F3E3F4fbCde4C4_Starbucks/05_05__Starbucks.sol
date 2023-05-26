//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20Min.sol";
import "./BasicTaxableMin.sol";

contract Starbucks is BaseErc20, Taxable {

    uint256 immutable public mhAmount;

    constructor () {
        configure(0xeC7AF712762cD9E4941A41b489445f52390c076a);

        symbol = "BUCKS";
        name = "Starbucks Coin";
        decimals = 9;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new BasicTaxDistributor(routerAddress, pair, native, 3000, 3000);

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 1 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Marketing", 0, 0, 0xfF0b823CB77f14C7A130Ca241a0839748Ef0Cb51, true);
        autoSwapTax = true;

        // Max Hold
        mhAmount = 2_000_000_000_005  * 10 ** decimals;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (100_000_000_000_000 * 10 ** decimals);
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

    function setTax(uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax("Marketing", taxAmount);
        taxDistributor.setBuyTax("Marketing", taxAmount);
    }
} 