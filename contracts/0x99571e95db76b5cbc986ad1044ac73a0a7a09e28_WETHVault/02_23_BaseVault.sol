// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IVault.sol";

abstract contract BaseVault is IVault {
    address public bridge;

    mapping(bytes32 => address) public assetIdToTokenAddress;
    mapping(address => bytes32) public tokenAddressToAssetId;
    mapping(address => bool) public tokenAllowlist;
    mapping(address => bool) public tokenBurnList;

    modifier onlyBridge() {
        require(msg.sender == bridge, "Vault: only bridge");
        _;
    }

    function setAsset(bytes32 _assetId, address _tokenAddress) external override onlyBridge {
        _setAsset(_assetId, _tokenAddress);
    }

    function setBurnable(address contractAddress) external override onlyBridge {
        _setBurnable(contractAddress);
    }

    function setNotBurnable(address contractAddress) external override onlyBridge {
        _setNotBurnable(contractAddress);
    }

    function _setAsset(bytes32 _assetId, address _tokenAddress) internal {
        assetIdToTokenAddress[_assetId] = _tokenAddress;
        tokenAddressToAssetId[_tokenAddress] = _assetId;
        tokenAllowlist[_tokenAddress] = true;
    }

    function _setBurnable(address _tokenAddress) internal {
        require(tokenAllowlist[_tokenAddress], "Vault: token is not in the allowlist");
        tokenBurnList[_tokenAddress] = true;
    }

    function _setNotBurnable(address _tokenAddress) internal {
        require(tokenAllowlist[_tokenAddress], "Vault: token is not in the allowlist");
        tokenBurnList[_tokenAddress] = false;
    }
}