//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/IDexibleConfig.sol";
import "../DexibleStorage.sol";
import "./AdminBase.sol";

abstract contract ConfigBase is AdminBase, IDexibleConfig {

    event ConfigChanged(DexibleStorage.DexibleConfig config);
    event RelayAdded(address relay);
    event RelayRemoved(address relay);

    function configure(DexibleStorage.DexibleConfig memory config) public {
        DexibleStorage.DexibleData storage ds = DexibleStorage.load();
        if(ds.adminMultiSig != address(0)) {
            require(msg.sender == ds.adminMultiSig, "Unauthorized");
        }

        require(config.communityVault != address(0), "Invalid CommunityVault address");
        require(config.treasury != address(0), "Invalid treasury");
        require(config.dxblToken != address(0), "Invalid DXBL token address");
        require(config.revshareSplitRatio > 0, "Invalid revshare split ratio");
        require(config.stdBpsRate > 0, "Must provide a standard bps fee rate");
        require(config.minBpsRate > 0, "minBpsRate is required");
        require(config.minBpsRate < config.stdBpsRate, "Min bps rate must be less than std");

        ds.adminMultiSig = config.adminMultiSig;
        ds.revshareSplitRatio = config.revshareSplitRatio;
        ds.communityVault = ICommunityVault(config.communityVault);
        ds.treasury = config.treasury;
        ds.dxblToken = IDXBL(config.dxblToken);
        ds.stdBpsRate = config.stdBpsRate;
        ds.minBpsRate = config.minBpsRate;
        ds.minFeeUSD = config.minFeeUSD; //can be 0
        ds.arbitrumGasOracle = IArbitrumGasOracle(config.arbGasOracle);

        for(uint i=0;i<config.initialRelays.length;++i) {
            ds.relays[config.initialRelays[i]] = true;
        }
        emit ConfigChanged(config);
    }

    function addRelays(address[] calldata relays) external onlyAdmin {
        DexibleStorage.DexibleData storage ds = DexibleStorage.load();
        for(uint i=0;i<relays.length;++i) {
            ds.relays[relays[i]] = true;
            emit RelayAdded(relays[i]);
        }
    }

    function removeRelay(address relay) external onlyAdmin {
        DexibleStorage.DexibleData storage ds = DexibleStorage.load();
        delete ds.relays[relay];
        emit RelayRemoved(relay);
    }

    function setRevshareSplitRatio(uint8 bps) external onlyAdmin {
        DexibleStorage.load().revshareSplitRatio = bps;
        emit SplitRatioChanged(bps);
    }
         
    function setStdBpsRate(uint16 bps) external onlyAdmin {
        DexibleStorage.load().stdBpsRate = bps;
        emit StdBpsChanged(bps);
    }

    function setMinBpsRate(uint16 bps) external onlyAdmin {
        DexibleStorage.load().minBpsRate = bps;
        emit MinBpsChanged(bps);
    }

    function setMinFeeUSD(uint112 minFee) external onlyAdmin {
        DexibleStorage.load().minFeeUSD = minFee;
        emit MinFeeChanged(minFee);
    }
        
    function setCommunityVault(ICommunityVault vault) external onlyVault {
        DexibleStorage.load().communityVault = vault;
        emit VaultChanged(address(vault));
    }

    function setTreasury(address t) external onlyAdmin {
        DexibleStorage.load().treasury = t;
        emit TreasuryChanged(t);
    }
    
    function setArbitrumGasOracle(IArbitrumGasOracle oracle) external onlyAdmin {
        DexibleStorage.load().arbitrumGasOracle = oracle;
        emit ArbGasOracleChanged(address(oracle));
    }

    function pause() external onlyAdmin {
        DexibleStorage.load().paused = true;
        emit Paused();
    }

    function resume() external onlyAdmin {
        DexibleStorage.load().paused = false;
        emit Resumed();
    }
}