/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

abstract contract Setter {
    function modifyParameters(bytes32, bytes32, uint256) public virtual;
}

contract UpdateCRatios {
    Setter public constant GEB_ORACLE_RELAYER =
        Setter(0x6aa9D2f366beaAEc40c3409E5926e831Ea42DC82);

    function run() external {
        updateCRatios("WSTETH-A", 1500000000000000000000000000);
        updateCRatios("WSTETH-B", 1750000000000000000000000000);
        updateCRatios("RETH-A", 1500000000000000000000000000);
        updateCRatios("RETH-B", 1750000000000000000000000000);
        updateCRatios("CBETH-A", 1500000000000000000000000000);
        updateCRatios("CBETH-B", 1750000000000000000000000000);
    }

    function updateCRatios(bytes32 collateral, uint256 cRatio) internal {
        GEB_ORACLE_RELAYER.modifyParameters(
            collateral,
            "liquidationCRatio",
            cRatio
        );
        GEB_ORACLE_RELAYER.modifyParameters(collateral, "safetyCRatio", cRatio);        
    }
}