// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokensEvents.sol";
import "../../interfaces/IEverscale.sol";

import "../../MultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";
import "./MultiVaultHelperEmergency.sol";


abstract contract MultiVaultHelperTokens is
    MultiVaultHelperEmergency,
    IMultiVaultFacetTokensEvents
{
    modifier initializeToken(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (s.tokens_[token].activation == 0) {
            // Non-activated tokens are always aliens, native tokens are activate on the first `saveWithdrawNative`

            require(
                IERC20Metadata(token).decimals() <= MultiVaultStorage.DECIMALS_LIMIT &&
                bytes(IERC20Metadata(token).symbol()).length <= MultiVaultStorage.SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(token).name()).length <= MultiVaultStorage.NAME_LENGTH_LIMIT
            );

            _activateToken(token, false);
        }

        _;
    }

    modifier tokenNotBlacklisted(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.tokens_[token].blacklisted);

        _;
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint depositFee = isNative ? s.defaultNativeDepositFee : s.defaultAlienDepositFee;
        uint withdrawFee = isNative ? s.defaultNativeWithdrawFee : s.defaultAlienWithdrawFee;

        s.tokens_[token] = IMultiVaultFacetTokens.Token({
            activation: block.number,
            blacklisted: false,
            isNative: isNative,
            depositFee: depositFee,
            withdrawFee: withdrawFee,
            custom: address(0)
        });

        emit TokenActivated(
            token,
            block.number,
            isNative,
            depositFee,
            withdrawFee
        );
    }

    function _getNativeWithdrawalToken(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal
    ) internal returns (address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        // Derive native token address from the Everscale (token wid, token addr)
        address token = _getNativeToken(withdrawal.native);

        // Token is being withdrawn first time - activate it (set default parameters)
        // And deploy ERC20 representation
        if (s.tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            s.natives_[token] = withdrawal.native;
        }

        // Check if there is a custom ERC20 representing this withdrawal.native
        address custom = s.tokens_[token].custom;

        if (custom != address(0)) return custom;

        return token;
    }

    function _increaseCash(
        address token,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.liquidity[token].cash += amount;
    }

    /// @notice Gets the address
    /// @param native Everscale token address
    /// @return token Token address
    function _getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) internal view returns (address token) {
        token = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(native.wid, native.addr)),
            hex'192c19818bebb5c6c95f5dcb3c3257379fc46fb654780cb06f3211ee77e1a360' // MultiVaultToken init code hash
        )))));
    }

    function _deployTokenForNative(
        IEverscale.EverscaleAddress memory native,
        IMultiVaultFacetTokens.TokenMeta memory meta
    ) internal returns (address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Check custom prefix available
        IMultiVaultFacetTokens.TokenPrefix memory prefix = s.prefixes_[token];

        string memory name_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_NAME_PREFIX : prefix.name;
        string memory symbol_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_SYMBOL_PREFIX : prefix.symbol;

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked(name_prefix, meta.name)),
            string(abi.encodePacked(symbol_prefix, meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            name_prefix,
            symbol_prefix,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }
}