// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {YoSifuStargateVault} from "./YoSifuStargateVault.sol";
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

import {IStargatePool} from "./interfaces/IStargatePool.sol";

/// @title Yield Optimized Sifu Factory (Stargate Vault)
contract YoSifuStargateVaultFactory is Owned {
    using Bytes32AddressLib for bytes32;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the Stargate Staking contract
    address public immutable stargateStaking;

    /// @notice address of the Stargate Router contract
    address public immutable stargateRouter;

    /// @notice address of the Stargate Token contract
    ERC20 public immutable STG;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogVaultCreated(
        YoSifuStargateVault indexed vault,
        ERC20 indexed asset,
        ERC20 indexed underlyingAsset
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the Factory parameters, Stargate Staking, Router, Token and the Owner
    /// @param _stargateStaking Address of the Stargate Staking contract
    /// @param _stargateRouter Address of the Stargate Router contract
    /// @param _STG Address of the Stargate Token
    /// @param _owner Address of the Owner of this Factory
    constructor(
        address _stargateStaking,
        address _stargateRouter,
        ERC20 _STG,
        address _owner
    ) Owned(_owner) {
        stargateStaking = _stargateStaking;
        stargateRouter = _stargateRouter;
        STG = _STG;
    }

    /// @notice Deploys a new YoSifuStargate vault for the given asset
    /// @dev The asset should be supported by the stargate. Only owner can deploy new vaults
    /// @param asset The Base Asset which will be used in the vault i.e. Stargate Pool Tokens
    /// @param pid The pid of the asset in the staking contract
    /// @param feeTo Address of the fee receiver for this vault
    /// @param owner Address of the owner of this vault
    function createVault(
        ERC20 asset,
        uint256 pid,
        address feeTo,
        address owner
    ) external onlyOwner returns (YoSifuStargateVault vault) {
        ERC20 underlyingAsset = ERC20(IStargatePool(address(asset)).token());
        uint256 poolId = IStargatePool(address(asset)).poolId();

        vault = new YoSifuStargateVault{salt: bytes32(0)}(
            asset,
            underlyingAsset,
            stargateStaking,
            stargateRouter,
            STG,
            poolId,
            pid,
            feeTo,
            owner
        );

        emit LogVaultCreated(vault, asset, underlyingAsset);
    }

    function computeVaultAddress(
        ERC20 asset,
        uint256 pid,
        address feeTo,
        address owner
    ) external view returns (YoSifuStargateVault vault) {
        ERC20 underlyingAsset = ERC20(IStargatePool(address(asset)).token());
        uint256 poolId = IStargatePool(address(asset)).poolId();

        vault = YoSifuStargateVault(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        type(YoSifuStargateVault).creationCode,
                        abi.encode(
                            asset,
                            underlyingAsset,
                            stargateStaking,
                            stargateRouter,
                            STG,
                            poolId,
                            pid,
                            feeTo,
                            owner
                        )
                    )
                )
            )
        );
    }

    function _computeCreate2Address(bytes32 bytecodeHash)
        internal
        view
        virtual
        returns (address)
    {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0xFF),
                    address(this),
                    bytes32(0),
                    bytecodeHash
                )
            ).fromLast20Bytes();
    }
}