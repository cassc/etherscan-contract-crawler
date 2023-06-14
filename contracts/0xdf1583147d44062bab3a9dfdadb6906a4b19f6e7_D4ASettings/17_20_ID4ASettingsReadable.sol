// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4ASettingsBaseStorage.sol";

interface ID4ASettingsReadable {
    function permissionControl() external view returns (IPermissionControl);

    function ownerProxy() external view returns (ID4AOwnerProxy);

    function mintProtocolFeeRatio() external view returns (uint256);

    function protocolFeePool() external view returns (address);

    function tradeProtocolFeeRatio() external view returns (uint256);

    function mintProjectFeeRatio() external view returns (uint256);

    function mintProjectFeeRatioFlatPrice() external view returns (uint256);

    function ratioBase() external view returns (uint256);

    function createProjectFee() external view returns (uint256);

    function createCanvasFee() external view returns (uint256);

    function defaultNftPriceMultiplyFactor() external view returns (uint256);
}