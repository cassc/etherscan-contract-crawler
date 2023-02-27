//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Burnable.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./AntiSniper.sol";

contract XPatInk is BaseErc20, AntiSniper, Burnable, Taxable {

    mapping(address => bool) public zkManualEnable;
    uint256 public zkTokenThreshold;

    constructor () {
        configure(0xE6fb6350f3b70C63b764e9E678DB8e13CdD3fD72);

        symbol = "XINK";
        name = "XPAT Ink";
        decimals = 18;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, WBNB, 1300, 1300);

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;
        mhPercentage = 300;
        enableHighTaxCountdown = true;

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 10000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Listing", 190, 190, 0xE6fb6350f3b70C63b764e9E678DB8e13CdD3fD72, true);
        taxDistributor.createWalletTax("Marketing", 185, 185, 0x28c47Ee37f1A358bCB55365Aa3F155EEf5A7f25D, true);
        taxDistributor.createWalletTax("Dev", 125, 125, 0x9dF336BCf2B5BDb4F4dD854e539853F3a25A3C96, true);
        autoSwapTax = false;

        // Burnable
        ableToBurn[address(taxDistributor)] = true;

        // ZK
        zkManualEnable[owner] = true;
        zkTokenThreshold = 240_000 * 10 ** decimals;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (24_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }

    // Public Functions

    function allowZk(address who) external view returns(bool) {
        return zkManualEnable[who] || _balances[who] >= zkTokenThreshold;
    }

    // Admin Functions
    function setManualZK(address who, bool on) external onlyOwner {
        zkManualEnable[who] = on;
    }

    function setZkTokenThreshold(uint256 amount) external onlyOwner {
        zkTokenThreshold = amount;
    }
}