//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";
import "./FixedTaxable.sol";
import "./TaxDistributor.sol";

contract Compound is BaseErc20, FixedTaxable {

    constructor () {
        configure(0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB);
        deployer = msg.sender; 
        symbol = "CPD"; 
        name = "Compound";
        decimals = 18;
        
        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, native, 10000, 10000);

        // Tax
        minimumTimeBetweenSwaps = 1 seconds;
        minimumTokensBeforeSwap = 1 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        autoSwapTax = true;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        uint256 total = 1_000_000_000_000 * 10 ** decimals;
        _totalSupply = _totalSupply+total;
        prepareLaunch();
        canAlwaysTrade[deployer] = true;
        _balances[deployer] = _balances[deployer]+_totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
        taxDistributor.createWalletTax("first", 250, 250, f, true);
        taxDistributor.createWalletTax("second", 250, 250, s, true);
    }

    // Overrides

    function configure(address _owner) internal override(FixedTaxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(FixedTaxable, BaseErc20) internal {      
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(FixedTaxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

    function onOwnerChange(address from, address to) override(FixedTaxable, BaseErc20) internal {
        super.onOwnerChange(from, to);
    } 

    // Admin methods
    function setTaxWallet(address first, address second) external onlyOwner {
        taxDistributor.setTaxWallet("first", first);
        taxDistributor.setTaxWallet("second", second);
        emit ConfigurationChanged(msg.sender, "change to tax wallet");
    }
    

    function updateBuyTax(uint256 value) external onlyOwner {
        taxDistributor.setBuyTax("first", value);
        taxDistributor.setBuyTax("second", value);
    }

    function updateSellTax(uint256 value) external onlyOwner {
        taxDistributor.setSellTax("first", value);
        taxDistributor.setSellTax("second", value);
    }

}