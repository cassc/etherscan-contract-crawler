// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMintGateway} from "../Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "../Gateways/interfaces/ILockGateway.sol";
import {RenAssetProxyBeacon, MintGatewayProxyBeacon, LockGatewayProxyBeacon} from "./ProxyBeacon.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RenAssetFactoryState {
    RenAssetProxyBeacon internal _renAssetProxyBeacon;
    MintGatewayProxyBeacon internal _mintGatewayProxyBeacon;
    LockGatewayProxyBeacon internal _lockGatewayProxyBeacon;
}

abstract contract RenAssetFactory is Initializable, ContextUpgradeable, RenAssetFactoryState {
    event RenAssetProxyDeployed(
        uint256 chainId,
        string asset,
        string name,
        string symbol,
        uint8 decimals,
        string version
    );
    event MintGatewayProxyDeployed(string asset, address signatureVerifier, address token, string version);
    event LockGatewayProxyDeployed(string asset, address signatureVerifier, address token, string version);

    function getRenAssetProxyBeacon() public view returns (RenAssetProxyBeacon) {
        return _renAssetProxyBeacon;
    }

    function getMintGatewayProxyBeacon() public view returns (MintGatewayProxyBeacon) {
        return _mintGatewayProxyBeacon;
    }

    function getLockGatewayProxyBeacon() public view returns (LockGatewayProxyBeacon) {
        return _lockGatewayProxyBeacon;
    }

    function __RenAssetFactory_init(
        address renAssetProxyBeacon_,
        address mintGatewayProxyBeacon_,
        address lockGatewayProxyBeacon_
    ) public initializer {
        __Context_init();
        _renAssetProxyBeacon = RenAssetProxyBeacon(renAssetProxyBeacon_);
        _mintGatewayProxyBeacon = MintGatewayProxyBeacon(mintGatewayProxyBeacon_);
        _lockGatewayProxyBeacon = LockGatewayProxyBeacon(lockGatewayProxyBeacon_);
    }

    function _deployRenAsset(
        uint256 chainId,
        string calldata asset,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        string calldata version
    ) internal returns (IERC20) {
        bytes memory encodedParameters = abi.encodeWithSignature(
            "__RenAsset_init(uint256,string,string,string,uint8,address)",
            chainId,
            version,
            name,
            symbol,
            decimals,
            // Owner will be transferred to gateway
            address(this)
        );

        bytes32 create2Salt = keccak256(abi.encodePacked(asset, version));

        address renAsset = getRenAssetProxyBeacon().deployProxy(create2Salt, encodedParameters);

        emit RenAssetProxyDeployed(chainId, asset, name, symbol, decimals, version);

        return IERC20(renAsset);
    }

    function _deployMintGateway(
        string calldata asset,
        address signatureVerifier,
        address token,
        string calldata version
    ) internal returns (IMintGateway) {
        bytes memory encodedParameters = abi.encodeWithSignature(
            "__MintGateway_init(string,address,address)",
            asset,
            signatureVerifier,
            token
        );

        bytes32 create2Salt = keccak256(abi.encodePacked(asset, version));

        address mintGateway = getMintGatewayProxyBeacon().deployProxy(create2Salt, encodedParameters);

        emit MintGatewayProxyDeployed(asset, signatureVerifier, token, version);

        return IMintGateway(mintGateway);
    }

    function _deployLockGateway(
        string calldata asset,
        address signatureVerifier,
        address token,
        string calldata version
    ) internal returns (ILockGateway) {
        bytes memory encodedParameters = abi.encodeWithSignature(
            "__LockGateway_init(string,address,address)",
            asset,
            signatureVerifier,
            token
        );

        bytes32 create2Salt = keccak256(abi.encodePacked(asset, version));

        address lockGateway = getLockGatewayProxyBeacon().deployProxy(create2Salt, encodedParameters);

        emit LockGatewayProxyDeployed(asset, signatureVerifier, token, version);

        return ILockGateway(lockGateway);
    }
}