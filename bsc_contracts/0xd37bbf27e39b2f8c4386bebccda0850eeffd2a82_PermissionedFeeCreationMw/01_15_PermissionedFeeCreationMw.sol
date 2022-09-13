// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";

import { Constants } from "../../libraries/Constants.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";

import { EIP712 } from "../../base/EIP712.sol";
import { PermissionedMw } from "../base/PermissionedMw.sol";
import { FeeMw } from "../base/FeeMw.sol";

/**
 * @title Permissioned Fee Creation Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to create permissioned fee.
 */
contract PermissionedFeeCreationMw is
    IProfileMiddleware,
    EIP712,
    PermissionedMw,
    FeeMw
{
    event SetFeeByTier(
        address indexed namespace,
        Tier tier,
        uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address signer;
        address recipient;
        mapping(address => uint256) nonces;
        mapping(Tier => uint256) feeMapping;
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5,
        Tier6
    }

    mapping(address => MiddlewareData) internal _mwDataByNamespace;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks that the namespace is valid.
     */
    modifier onlyValidNamespace(address namespace) {
        address mwData = _mwDataByNamespace[namespace].recipient;
        require(mwData != address(0), "INVALID_NAMESPACE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address engine, address treasury)
        PermissionedMw(engine)
        FeeMw(treasury)
    {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileMiddleware
    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable override onlyValidNamespace(msg.sender) {
        MiddlewareData storage mwData = _mwDataByNamespace[msg.sender];

        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresValidHandle(params.handle);
        _requiresEnoughFee(msg.sender, params.handle, msg.value);
        _requiresValidSig(params, v, r, s, deadline, mwData);

        uint256 treasuryCollected = (msg.value * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualCollected = msg.value - treasuryCollected;

        Address.sendValue(payable(mwData.recipient), actualCollected);
        if (treasuryCollected > 0) {
            Address.sendValue(payable(_treasuryAddress()), treasuryCollected);
        }
    }

    /// @inheritdoc IProfileMiddleware
    function postProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external override {
        // do nothing
    }

    /// @inheritdoc IProfileMiddleware
    function setProfileMwData(address namespace, bytes calldata data)
        external
        override
        onlyEngine
        returns (bytes memory)
    {
        (
            address signer,
            address recipient,
            uint256 tier0Fee,
            uint256 tier1Fee,
            uint256 tier2Fee,
            uint256 tier3Fee,
            uint256 tier4Fee,
            uint256 tier5Fee,
            uint256 tier6Fee
        ) = abi.decode(
                data,
                (
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        require(
            signer != address(0) && recipient != address(0),
            "INVALID_SIGNER_OR_RECIPIENT"
        );

        _setFeeByTier(namespace, Tier.Tier0, tier0Fee);
        _setFeeByTier(namespace, Tier.Tier1, tier1Fee);
        _setFeeByTier(namespace, Tier.Tier2, tier2Fee);
        _setFeeByTier(namespace, Tier.Tier3, tier3Fee);
        _setFeeByTier(namespace, Tier.Tier4, tier4Fee);
        _setFeeByTier(namespace, Tier.Tier5, tier5Fee);
        _setFeeByTier(namespace, Tier.Tier6, tier6Fee);

        _mwDataByNamespace[namespace].signer = signer;
        _mwDataByNamespace[namespace].recipient = recipient;

        return data;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the signer address.
     *
     * @param namespace The namespace address.
     * @return address The signer address.
     */
    function getSigner(address namespace) external view returns (address) {
        return _mwDataByNamespace[namespace].signer;
    }

    /**
     * @notice Gets the recipient address.
     *
     * @param namespace The namespace address.
     * @return address The recipient address.
     */
    function getRecipient(address namespace) external view returns (address) {
        return _mwDataByNamespace[namespace].recipient;
    }

    /**
     * @notice Gets the nonce of the address.
     *
     * @param namespace The namespace address.
     * @param user The user address.
     * @return uint256 The nonce.
     */
    function getNonce(address namespace, address user)
        external
        view
        returns (uint256)
    {
        return _mwDataByNamespace[namespace].nonces[user];
    }

    /**
     * @notice Gets the tier's fee.
     *
     * @param namespace The namespace address.
     * @param tier The tier.
     * @return uint256 The fee amount.
     */
    function getFeeByTier(address namespace, Tier tier)
        external
        view
        returns (uint256)
    {
        return _mwDataByNamespace[namespace].feeMapping[tier];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _setFeeByTier(
        address namespace,
        Tier tier,
        uint256 amount
    ) internal {
        _mwDataByNamespace[namespace].feeMapping[tier] = amount;
        emit SetFeeByTier(namespace, tier, amount);
    }

    function _requiresEnoughFee(
        address namespace,
        string calldata handle,
        uint256 amount
    ) internal view {
        bytes memory byteHandle = bytes(handle);
        MiddlewareData storage mwData = _mwDataByNamespace[namespace];
        uint256 fee = mwData.feeMapping[Tier.Tier6];

        if (byteHandle.length < 7) {
            fee = mwData.feeMapping[Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "INSUFFICIENT_FEE");
    }

    function _requiresValidHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            "HANDLE_INVALID_LENGTH"
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                "HANDLE_INVALID_CHARACTER"
            );
            unchecked {
                ++i;
            }
        }
    }

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "PermissionedFeeCreationMw";
    }

    function _requiresValidSig(
        DataTypes.CreateProfileParams calldata params,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline,
        MiddlewareData storage mwData
    ) internal {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CREATE_PROFILE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        params.operator,
                        mwData.nonces[params.to]++,
                        deadline
                    )
                )
            ),
            mwData.signer,
            v,
            r,
            s,
            deadline
        );
    }
}