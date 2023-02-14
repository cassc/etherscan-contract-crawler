//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../VaultStorage.sol";
import "../interfaces/IStorageView.sol";

contract StorageView is IStorageView {

    function isFeeTokenAllowed(address token) external view returns (bool){
        VaultStorage.VaultData storage vs = VaultStorage.load();
        return address(vs.allowedFeeTokens[token].feed) != address(0);
    }

    function discountBps() external view returns(uint32) {
        return VaultStorage.load().dxbl.discountPerTokenBps();
    }

    function dailyVolumeUSD() external view returns(uint) {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        if(vs.lastTradeTimestamp < block.timestamp) {
            return 0;
        }
        
        return VaultStorage.load().currentVolume;
    }

    function paused() external view returns (bool) {
        return VaultStorage.load().paused;
    }

    function adminMultiSig() external view returns (address) {
        return VaultStorage.load().adminMultiSig;
    }

    function dxblToken() external view returns (address) {
        return address(VaultStorage.load().dxbl);
    }

    function dexibleContract() external view returns (address) {
        return VaultStorage.load().dexible;
    }

    function wrappedNativeToken() external view returns (address) {
        return VaultStorage.load().wrappedNativeToken;
    }

    function timelockSeconds() external view returns (uint32) {
        return VaultStorage.load().timelockSeconds;
    }

    function baseMintThreshold() external view returns (uint) {
        return VaultStorage.load().baseMintThreshold;
    }
}