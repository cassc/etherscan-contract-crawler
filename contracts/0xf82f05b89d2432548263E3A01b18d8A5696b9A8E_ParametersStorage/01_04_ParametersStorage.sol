// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Auth.sol";
import "./interfaces/IParametersStorage.sol";


contract ParametersStorage is IParametersStorage, Auth {

    string public constant VERSION = '0.1.0';

    uint public constant BASIS_POINTS_IN_1_PERCENT = 100;
    uint public constant MAX_FEE_BASIS_POINTS = 10 * BASIS_POINTS_IN_1_PERCENT;
    uint public constant MAX_OPERATOR_FEE_PERCENT = 50;

    mapping(address => bool) public isManager;

    address public treasury;
    address public operatorTreasury;
    uint public baseFeeBasisPoints = 100;
    mapping(address => CustomFee) public assetCustomFee;
    /// @notice % of total fee to send to operator treasury
    uint public operatorFeePercent = 50;

    /// @dev custom params, parameter => value, see Parameters*.sol. Does not affect assetCustomParams
    mapping(uint => bytes32) public customParams;
    mapping(address => mapping(uint => bytes32)) public assetCustomParams;

    modifier correctFee(uint fee) {
        require(fee <= MAX_FEE_BASIS_POINTS, "UP borrow module: INCORRECT_FEE_VALUE");
        _;
    }

    constructor(address _treasury, address _operatorTreasury) Auth(address(this)) {
        require(_treasury != address(0) && _operatorTreasury != address(0), "UP borrow module: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        emit ManagerAdded(msg.sender);

        treasury = _treasury;
        emit TreasuryChanged(_treasury);

        operatorTreasury = _operatorTreasury;
        emit OperatorTreasuryChanged(operatorTreasury);
    }

    function getAssetFee(address _asset) public view returns (uint _feeBasisPoints) {
        if (assetCustomFee[_asset].enabled) {
            return assetCustomFee[_asset].feeBasisPoints;
        }

        return baseFeeBasisPoints;
    }

    /**
     * @notice Grants and revokes manager's status of any address
     * @param _who The target address
     * @param _permit The permission flag
     **/
    function setManager(address _who, bool _permit) external onlyManager {
        isManager[_who] = _permit;

        if (_permit) {
            emit ManagerAdded(_who);
        } else {
            emit ManagerRemoved(_who);
        }
    }

    /**
     * @notice Sets the treasury address
     * @param _treasury The new treasury address
     **/
    function setTreasury(address _treasury) external onlyManager {
        require(_treasury != address(0), "UP borrow module: ZERO_ADDRESS");
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /**
     * @notice Sets the operator treasury address
     * @param _operatorTreasury The new operator treasury address
     **/
    function setOperatorTreasury(address _operatorTreasury) external onlyManager {
        require(_operatorTreasury != address(0), "UP borrow module: ZERO_ADDRESS");

        operatorTreasury = _operatorTreasury;
        emit OperatorTreasuryChanged(operatorTreasury);
    }

    function setBaseFee(uint _feeBasisPoints) external onlyManager correctFee(_feeBasisPoints) {
        baseFeeBasisPoints = _feeBasisPoints;
        emit BaseFeeChanged(_feeBasisPoints);
    }

    function setAssetCustomFee(address _asset, bool _enabled, uint16 _feeBasisPoints) external onlyManager correctFee(_feeBasisPoints) {
        assetCustomFee[_asset].enabled = _enabled;
        assetCustomFee[_asset].feeBasisPoints = _feeBasisPoints;

        if (_enabled) {
            emit AssetCustomFeeEnabled(_asset, _feeBasisPoints);
        } else {
            emit AssetCustomFeeDisabled(_asset);
        }
    }

    function setOperatorFee(uint _operatorFeePercent) external onlyManager {
        require(_operatorFeePercent <= MAX_OPERATOR_FEE_PERCENT, "UP borrow module: INCORRECT_FEE_VALUE");

        operatorFeePercent = _operatorFeePercent;
        emit OperatorFeeChanged(_operatorFeePercent);
    }

    function setCustomParam(uint _param, bytes32 _value) public onlyManager {
        customParams[_param] = _value;
        emit CustomParamChanged(_param, _value);
    }

    /**
     * @dev convenient way to set parameters with UI of multisig
     */
    function setCustomParamAsUint(uint _param, uint _value) public onlyManager {
        setCustomParam(_param, bytes32(_value));
    }

    /**
     * @dev convenient way to set parameters with UI of multisig
     */
    function setCustomParamAsAddress(uint _param, address _value) public onlyManager {
        setCustomParam(_param, bytes32(uint(uint160(_value))));
    }

    function setAssetCustomParam(address _asset, uint _param, bytes32 _value) public onlyManager {
        assetCustomParams[_asset][_param] = _value;
        emit AssetCustomParamChanged(_asset, _param, _value);
    }

    /**
     * @dev convenient way to set parameters with UI of multisig
     */
    function setAssetCustomParamAsUint(address _asset, uint _param, uint _value) public onlyManager {
        setAssetCustomParam(_asset, _param, bytes32(_value));
    }

    /**
     * @dev convenient way to set parameters with UI of multisig
     */
    function setAssetCustomParamAsAddress(address _asset, uint _param, address _value) public onlyManager {
        setAssetCustomParam(_asset, _param, bytes32(uint(uint160(_value))));
    }
}