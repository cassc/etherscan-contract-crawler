// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./AssetOracleAdapter.sol";
import "./Ownable.sol";
import "./IERC20Details.sol";

abstract contract NormalizingOracleAdapter is AssetOracleAdapter, Ownable {
    uint256 public _inputDecimals;
    uint256 public _outputDecimals;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        uint256 __inputDecimals,
        uint256 __outputDecimlas
    ) AssetOracleAdapter(_assetName, _assetSymbol, _asset) {
        _inputDecimals = __inputDecimals;
        _outputDecimals = __outputDecimlas;
    }

    function getInputDecimals() public view returns (uint256) {
        return _inputDecimals;
    }

    function setInputDecimals(uint256 __inputDecimals) public onlyOwner {
        _inputDecimals = __inputDecimals;
    }

    function getOutputDecimals() public view returns (uint256) {
        return _outputDecimals;
    }

    function setOutputDecimals(uint256 __outputDecimals) public onlyOwner {
        _outputDecimals = __outputDecimals;
    }

    /// @dev scales the input to from `_inputDecimals` to `_outputDecimals` decimal places
    function _normalize(uint256 _amount) internal view returns (uint256) {
        if (_inputDecimals >= _outputDecimals) {
            return _amount / 10**(_inputDecimals - _outputDecimals);
        } else {
            return _amount * (10**(_outputDecimals - _inputDecimals));
        }
    }
}
