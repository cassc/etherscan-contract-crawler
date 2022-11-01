//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../interfaces/IOriConfig.sol";
import "./ConsiderationConstants.sol";

library ConfigHelper {
    function oriFactory(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFTFACTORY_KEY);
    }

    function isExchange(IOriConfig cfg, address acct) internal view returns (bool) {
        return cfg.getUint256(keccak256(abi.encode("EXCHANGE", acct))) == 1;
    }

    function oriAdmin(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_ORI_OWNER_KEY);
    }

    function mintFeeReceiver(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY);
    }

    function nftEditor(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFT_EDITOR_KEY);
    }

    function operator(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_OPERATPR_ALL_NFT_KEY);
    }

    function maxEarnBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_MAX_LICENSE_EARN_POINT_KEY);
    }

    function mintFeeBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_LICENSE_MINT_FEE_KEY);
    }

    function settlementHouse(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY);
    }
}