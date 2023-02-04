//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/StorageLib.sol";

import "./ContangoNotionalProxy.sol";

/// Contract responsible for deploying ContangoVault proxies, should be inherited by ContangoNotional.sol
/// inspired by https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3PoolDeployer.sol
contract ContangoVaultProxyDeployer is IContangoNotionalProxyDeployer {
    struct ProxyParameters {
        PositionId positionId;
        address payable owner;
        address payable delegate;
        ERC20[] tokens;
    }

    ProxyParameters private params;

    function deployVaultProxy(PositionId positionId, Instrument memory instrument)
        external
        returns (PermissionedProxy proxy)
    {
        // allows for owner to collect any balance in the instrument base/quote tokens that may end up in the proxy by mistake
        ERC20[] memory tokens = new ERC20[](2);
        tokens[0] = instrument.base;
        tokens[1] = instrument.quote;

        params = ProxyParameters({
            positionId: positionId,
            owner: payable(address(this)),
            delegate: payable(address(NotionalStorageLib.NOTIONAL)),
            tokens: tokens
        });
        proxy = new ContangoNotionalProxy{salt: bytes32(PositionId.unwrap(positionId))}();
        delete params;
    }

    function proxyParameters()
        external
        view
        returns (address payable owner, address payable delegate, ERC20[] memory tokens)
    {
        owner = params.owner;
        delegate = params.delegate;
        tokens = params.tokens;
    }

    function contangoNotionalParameters() external view returns (PositionId positionId) {
        positionId = params.positionId;
    }
}