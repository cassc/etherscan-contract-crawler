// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {MarryStrgtVault} from "./MarryStrgtVault.sol";
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

import {IStrgtPool} from "./interfaces/IStrgtPool.sol";

/// @title Yield Optimized Mary Factory (Strgt Vault)
contract MarryStrgtVaultFactory is Owned {
    using Bytes32AddressLib for bytes32;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the Strgt Staking contract
    address public immutable strgtStaking;

    /// @notice address of the Strgt Router contract
    address public immutable strgtRouter;

    /// @notice address of the Strgt Token contract
    ERC20 public immutable STG;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogVaultCreated(
        MarryStrgtVault indexed vault,
        ERC20 indexed asset,
        ERC20 indexed underlyingAsset
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the Factory parameters, Strgt Staking, Router, Token and the Owner
    /// @param _strgtStaking Address of the Strgt Staking contract
    /// @param _strgtRouter Address of the Strgt Router contract
    /// @param _STG Address of the Strgt Token
    /// @param _owner Address of the Owner of this Factory
    constructor(
        address _strgtStaking,
        address _strgtRouter,
        ERC20 _STG,
        address _owner
    ) Owned(_owner) {
        strgtStaking = _strgtStaking;
        strgtRouter = _strgtRouter;
        STG = _STG;
    }

    /// @notice Deploys a new YoSifuStargate vault for the given asset
    /// @dev The asset should be supported by the strgt. Only owner can deploy new vaults
    /// @param asset The Base Asset which will be used in the vault i.e. Strgt Pool Tokens
    /// @param pid The pid of the asset in the staking contract
    /// @param feeTo Address of the fee receiver for this vault
    /// @param owner Address of the owner of this vault
    function createVault(
        ERC20 asset,
        uint256 pid,
        address feeTo,
        address owner
    ) external onlyOwner returns (MarryStrgtVault vault) {
        ERC20 underlyingAsset = ERC20(IStrgtPool(address(asset)).token());
        uint256 poolId = IStrgtPool(address(asset)).poolId();

        vault = new MarryStrgtVault{salt: bytes32(0)}(
            asset,
            underlyingAsset,
            strgtStaking,
            strgtRouter,
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
    ) external view returns (MarryStrgtVault vault) {
        ERC20 underlyingAsset = ERC20(IStrgtPool(address(asset)).token());
        uint256 poolId = IStrgtPool(address(asset)).poolId();

        vault = MarryStrgtVault(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        type(MarryStrgtVault).creationCode,
                        abi.encode(
                            asset,
                            underlyingAsset,
                            strgtStaking,
                            strgtRouter,
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