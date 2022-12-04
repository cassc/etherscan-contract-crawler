//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract Dividends is BaseErc20 {
    IDividendDistributor dividendDistributor;
    bool public autoDistributeDividends;
    mapping (address => bool) public excludedFromDividends;
    uint256 dividendDistributorGas;
    

    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromDividends[_owner] = true;
        super.configure(_owner);
    }
    
    function postTransfer(address from, address to) internal virtual override {
        if (excludedFromDividends[from] == false) {
            dividendDistributor.setShare(from, _balances[from]);
        }
        if (excludedFromDividends[to] == false) {
            dividendDistributor.setShare(to, _balances[to]);
        }

        if (
            launched && 
            autoDistributeDividends &&
            exchanges[from] && 
            dividendDistributor.inSwap() == false
        ) {
            try dividendDistributor.process(dividendDistributorGas) {} catch {}
        }

        super.postTransfer(from, to);
    }
    
    // Public methods
    
    /**
     * @dev Return the address of the dividend distributor contract
     */
    function dividendDistributorAddress() public view returns (address) {
        return address(dividendDistributor);
    }
    
    
    // Admin methods
    
    function setDividendDistributionThresholds(uint256 minAmount, uint256 minTime, uint256 gas) external virtual onlyOwner {
        dividendDistributorGas = gas;
        dividendDistributor.setDistributionCriteria(minTime, minAmount);
    }

    function setAutoDistributeDividends(bool enabled) external onlyOwner {
        autoDistributeDividends = enabled;
    }

    function setIsDividendExempt(address who, bool isExempt) external onlyOwner {
        require(who != address(this), "this address cannot receive shares");
        excludedFromDividends[who] = isExempt;
        if (isExempt){
            dividendDistributor.setShare(who, 0);
        } else {
            dividendDistributor.setShare(who, _balances[who]);
        }
    }

    function runDividendsManually(uint256 gas) external onlyOwner {
        dividendDistributor.process(gas);
    }
    

}