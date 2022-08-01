// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IVersioned.sol";


interface IParametersStorage is IVersioned {

    struct CustomFee {
        bool enabled; // is custom fee for asset enabled
        uint16 feeBasisPoints; // fee basis points, 1 basis point = 0.0001
    }

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);
    event TreasuryChanged(address newTreasury);
    event OperatorTreasuryChanged(address newOperatorTreasury);
    event BaseFeeChanged(uint newFeeBasisPoints);
    event AssetCustomFeeEnabled(address indexed _asset, uint16 _feeBasisPoints);
    event AssetCustomFeeDisabled(address indexed _asset);
    event OperatorFeeChanged(uint newOperatorFeePercent);
    event CustomParamChanged(uint indexed param, bytes32 value);
    event AssetCustomParamChanged(address indexed asset, uint indexed param, bytes32 value);

    function isManager(address) external view returns (bool);

    function treasury() external view returns (address);
    function operatorTreasury() external view returns (address);

    function baseFeeBasisPoints() external view returns (uint);
    function assetCustomFee(address) external view returns (bool _enabled, uint16 _feeBasisPoints);
    function operatorFeePercent() external view returns (uint);

    function getAssetFee(address _asset) external view returns (uint _feeBasisPoints);

    function customParams(uint _param) external view returns (bytes32);
    function assetCustomParams(address _asset, uint _param) external view returns (bytes32);

    function setManager(address _who, bool _permit) external;
    function setTreasury(address _treasury) external;
    function setOperatorTreasury(address _operatorTreasury) external;

    function setBaseFee(uint _feeBasisPoints) external;
    function setAssetCustomFee(address _asset, bool _enabled, uint16 _feeBasisPoints) external;
    function setOperatorFee(uint _feeBasisPoints) external;

    function setCustomParam(uint _param, bytes32 _value) external;
    function setCustomParamAsUint(uint _param, uint _value) external;
    function setCustomParamAsAddress(uint _param, address _value) external;

    function setAssetCustomParam(address _asset, uint _param, bytes32 _value) external;
    function setAssetCustomParamAsUint(address _asset, uint _param, uint _value) external;
    function setAssetCustomParamAsAddress(address _asset, uint _param, address _value) external;
}