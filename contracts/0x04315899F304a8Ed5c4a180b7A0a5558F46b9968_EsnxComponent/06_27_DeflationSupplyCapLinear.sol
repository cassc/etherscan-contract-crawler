// SPDX-License-Identifier: MIT
// Creator: Ctor Lab (https://ctor.xyz)

pragma solidity ^0.8.0;


library DeflationSupplyCapLinear {
    error ExceedSupplyCap();
    error InvalidDecayPeriod();

    // All the parameters are packed into a single storage slot for gas saving.
    // In practice, 2** 32 token supply is enough for most of the NFT applications.
    struct DeflationSupplyCapLinearParameter{
        uint64 decayPeriod; // The time for supply cap to decay if no minting events happend.
        uint32 lastSupplyCap; // The supply cap of the last minting event.
        uint32 supplyDecay; // Amount of reduction in the supply cap every `decayPeriod`.
        uint64 lastMint; // Timestamp of the last minting event.
    }

    /// @dev Insert this function in the minting logic.
    function checkMintingAndUpdate(
        DeflationSupplyCapLinearParameter storage param,
        uint256 totalMinted,
        uint256 numToMint
    ) internal {
        uint256 supplyCap = currentSupplyCap(param);
        if(numToMint + totalMinted > supplyCap ) {
            revert ExceedSupplyCap();
        }

        if(block.timestamp > param.lastMint) {
            param.lastMint = uint64(block.timestamp);
            param.lastSupplyCap = uint32(supplyCap);
        }
    }

    function currentSupplyCap(
        DeflationSupplyCapLinearParameter storage param
    ) internal view returns (uint256) {
        uint256 time = block.timestamp;
        if (time < param.lastMint) {
            return param.lastSupplyCap;
        }

        if(param.decayPeriod == 0) {
            return 0;
        }
        uint256 reduction = 0;
        unchecked {
            reduction = (time - uint256(param.lastMint)) / uint256(param.decayPeriod) * param.supplyDecay;
        }
        
        if(reduction > param.lastSupplyCap) {
            return 0;
        }
        unchecked {
            return param.lastSupplyCap - reduction;
        }
    }

    /// @dev Calculate the number of token that is still available to be minted.
    function availableToMint(
        DeflationSupplyCapLinearParameter storage param,
        uint256 totalMinted
    ) internal view returns (uint256){
        uint256 supplyCap = currentSupplyCap(param);
        if(supplyCap > totalMinted) {
            unchecked {
                return supplyCap - totalMinted;
            }  
        } 
        return 0;
    }


    function initializeParam(
        DeflationSupplyCapLinearParameter storage param,
        uint64 decayStart,
        uint64 decayPeriod,
        uint32 initialSupply,
        uint32 supplyDecay
    ) internal {
        if(decayPeriod == 0) {
            revert InvalidDecayPeriod();
        }
        
        param.decayPeriod = decayPeriod;
        param.lastSupplyCap = initialSupply;
        param.supplyDecay = supplyDecay;
        param.lastMint = decayStart;
    }

}