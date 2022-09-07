//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";

import "./interface/IPriceModel.sol";

/**
 * @title dForce's Oracle Contract
 * @author dForce Team.
 */
contract Oracle is Initializable, Ownable {
    using Address for address;
    /// @dev Flag for whether or not contract is paused_.
    bool internal paused_;

    /// @dev Address of the price poster.
    address internal poster_;

    /// @dev Mapping of asset addresses to priceModel.
    mapping(address => address) internal priceModel_;

    /// @dev Emitted when `priceModel_` is changed.
    event SetAssetPriceModel(address asset, address priceModel);

    /// @dev Emitted when owner either pauses or resumes the contract; `newState` is the resulting state.
    event SetPaused(bool newState);

    /// @dev Emitted when `poster_` is changed.
    event NewPoster(address oldPoster, address newPoster);

    /**
     * @notice Only for the implementation contract, as for the proxy pattern,
     *            should call `initialize()` separately.
     * @param _poster poster address.
     */
    constructor(address _poster) public {
        initialize(_poster);
    }

    /**
     * @dev Initialize contract to set some configs.
     * @param _poster poster address.
     */
    function initialize(address _poster) public initializer {
        __Ownable_init();
        _setPoster(_poster);
    }

    /**
     * @dev Throws if called by any account other than the poster.
     */
    modifier onlyPoster() {
        require(poster_ == msg.sender, "onlyPoster: caller is not the poster");
        _;
    }

    /**
     * @dev If paused, function logic is not executed.
     */
    modifier NotPaused() {
        if (!paused_) _;
    }

    /**
     * @dev If there is no price model, no functional logic is executed.
     */
    modifier hasModel(address _asset) {
        if (priceModel_[_asset] != address(0)) _;
    }

    /**
     * @notice Do not pay into Oracle.
     */
    receive() external payable {
        revert();
    }

    /**
     * @notice Set `paused_` to the specified state.
     * @dev Owner function to pause or resume the contract.
     * @param _requestedState Value to assign to `paused_`.
     */
    function _setPaused(bool _requestedState) external onlyOwner {
        paused_ = _requestedState;
        emit SetPaused(_requestedState);
    }

    /**
     * @notice Set new poster.
     * @dev Owner function to change of poster.
     * @param _newPoster New poster.
     */
    function _setPoster(address _newPoster) public onlyOwner {
        // Save current value, if any, for inclusion in log.
        address _oldPoster = poster_;
        require(
            _oldPoster != _newPoster,
            "_setPoster: poster address invalid!"
        );
        // Store poster_ = newPoster.
        poster_ = _newPoster;

        emit NewPoster(_oldPoster, _newPoster);
    }

    /**
     * @notice Set `priceModel_` for asset to the specified address.
     * @dev Function to change of priceModel_.
     * @param _asset Asset for which to set the `priceModel_`.
     * @param _priceModel Address to assign to `priceModel_`.
     */
    function _setAssetPriceModelInternal(address _asset, address _priceModel)
        internal
    {
        require(
            IPriceModel(_priceModel).isPriceModel(),
            "_setAssetPriceModelInternal: This is not the priceModel_ contract!"
        );

        priceModel_[_asset] = _priceModel;
        emit SetAssetPriceModel(_asset, _priceModel);
    }

    function _setAssetPriceModel(address _asset, address _priceModel)
        external
        onlyOwner
    {
        _setAssetPriceModelInternal(_asset, _priceModel);
    }

    function _setAssetPriceModelBatch(
        address[] calldata _assets,
        address[] calldata _priceModels
    ) external onlyOwner {
        require(
            _assets.length == _priceModels.length,
            "_setAssetStatusOracleBatch: assets & priceModels must match the current length."
        );
        for (uint256 i = 0; i < _assets.length; i++)
            _setAssetPriceModelInternal(_assets[i], _priceModels[i]);
    }

    /**
     * @notice Set the `priceModel_` to disabled.
     * @dev Function to disable of `priceModel_`.
     */
    function _disableAssetPriceModelInternal(address _asset) internal {
        priceModel_[_asset] = address(0);

        emit SetAssetPriceModel(_asset, address(0));
    }

    function _disableAssetPriceModel(address _asset) external onlyOwner {
        _disableAssetPriceModelInternal(_asset);
    }

    function _disableAssetStatusOracleBatch(address[] calldata _assets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _assets.length; i++)
            _disableAssetPriceModelInternal(_assets[i]);
    }

    /**
     * @notice Generic static call contract function.
     * @dev Static call the asset's priceModel function.
     * @param _target Target contract address (`priceModel_`).
     * @param _signature Function signature.
     * @param _data Param data.
     * @return The return value of calling the target contract function.
     */
    function _staticCall(
        address _target,
        string memory _signature,
        bytes memory _data
    ) internal view returns (bytes memory) {
        require(
            bytes(_signature).length > 0,
            "_staticCall: Parameter signature can not be empty!"
        );
        bytes memory _callData = abi.encodePacked(
            bytes4(keccak256(bytes(_signature))),
            _data
        );
        return _target.functionStaticCall(_callData);
    }

    /**
     * @notice Generic call contract function.
     * @dev Call the asset's priceModel function.
     * @param _target Target contract address (`priceModel_`).
     * @param _signature Function signature.
     * @param _data Param data.
     * @return The return value of calling the target contract function.
     */
    function _execute(
        address _target,
        string memory _signature,
        bytes memory _data
    ) internal returns (bytes memory) {
        require(
            bytes(_signature).length > 0,
            "_execute: Parameter signature can not be empty!"
        );
        bytes memory _callData = abi.encodePacked(
            bytes4(keccak256(bytes(_signature))),
            _data
        );
        return _target.functionCall(_callData);
    }

    function _executeTransaction(
        address _target,
        string memory _signature,
        bytes memory _data
    ) external onlyOwner {
        _execute(_target, _signature, _data);
    }

    function _executeTransactions(
        address[] memory _targets,
        string[] memory _signatures,
        bytes[] memory _calldatas
    ) external onlyOwner {
        for (uint256 i = 0; i < _targets.length; i++) {
            _execute(_targets[i], _signatures[i], _calldatas[i]);
        }
    }

    /**
     * @dev Config asset's priceModel
     * @param _asset Asset address.
     * @param _signature Function signature.
     * @param _data Param data.
     */
    function _setAsset(
        address _asset,
        string memory _signature,
        bytes memory _data
    ) external onlyOwner {
        _execute(address(priceModel_[_asset]), _signature, _data);
    }

    /**
     * @dev Config multiple assets priceModel
     * @param _assets Asset address list.
     * @param _signatures Function signature list.
     * @param _calldatas Param data list.
     */
    function _setAssets(
        address[] memory _assets,
        string[] memory _signatures,
        bytes[] memory _calldatas
    ) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            _execute(
                address(priceModel_[_assets[i]]),
                _signatures[i],
                _calldatas[i]
            );
        }
    }

    /**
     * @notice Entry point for updating prices.
     * @dev Set price for an asset.
     * @param _asset Asset address.
     * @param _requestedPrice Requested new price, scaled by 10**18.
     * @return Boolean ture:success, false:fail.
     */
    function _setPriceInternal(address _asset, uint256 _requestedPrice)
        internal
        returns (bool)
    {
        bytes memory _callData = abi.encodeWithSignature(
            "_setPrice(address,uint256)",
            _asset,
            _requestedPrice
        );
        (bool _success, bytes memory _returndata) = priceModel_[_asset].call(
            _callData
        );

        if (_success) return abi.decode(_returndata, (bool));
        return false;
    }

    /**
     * @dev Set price for an asset.
     * @param _asset Asset address.
     * @param _requestedPrice Requested new price, scaled by 10**18.
     * @return Boolean ture:success, false:fail.
     */
    function setPrice(address _asset, uint256 _requestedPrice)
        external
        onlyPoster
        returns (bool)
    {
        return _setPriceInternal(_asset, _requestedPrice);
    }

    /**
     * @notice Entry point for updating multiple prices.
     * @dev Set prices for a variable number of assets.
     * @param _assets A list of up to assets for which to set a price.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @param _requestedPrices Requested new prices for the assets, scaled by 10**18.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @return Boolean values in same order as inputs.
     *         For each: ture:success, false:fail.
     */
    function setPrices(
        address[] memory _assets,
        uint256[] memory _requestedPrices
    ) external onlyPoster returns (bool[] memory) {
        uint256 _numAssets = _assets.length;
        uint256 _numPrices = _requestedPrices.length;
        require(
            _numAssets > 0 && _numAssets == _numPrices,
            "setPrices: _assets & _requestedPrices must match the current length."
        );

        bool[] memory _result = new bool[](_numAssets);
        for (uint256 i = 0; i < _numAssets; i++) {
            _result[i] = _setPriceInternal(_assets[i], _requestedPrices[i]);
        }

        return _result;
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _asset Asset for which to get the price.
     * @return _price mantissa of asset price (scaled by 1e18) or zero if unset or contract paused_.
     */
    function getUnderlyingPrice(address _asset)
        external
        NotPaused
        hasModel(_asset)
        returns (uint256 _price)
    {
        _price = IPriceModel(priceModel_[_asset]).getAssetPrice(_asset);
    }

    /**
     * @notice The asset price status is provided by `priceModel_`.
     * @dev Get price status of `asset` from `priceModel_`.
     * @param _asset Asset for which to get the price status.
     * @return The asset price status is Boolean, the price status model is not set to true.true: available, false: unavailable.
     */
    function getAssetPriceStatus(address _asset)
        external
        hasModel(_asset)
        returns (bool)
    {
        return IPriceModel(priceModel_[_asset]).getAssetStatus(_asset);
    }

    /**
     * @notice Retrieve asset price and status.
     * @dev Get the price and status of the asset.
     * @param _asset The asset whose price and status are to be obtained.
     * @return _price and _status.
     */
    function getUnderlyingPriceAndStatus(address _asset)
        external
        NotPaused
        hasModel(_asset)
        returns (uint256 _price, bool _status)
    {
        (_price, _status) = IPriceModel(priceModel_[_asset])
        .getAssetPriceStatus(_asset);
    }

    /**
     * @notice Oracle status.
     * @dev Stored the value of `paused_` .
     * @return Boolean ture: paused, false: not paused.
     */
    function paused() external view returns (bool) {
        return paused_;
    }

    /**
     * @notice Poster address.
     * @dev Stored the value of `poster_` .
     * @return Address poster address.
     */
    function poster() external view returns (address) {
        return poster_;
    }

    /**
     * @notice Asset's priceModel address.
     * @dev Stored the value of asset's `priceModel_` .
     * @param _asset The asset address.
     * @return Address priceModel address.
     */
    function priceModel(address _asset) external view returns (address) {
        return priceModel_[_asset];
    }

    /**
     * @notice should update price.
     * @dev Whether the asset price needs to be updated.
     * @param _asset The asset address.
     * @param _requestedPrice New asset price.
     * @param _postSwing Min swing of the price feed.
     * @param _postBuffer Price invalidation buffer time.
     * @return bool true: can be updated; false: no need to update.
     */
    function readyToUpdate(
        address _asset,
        uint256 _requestedPrice,
        uint256 _postSwing,
        uint256 _postBuffer
    ) public view returns (bool) {
        bytes memory _callData = abi.encodeWithSignature(
            "readyToUpdate(address,uint256,uint256,uint256)",
            _asset,
            _requestedPrice,
            _postSwing,
            _postBuffer
        );
        (bool _success, bytes memory _returndata) = priceModel_[_asset]
        .staticcall(_callData);

        if (_success) return abi.decode(_returndata, (bool));
        return false;
    }

    function readyToUpdates(
        address[] memory _assets,
        uint256[] memory _requestedPrices,
        uint256[] memory _postSwings,
        uint256[] memory _postBuffers
    ) external view returns (bool[] memory) {
        uint256 _numAssets = _assets.length;

        bool[] memory _result = new bool[](_numAssets);
        for (uint256 i = 0; i < _numAssets; i++) {
            _result[i] = readyToUpdate(
                _assets[i],
                _requestedPrices[i],
                _postSwings[i],
                _postBuffers[i]
            );
        }

        return _result;
    }
}