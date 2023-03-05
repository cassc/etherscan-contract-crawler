// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../LSDBase.sol";

import "../../interface/owner/ILSDOwner.sol";
import "../../interface/balance/ILSDUpdateBalance.sol";
import "../../interface/token/ILSDTokenLSETH.sol";
import "../../interface/token/ILSDTokenVELSD.sol";
import "../../interface/vault/ILSDRPVault.sol";

contract LSDUpdateBalance is LSDBase, ILSDUpdateBalance {
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        version = 1;
    }

    // Return last update virtual ETH balance time
    function getLastUpdateVitualETHBalanceTime()
        public
        view
        override
        returns (uint256)
    {
        return getUint(keccak256("lsd.virtual.eth.balance.update.time"));
    }

    // Update virtual ETH balance when deposit ETH
    function addVirtualETHBalance(uint256 _amount)
        public
        override
        onlyLSDContract("lsdTokenLSETH", msg.sender)
    {
        updateVirtualETHBalance();
        uint256 virtualETHBalance = getVirtualETHBalance();
        setVirtualETHBalance(virtualETHBalance + _amount);
        if (getLastUpdateVitualETHBalanceTime() == 0) {
            setVirtualETHBalanceTime(block.timestamp);
        }
    }

    // Update virtual ETH balance when withdraw ETH
    function subVirtualETHBalance(uint256 _amount)
        public
        override
        onlyLSDContract("lsdTokenLSETH", msg.sender)
    {
        updateVirtualETHBalance();

        uint256 virtualETHBalance = getVirtualETHBalance();
        setVirtualETHBalance(virtualETHBalance - _amount);
    }

    // Update virtual ETH per day
    function updateVirtualETHBalance() public override {
        uint256 lastTime = getLastUpdateVitualETHBalanceTime();
        uint256 ONE_DAY_IN_SECS = 24 * 60 * 60;
        if (block.timestamp >= lastTime + ONE_DAY_IN_SECS) {
            uint256 dayPassed = (block.timestamp - lastTime) / ONE_DAY_IN_SECS;
            setVirtualETHBalanceTime(lastTime + dayPassed * ONE_DAY_IN_SECS);
            ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
            uint256 apy = lsdOwner.getApy();
            uint256 apyUnit = lsdOwner.getApyUnit();
            uint256 virtualETHBalance = getVirtualETHBalance();
            setVirtualETHBalance(
                virtualETHBalance +
                    (virtualETHBalance * dayPassed * apy) /
                    365 /
                    (10**apyUnit)
            );
        }
    }

    // Set the last virtual ETH balance time
    function setVirtualETHBalanceTime(uint256 _lastTime) private {
        setUint(keccak256("lsd.virtual.eth.balance.update.time"), _lastTime);
    }

    // Set the virtual ETH blance
    function setVirtualETHBalance(uint256 _amount) private {
        setUint(keccak256("lsd.virtual.eth.balance"), _amount);
    }

    // Get the virtual ETH balance
    function getVirtualETHBalance() public view override returns (uint256) {
        return getUint(keccak256("lsd.virtual.eth.balance"));
    }

    // Total minted LS-ETH
    function getTotalLSETHSupply() public view override returns (uint256) {
        ILSDTokenLSETH lsdTokenLSETH = ILSDTokenLSETH(
            getContractAddress("lsdTokenLSETH")
        );
        return lsdTokenLSETH.totalSupply();
    }

    // Total minted veLSD
    function getTotalVELSDSupply() public view override returns (uint256) {
        ILSDTokenVELSD lsdTokenVELSD = ILSDTokenVELSD(
            getContractAddress("lsdTokenVELSD")
        );
        return lsdTokenVELSD.totalSupply();
    }

    // Total ETH balance in RP
    function getTotalETHInRP() public view override returns (uint256) {
        ILSDRPVault lsdRPVault = ILSDRPVault(getContractAddress("lsdRPVault"));
        return lsdRPVault.getETHBalance();
    }

    // Total ETH balance in RP
    function getTotalETHInLIDO() public view override returns (uint256) {
        ILSDRPVault lsdRPVault = ILSDRPVault(getContractAddress("lsdRPVault"));
        return lsdRPVault.getETHBalance();
    }

    // Total ETH balance in RP
    function getTotalETHInSWISE() public view override returns (uint256) {
        ILSDRPVault lsdRPVault = ILSDRPVault(getContractAddress("lsdRPVault"));
        return lsdRPVault.getETHBalance();
    }
}