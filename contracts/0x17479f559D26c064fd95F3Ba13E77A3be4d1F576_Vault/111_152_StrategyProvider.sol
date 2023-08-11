// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "./libraries/types/DataTypes.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

//  helper contracts
import { Modifiers } from "./Modifiers.sol";

//  interfaces
import { IStrategyProvider } from "./interfaces/opty/IStrategyProvider.sol";
import { Constants } from "./utils/Constants.sol";

/**
 * @title StrategyProvider Contract
 * @author Opty.fi
 * @notice Serves as an oracle service of opty-fi's earn protocol
 * @dev Contracts contains logic for setting and getting the best and default strategy
 * as well as vault reward token strategy
 */
contract StrategyProvider is IStrategyProvider, Modifiers {
    using SafeMath for uint256;

    /**
     * @notice Mapping of RiskProfile (eg: RP1, RP2, etc) to tokensHash to the best strategy hash
     */
    mapping(uint256 => mapping(bytes32 => DataTypes.StrategyStep[])) public rpToTokenToBestStrategy;

    /**
     * @notice Mapping of RiskProfile (eg: RP1, RP2, etc) to tokensHash to best default strategy hash
     */
    mapping(uint256 => mapping(bytes32 => DataTypes.StrategyStep[])) public rpToTokenToDefaultStrategy;

    /**
     * @notice Mapping of vaultRewardToken address hash to vault reward token strategy
     */
    mapping(bytes32 => DataTypes.VaultRewardStrategy) public vaultRewardTokenHashToVaultRewardTokenStrategy;

    /* solhint-disable no-empty-blocks */
    constructor(address _registry) public Modifiers(_registry) {}

    /**
     * @inheritdoc IStrategyProvider
     */
    function setBestStrategy(
        uint256 _riskProfileCode,
        bytes32 _underlyingTokensHash,
        DataTypes.StrategyStep[] memory _strategySteps
    ) external override onlyStrategyOperator {
        delete rpToTokenToBestStrategy[_riskProfileCode][_underlyingTokensHash];
        for (uint256 _i = 0; _i < _strategySteps.length; _i++) {
            rpToTokenToBestStrategy[_riskProfileCode][_underlyingTokensHash].push(_strategySteps[_i]);
        }
    }

    /**
     * @inheritdoc IStrategyProvider
     */
    function setBestDefaultStrategy(
        uint256 _riskProfileCode,
        bytes32 _underlyingTokensHash,
        DataTypes.StrategyStep[] memory _strategySteps
    ) external override onlyStrategyOperator {
        delete rpToTokenToDefaultStrategy[_riskProfileCode][_underlyingTokensHash];
        for (uint256 _i = 0; _i < _strategySteps.length; _i++) {
            rpToTokenToDefaultStrategy[_riskProfileCode][_underlyingTokensHash].push(_strategySteps[_i]);
        }
    }

    /**
     * @inheritdoc IStrategyProvider
     */
    function setVaultRewardStrategy(
        bytes32 _vaultRewardTokenHash,
        DataTypes.VaultRewardStrategy memory _vaultRewardStrategy
    ) external override onlyStrategyOperator returns (DataTypes.VaultRewardStrategy memory) {
        vaultRewardTokenHashToVaultRewardTokenStrategy[_vaultRewardTokenHash].hold = _vaultRewardStrategy.hold;
        vaultRewardTokenHashToVaultRewardTokenStrategy[_vaultRewardTokenHash].convert = _vaultRewardStrategy.convert;
        return vaultRewardTokenHashToVaultRewardTokenStrategy[_vaultRewardTokenHash];
    }

    /**
     * @inheritdoc IStrategyProvider
     */
    function getVaultRewardTokenHashToVaultRewardTokenStrategy(bytes32 _vaultRewardTokenHash)
        public
        view
        override
        returns (DataTypes.VaultRewardStrategy memory)
    {
        return vaultRewardTokenHashToVaultRewardTokenStrategy[_vaultRewardTokenHash];
    }

    /**
     * @inheritdoc IStrategyProvider
     */
    function getRpToTokenToBestStrategy(uint256 _riskProfileCode, bytes32 _underlyingTokensHash)
        external
        view
        override
        returns (DataTypes.StrategyStep[] memory)
    {
        return rpToTokenToBestStrategy[_riskProfileCode][_underlyingTokensHash];
    }

    /**
     * @inheritdoc IStrategyProvider
     */
    function getRpToTokenToDefaultStrategy(uint256 _riskProfileCode, bytes32 _underlyingTokensHash)
        external
        view
        override
        returns (DataTypes.StrategyStep[] memory)
    {
        return rpToTokenToDefaultStrategy[_riskProfileCode][_underlyingTokensHash];
    }
}