// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokensEvents.sol";

import "../../MultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperActors.sol";
import "../helpers/MultiVaultHelperTokens.sol";


contract MultiVaultFacetTokens is
    MultiVaultHelperActors,
    MultiVaultHelperTokens,
    IMultiVaultFacetTokens
{
    function getInitHash() public pure returns(bytes32) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    /// @notice Get token prefix
    /// @dev Used to set up in advance prefix for the ERC20 native token
    /// @param _token Token address
    /// @return Name and symbol prefix
    function prefixes(
        address _token
    ) external view override returns (IMultiVaultFacetTokens.TokenPrefix memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.prefixes_[_token];
    }

    /// @notice Get token information
    /// @param _token Token address
    function tokens(
        address _token
    ) external view override returns (IMultiVaultFacetTokens.Token memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.tokens_[_token];
    }

    /// @notice Get native Everscale token address for EVM token
    /// @param _token Token address
    function natives(
        address _token
    ) external view override returns (IEverscale.EverscaleAddress memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.natives_[_token];
    }

    /// @notice Set prefix for native token
    /// @param token Expected native token address, see note on `getNative`
    /// @param name_prefix Name prefix, leave empty for no-prefix
    /// @param symbol_prefix Symbol prefix, leave empty for no-prefix
    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external override onlyGovernanceOrManagement {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        TokenPrefix memory prefix = s.prefixes_[token];

        if (prefix.activation == 0) {
            prefix.activation = block.number;
        }

        prefix.name = name_prefix;
        prefix.symbol = symbol_prefix;

        s.prefixes_[token] = prefix;
    }

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.tokens_[token].blacklisted = blacklisted;
    }

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view override returns (address token) {
        token = _getNativeToken(native);
    }
}