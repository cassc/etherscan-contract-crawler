//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";
import "./FixedTaxable.sol";
import "./TaxDistributor.sol";

contract Landwolf is BaseErc20, FixedTaxable {

    constructor () {
        configure(0xfbfEaF0DA0F2fdE5c66dF570133aE35f3eB58c9A);

        symbol = "WOLF";
        name = "Landwolf";
        decimals = 18;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address native = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(native, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, native, 500, 500);

        // Tax
        minimumTimeBetweenSwaps = 1 seconds;
        minimumTokensBeforeSwap = 1 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Marketing", 400, 400, 0x821B2b0a9d1CE32a9e691414F6EDe2B9ACE03138, true);
        autoSwapTax = true;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (420_690_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
    function setTaxWallet(address wallet) external onlyOwner {
        require(msg.sender == taxDistributor.getTaxWallet("Marketing"), "Only the tax wallet can change its address");
        taxDistributor.setTaxWallet("Marketing", wallet);
        emit ConfigurationChanged(msg.sender, "change to tax wallet");
    }
} 