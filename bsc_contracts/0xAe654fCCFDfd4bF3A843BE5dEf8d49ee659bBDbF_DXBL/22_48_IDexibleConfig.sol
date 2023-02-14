//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../vault/interfaces/ICommunityVault.sol";
import "../oracles/IArbitrumGasOracle.sol";
import "../../common/IPausable.sol";

interface IDexibleConfig is IPausable {

    event SplitRatioChanged(uint8 newRate);
    event StdBpsChanged(uint16 newRate);
    event MinBpsChanged(uint16 newRate);
    event MinFeeChanged(uint112 newMin);
    event VaultChanged(address newVault);
    event TreasuryChanged(address newTreasury);
    event ArbGasOracleChanged(address newVault);

    function setRevshareSplitRatio(uint8 bps) external;
         
    function setStdBpsRate(uint16 bps) external;

    function setMinBpsRate(uint16 bps) external;

    function setMinFeeUSD(uint112 minFee) external;
        
    function setCommunityVault(ICommunityVault vault) external;

    function setTreasury(address t) external;
    
    function setArbitrumGasOracle(IArbitrumGasOracle oracle) external;
}