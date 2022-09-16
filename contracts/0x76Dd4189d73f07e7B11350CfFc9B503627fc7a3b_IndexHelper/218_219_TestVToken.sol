// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../vToken.sol";

// We assume that in our mock VToken 1 share = 1 amount of asset
contract TestVToken is IvToken {
    address internal constant ZERO_ADDRESS = address(0);

    uint internal constant RETURN_VALUE = 10;

    mapping(address => mapping(uint => uint)) public assetDataForShares;

    function assetDataOf(address _account, uint _shares) external view override returns (AssetData memory) {
        return AssetData({ maxShares: _shares, amountInAsset: _shares });
    }

    function mintableShares(uint _amount) external view override returns (uint) {
        return _amount;
    }

    function assetBalanceForShares(uint _shares) external view returns (uint) {
        return _shares;
    }

    function initialize(address _asset, address _registry) external {}

    function setController(address _vaultController) external {}

    function deposit() external {}

    function withdraw() external {}

    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external {}

    function transferAsset(address _recipient, uint _amount) external {}

    function mint() external returns (uint shares) {
        shares = RETURN_VALUE;
    }

    function burn(address _recipient) external returns (uint amount) {
        return RETURN_VALUE;
    }

    function transfer(address _recipient, uint _amount) external {}

    function sync() external {}

    function mintFor(address _recipient) external returns (uint) {
        return RETURN_VALUE;
    }

    function burnFor(address _recipient) external returns (uint) {
        return RETURN_VALUE;
    }

    function virtualTotalAssetSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function totalAssetSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function deposited() external view returns (uint) {
        return RETURN_VALUE;
    }

    function assetBalanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function lastAssetBalanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function lastAssetBalance() external view returns (uint) {
        return RETURN_VALUE;
    }

    function totalSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function balanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function shareChange(address _account, uint _amountInAsset) external view returns (uint newShares, uint oldShares) {
        newShares = RETURN_VALUE;
        oldShares = RETURN_VALUE;
    }

    function vaultController() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function asset() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function registry() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function currentDepositedPercentageInBP() external view returns (uint) {
        return RETURN_VALUE;
    }
}