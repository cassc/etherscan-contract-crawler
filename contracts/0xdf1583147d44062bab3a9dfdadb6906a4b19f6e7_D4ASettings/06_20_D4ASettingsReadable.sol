// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4ASettingsBaseStorage.sol";
import "./ID4ASettingsReadable.sol";

contract D4ASettingsReadable is ID4ASettingsReadable {
    function permissionControl() public view returns (IPermissionControl) {
        return D4ASettingsBaseStorage.layout().permission_control;
    }

    function ownerProxy() public view returns (ID4AOwnerProxy) {
        return D4ASettingsBaseStorage.layout().owner_proxy;
    }

    function mintProtocolFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_d4a_fee_ratio;
    }

    function protocolFeePool() public view returns (address) {
        return D4ASettingsBaseStorage.layout().protocol_fee_pool;
    }

    function tradeProtocolFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().trade_d4a_fee_ratio;
    }

    function mintProjectFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_project_fee_ratio;
    }

    function mintProjectFeeRatioFlatPrice() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_project_fee_ratio_flat_price;
    }

    function ratioBase() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().ratio_base;
    }

    function createProjectFee() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().create_project_fee;
    }

    function createCanvasFee() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().create_canvas_fee;
    }

    function defaultNftPriceMultiplyFactor() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().defaultNftPriceMultiplyFactor;
    }
}