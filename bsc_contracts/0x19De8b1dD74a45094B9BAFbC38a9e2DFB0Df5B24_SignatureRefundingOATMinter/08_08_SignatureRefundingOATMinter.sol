// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignatureOATMinter.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract SignatureRefundingOATMinter is SignatureOATMinter {

    uint256 private constant GAS_OVERHEAD = 31_592;
    uint256 private constant GAS_OVERHEAD_PER_ID = 143;
    uint256 private constant GAS_PRICE_MAX = 6 gwei;


    constructor(address OAT) 
        SignatureOATMinter(OAT) 
    {
    }


    modifier refundGas(address recipient, uint256 overhead) {
        uint256 gasUsed = gasleft();
        _;
        gasUsed = gasUsed - gasleft();
        _refundGas(recipient, gasUsed + overhead);
    }


    function fundGasRefunds() external payable {
    }

    function mintBatchAndRefundGas(address recipient, uint256[] calldata ids, bytes memory signature) 
        public 
        virtual 
        refundGas(recipient, GAS_OVERHEAD + (ids.length * GAS_OVERHEAD_PER_ID)) 
    {
        super.mintBatch(recipient, ids, signature);
    }


    function _refundGas(address recipient, uint256 gas) internal {
        uint256 gasPrice = tx.gasprice < GAS_PRICE_MAX ? tx.gasprice : GAS_PRICE_MAX;
        uint256 gasCost = gas * gasPrice;
        uint256 balance = address(this).balance;

        if (balance > 0) {
            if (balance < gasCost) {
                gasCost = balance;
            }

            Address.sendValue(payable(recipient), gasCost);
        }
    }
}