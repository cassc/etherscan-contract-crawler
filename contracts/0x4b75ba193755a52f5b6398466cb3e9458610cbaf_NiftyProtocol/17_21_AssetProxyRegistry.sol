pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/LibBytes.sol";
import "./interfaces/IAssetData.sol";
import "./interfaces/IAssetProxy.sol";
import "./interfaces/IAssetProxyRegistry.sol";


contract AssetProxyRegistry is
    Ownable,
    IAssetProxyRegistry
{
    using LibBytes for bytes;

    // Mapping from Asset Proxy Id's to their respective Asset Proxy
    mapping (bytes4 => address) internal _assetProxies;

    /// @dev Registers an asset proxy to its asset proxy id.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        override
        external
        onlyOwner
    {
        // Ensure that no asset proxy exists with current id.
        bytes4 assetProxyId = IAssetProxy(assetProxy).getProxyId();
        // Add asset proxy and log registration.
        _assetProxies[assetProxyId] = assetProxy;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return assetProxy The asset proxy address registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        override
        external
        view
        returns (address assetProxy)
    {
        return _assetProxies[assetProxyId];
    }

    function _isERC20Proxy(bytes memory assetData)
        internal
        pure
        returns (bool)
    {
        bytes4 assetProxyId = assetData.readBytes4(0);
        bytes4 erc20ProxyId = IAssetData(address(0)).ERC20Token.selector;

        return assetProxyId == erc20ProxyId;
    }

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function _dispatchTransfer(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        // Do nothing if no amount should be transferred.
        if (amount > 0) {

            // Ensure assetData is padded to 32 bytes (excluding the id) and is at least 4 bytes long
            if (assetData.length % 32 != 4) {
                revert('ASSET PROXY: invalid length');
            }

            // Lookup assetProxy.
            bytes4 assetProxyId = assetData.readBytes4(0);
            address assetProxy = _assetProxies[assetProxyId];

            // Ensure that assetProxy exists
            if (assetProxy == address(0)) {
                revert('ASSET PROXY: unknown');
            }

            bool ethPayment = false;

            if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
                address erc20TokenAddress = assetData.readAddress(4);
                ethPayment = erc20TokenAddress == address(0);
            }

            if (ethPayment) {
                if (address(this).balance < amount) {
                    revert("ASSET PROXY: insufficient balance");
                }
                payable(to).transfer(amount);
            } else {
                // Construct the calldata for the transferFrom call.
                bytes memory proxyCalldata = abi.encodeWithSelector(
                    IAssetProxy(address(0)).transferFrom.selector,
                    assetData,
                    from,
                    to,
                    amount
                );

                // Call the asset proxy's transferFrom function with the constructed calldata.
                (bool didSucceed, ) = assetProxy.call(proxyCalldata);

                // If the transaction did not succeed, revert with the returned data.
                if (!didSucceed) {
                    revert("ASSET PROXY: transfer failed");
                }
            }
        }
    }
}