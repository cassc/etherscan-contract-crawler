//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./IArbOnePrecompile.sol";
import "./IArbitrumGasOracle.sol";

contract ArbitrumGasOracle is IArbitrumGasOracle {
    IArbOnePrecompile constant ARBINFO = IArbOnePrecompile(address(uint160(0x6c)));

    //controller to set the multiplier
    address adminMultiSig;

    //expressed in 18-decs
    uint public multiplier;

    event MultiplierChanged(uint multiplier);

    modifier onlyAdmin() {
        require(msg.sender == adminMultiSig, "Unauthorized");
        _;
    }

    constructor(address multiSig, uint m) {
        adminMultiSig = multiSig;
        multiplier = m;
    }

    function changeAdmin(address newMultiSig) public onlyAdmin {
        adminMultiSig = newMultiSig;
    }

    function setMultiplier(uint m) public onlyAdmin {
        multiplier = m;
        emit MultiplierChanged(m);
    }

    /**
     * Calculate the gas cost for an arbitrum txn. This is needed for contracts that 
     * compute gas costs using gasleft() calls in solidity. The Arbitrum nodes do not accurately
     * reflect actual gas used yet. So given the mis-calculated gasused and call data size
     * this function will apply a multipler to the L1 gas fee to compute the estimated gas 
     * cost for the txn.
     */
    function calculateGasCost(uint callDataSize, uint l2GasUsed) public view returns (uint) {
        (,uint l1Fee,,,,) = ARBINFO.getPricesInWei();
        //the multiplier is expressed in 18decimals so have to divide that out for final result
        return (l2GasUsed*tx.gasprice) + ((multiplier * l1Fee * callDataSize)/1e18);
    }
}