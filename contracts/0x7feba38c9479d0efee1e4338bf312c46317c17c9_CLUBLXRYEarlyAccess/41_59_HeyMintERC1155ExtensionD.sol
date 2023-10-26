// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig, Data, BurnToken} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionD is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ CONFIG ============

    /**
     * @notice Returns config storage variables for the contract
     */
    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            bool,
            uint16[] memory
        )
    {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return (
            state.cfg,
            state.advCfg,
            state.data.advancedConfigInitialized,
            state.data.tokenIds
        );
    }

    /**
     * @notice Updates the base configuration for the contract
     */
    function _updateBaseConfig(BaseConfig memory _baseConfig) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _baseConfig.heyMintFeeActive == state.cfg.heyMintFeeActive,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.enforceRoyalties == state.cfg.enforceRoyalties,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        state.cfg = _baseConfig;
    }

    /**
     * @notice Updates the base configuration for the contract
     */
    function updateBaseConfig(
        BaseConfig memory _baseConfig
    ) external onlyOwner {
        return _updateBaseConfig(_baseConfig);
    }

    /**
     * @notice Updates the advanced configuration for the contract
     */
    function _updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _advancedConfig.payoutAddresses.length ==
                _advancedConfig.payoutBasisPoints.length,
            "PAYOUT_ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _advancedConfig.payoutBasisPoints.length; i++) {
            totalBasisPoints += _advancedConfig.payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "BASIS_POINTS_MUST_EQUAL_10000");
        if (state.advCfg.payoutAddressesFrozen) {
            require(
                _advancedConfig.payoutAddressesFrozen,
                "PAYOUT_ADDRESSES_FROZEN"
            );
            bool payoutInfoChanged = false;
            for (
                uint256 i = 0;
                i < _advancedConfig.payoutAddresses.length;
                i++
            ) {
                if (
                    _advancedConfig.payoutAddresses[i] !=
                    state.advCfg.payoutAddresses[i]
                ) {
                    payoutInfoChanged = true;
                    break;
                }
            }
            require(!payoutInfoChanged, "PAYOUT_ADDRESSES_FROZEN");
            for (
                uint256 i = 0;
                i < _advancedConfig.payoutBasisPoints.length;
                i++
            ) {
                if (
                    _advancedConfig.payoutBasisPoints[i] !=
                    state.advCfg.payoutBasisPoints[i]
                ) {
                    payoutInfoChanged = true;
                    break;
                }
            }
            require(!payoutInfoChanged, "PAYOUT_ADDRESSES_FROZEN");
        }
        state.advCfg = _advancedConfig;
        state.data.advancedConfigInitialized = true;
    }

    /**
     * @notice Updates the advanced configuration for the contract
     */
    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external onlyOwner {
        return _updateAdvancedConfig(_advancedConfig);
    }

    /**
     * @notice Returns token storage variables for the contract
     */
    function getTokenSettings(
        uint16 tokenId
    ) external view returns (TokenConfig memory, BurnToken[] memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return (state.tokens[tokenId], state.burnTokens[tokenId]);
    }

    /**
     * @notice Creates or updates a token based on the tokenId
     */
    function upsertToken(TokenConfig memory _tokenConfig) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _tokenConfig.maxSupply >=
                state.data.totalSupply[_tokenConfig.tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        require(
            _tokenConfig.presaleMaxSupply >=
                state.data.totalSupply[_tokenConfig.tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        require(
            _tokenConfig.publicSaleStartTime == 0 ||
                _tokenConfig.publicSaleStartTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.publicSaleEndTime == 0 ||
                _tokenConfig.publicSaleEndTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.presaleStartTime == 0 ||
                _tokenConfig.presaleStartTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.presaleEndTime == 0 ||
                _tokenConfig.presaleEndTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            !state.data.tokenMetadataFrozen[_tokenConfig.tokenId] &&
                !state.data.allMetadataFrozen,
            "ALL_METADATA_FROZEN"
        );
        require(
            !state.data.tokenMetadataFrozen[_tokenConfig.tokenId] ||
                keccak256(bytes(_tokenConfig.tokenUri)) ==
                keccak256(bytes(state.tokens[_tokenConfig.tokenId].tokenUri)),
            "METADATA_FROZEN"
        );
        require(
            _tokenConfig.refundEndsAt >=
                state.tokens[_tokenConfig.tokenId].refundEndsAt,
            "REFUND_DURATION_CANNOT_BE_DECREASED"
        );
        require(
            state.tokens[_tokenConfig.tokenId].refundPrice == 0 ||
                state.tokens[_tokenConfig.tokenId].refundPrice ==
                _tokenConfig.refundPrice,
            "REFUND_PRICE_CANNOT_BE_CHANGED"
        );

        state.tokens[_tokenConfig.tokenId] = _tokenConfig;
        // add the token id to the tokenIds array if it doesn't already exist
        for (uint256 i = 0; i < state.data.tokenIds.length; i++) {
            if (state.data.tokenIds[i] == _tokenConfig.tokenId) {
                return;
            }
        }
        state.data.tokenIds.push(_tokenConfig.tokenId);
    }

    /**
     * @notice Updates all of the token IDs on the contract.
     */
    function _setTokenIds(uint16[] memory _tokenIds) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();

        uint256 oldLength = state.data.tokenIds.length;
        uint256 newLength = _tokenIds.length;

        // Update the existing token ids & push any new ones.
        for (uint256 i = 0; i < newLength; i++) {
            if (i < oldLength) {
                state.data.tokenIds[i] = _tokenIds[i];
                state.tokens[_tokenIds[i]].tokenId = _tokenIds[i];
            } else {
                state.data.tokenIds.push(_tokenIds[i]);
                state.tokens[_tokenIds[i]].tokenId = _tokenIds[i];
            }
        }

        // Pop any extra token ids.
        for (uint256 i = oldLength; i > newLength; i--) {
            state.data.tokenIds.pop();
        }
    }

    /**
     * @notice Updates all of the token IDs on the contract.
     */
    function setTokenIds(uint16[] memory _tokenIds) external onlyOwner {
        return _setTokenIds(_tokenIds);
    }

    /**
     * @notice Set the details of the tokens to be burned in order to mint a token
     * @param _tokenIds The ids of the token on the contract to update
     * @param _burnConfigs An array of arrays of all tokens required for burning
     */
    function _updateBurnTokens(
        uint16[] memory _tokenIds,
        BurnToken[][] memory _burnConfigs
    ) internal {
        require(
            _tokenIds.length == 0 || _tokenIds.length == _burnConfigs.length,
            "BURN_CONFIGS_LENGTH_MUST_MATCH_TOKENS_LENGTH"
        );
        HeyMintStorage.State storage state = HeyMintStorage.state();

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 tokenId = _tokenIds[i];

            uint256 oldBurnTokensLength = state.burnTokens[tokenId].length;
            uint256 newBurnTokensLength = _burnConfigs[i].length;

            // Update the existing BurnTokens and push any new BurnTokens
            for (uint256 j = 0; j < newBurnTokensLength; j++) {
                if (j < oldBurnTokensLength) {
                    state.burnTokens[tokenId][j] = _burnConfigs[i][j];
                } else {
                    state.burnTokens[tokenId].push(_burnConfigs[i][j]);
                }
            }

            // Pop any extra BurnTokens if the new array is shorter
            for (
                uint256 j = oldBurnTokensLength;
                j > newBurnTokensLength;
                j--
            ) {
                state.burnTokens[tokenId].pop();
            }
        }
    }

    /**
     * @notice Set the details of the tokens to be burned in order to mint a token
     * @param _tokenIds The ids of the token on the contract to update
     * @param _burnConfigs An array of arrays of all tokens required for burning
     */
    function updateBurnTokens(
        uint16[] calldata _tokenIds,
        BurnToken[][] calldata _burnConfigs
    ) external onlyOwner {
        return _updateBurnTokens(_tokenIds, _burnConfigs);
    }

    /**
     * @notice Update the full config (base config + adv config + all tokens + burn tokens) on the contract.
     */
    function updateFullConfig(
        BaseConfig memory _baseConfig,
        TokenConfig[] memory _tokenConfigs,
        AdvancedConfig memory _advancedConfig,
        BurnToken[][] memory _burnTokens
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _burnTokens.length == 0 ||
                _burnTokens.length == _tokenConfigs.length,
            "BURN_CONFIGS_LENGTH_MUST_MATCH_TOKENS_LENGTH"
        );
        uint16[] memory tokenIds = new uint16[](_tokenConfigs.length);
        for (uint256 i = 0; i < _tokenConfigs.length; i++) {
            tokenIds[i] = _tokenConfigs[i].tokenId;
        }
        _updateBaseConfig(_baseConfig);
        _updateAdvancedConfig(_advancedConfig);
        state.data.advancedConfigInitialized = true;
        _setTokenIds(tokenIds);
        _updateBurnTokens(tokenIds, _burnTokens);
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setTokenUri(
        uint16 _tokenId,
        string calldata _newTokenURI
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(!state.data.allMetadataFrozen, "ALL_METADATA_FROZEN");
        require(
            !state.data.tokenMetadataFrozen[_tokenId],
            "TOKEN_METADATA_FROZEN"
        );
        state.tokens[_tokenId].tokenUri = _newTokenURI;
    }

    /**
     * @notice Returns a token-specific URI, if configured. Otherwise, returns an empty string.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.tokens[uint16(_tokenId)].tokenUri;
    }

    /**
     * @notice Update the global default ERC-1155 base URI
     */
    function setGlobalUri(string calldata _newTokenURI) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(!state.data.allMetadataFrozen, "ALL_METADATA_FROZEN");
        state.cfg.uriBase = _newTokenURI;
    }
}