// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DataTypes } from "./libraries/types/DataTypes.sol";

//  helper contracts
import { ModifiersControllerExt } from "./ModifiersControllerExt.sol";
import { RegistryProxy } from "./RegistryProxy.sol";

//  interfaces
import { IVault } from "./interfaces/opty/IVault.sol";
import { IRegistry } from "./interfaces/opty/IRegistry.sol";
import { IContractRegistry } from "./interfaces/opty/IContractRegistry.sol";
import { Constants } from "./utils/Constants.sol";

/**
 * @title Registry Contract
 * @author Opty.fi
 * @dev Contract to persit status of tokens,lpTokens,lp/cp and Vaults
 */
contract Registry is IRegistry, ModifiersControllerExt {
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Set RegistryProxy to act as Registry
     * @param _registryProxy RegistryProxy Contract address to act as Registry
     */
    function become(RegistryProxy _registryProxy) external {
        require(msg.sender == _registryProxy.governance(), "!governance");
        require(_registryProxy.acceptImplementation() == 0, "!unauthorized");
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTreasury(address _treasury) external override onlyGovernance {
        require(_treasury != address(0), "!address(0)");
        treasury = _treasury;
        emit TransferTreasury(treasury, msg.sender);
    }

    /**
     * @inheritdoc IRegistry
     */
    function setStrategyProvider(address _strategyProvider) external override onlyOperator {
        require(IContractRegistry(_strategyProvider).registryContract() == address(this), "!registryContract");
        strategyProvider = _strategyProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setRiskManager(address _riskManager) external override onlyOperator {
        require(IContractRegistry(_riskManager).registryContract() == address(this), "!registryContract");
        riskManager = _riskManager;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setHarvestCodeProvider(address _harvestCodeProvider) external override onlyOperator {
        require(IContractRegistry(_harvestCodeProvider).registryContract() == address(this), "!registryContract");
        harvestCodeProvider = _harvestCodeProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setOPTY(address _opty) external override onlyOperator {
        opty = _opty;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setODEFIVaultBooster(address _odefiVaultBooster) external override onlyOperator {
        require(IContractRegistry(_odefiVaultBooster).registryContract() == address(this), "!registryContract");
        odefiVaultBooster = _odefiVaultBooster;
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveToken(address[] memory _tokens) external override onlyOperator {
        for (uint256 _i; _i < _tokens.length; _i++) {
            _approveToken(_tokens[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveToken(address _token) external override onlyOperator {
        _approveToken(_token);
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeToken(address[] memory _tokens) external override onlyOperator {
        for (uint256 _i; _i < _tokens.length; _i++) {
            _revokeToken(_tokens[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeToken(address _token) external override onlyOperator {
        _revokeToken(_token);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPool(address[] memory _pools) external override onlyOperator {
        for (uint256 _i; _i < _pools.length; _i++) {
            _approveLiquidityPool(_pools[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPool(address _pool) external override onlyOperator {
        _approveLiquidityPool(_pool);
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeLiquidityPool(address[] memory _pools) external override onlyOperator {
        for (uint256 _i; _i < _pools.length; _i++) {
            _revokeLiquidityPool(_pools[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeLiquidityPool(address _pool) external override onlyOperator {
        _revokeLiquidityPool(_pool);
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateLiquidityPool(DataTypes.PoolRate[] memory _poolRates) external override onlyRiskOperator {
        for (uint256 _i; _i < _poolRates.length; _i++) {
            _rateLiquidityPool(_poolRates[_i].pool, _poolRates[_i].rate);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateLiquidityPool(address _pool, uint8 _rate) external override onlyRiskOperator {
        _rateLiquidityPool(_pool, _rate);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPoolAndMapToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters)
        external
        override
        onlyOperator
    {
        for (uint256 _i; _i < _poolAdapters.length; _i++) {
            _approveLiquidityPool(_poolAdapters[_i].pool);
            _setLiquidityPoolToAdapter(_poolAdapters[_i].pool, _poolAdapters[_i].adapter);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPoolAndMapToAdapter(address _pool, address _adapter) external override onlyOperator {
        _approveLiquidityPool(_pool);
        _setLiquidityPoolToAdapter(_pool, _adapter);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveSwapPool(address[] memory _pools) external override onlyOperator {
        for (uint256 _i; _i < _pools.length; _i++) {
            _approveSwapPool(_pools[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveSwapPool(address _pool) external override onlyOperator {
        _approveSwapPool(_pool);
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeSwapPool(address[] memory _pools) external override onlyOperator {
        for (uint256 _i; _i < _pools.length; _i++) {
            _revokeSwapPool(_pools[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeSwapPool(address _pool) external override onlyOperator {
        _revokeSwapPool(_pool);
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateSwapPool(DataTypes.PoolRate[] memory _poolRates) external override onlyRiskOperator {
        for (uint256 _i; _i < _poolRates.length; _i++) {
            _rateSwapPool(_poolRates[_i].pool, _poolRates[_i].rate);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateSwapPool(address _pool, uint8 _rate) external override onlyRiskOperator {
        _rateSwapPool(_pool, _rate);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveSwapPoolAndMapToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters)
        external
        override
        onlyOperator
    {
        for (uint256 _i; _i < _poolAdapters.length; _i++) {
            _approveSwapPool(_poolAdapters[_i].pool);
            _setSwapPoolToAdapter(_poolAdapters[_i].pool, _poolAdapters[_i].adapter);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveSwapPoolAndMapToAdapter(address _pool, address _adapter) external override onlyOperator {
        _approveSwapPool(_pool);
        _setSwapPoolToAdapter(_pool, _adapter);
    }

    /**
     * @inheritdoc IRegistry
     */
    function setLiquidityPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external override onlyOperator {
        for (uint256 _i; _i < _poolAdapters.length; _i++) {
            require(liquidityPools[_poolAdapters[_i].pool].isLiquidityPool, "!liquidityPools");
            _setLiquidityPoolToAdapter(_poolAdapters[_i].pool, _poolAdapters[_i].adapter);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function setLiquidityPoolToAdapter(address _pool, address _adapter) external override onlyOperator {
        require(liquidityPools[_pool].isLiquidityPool, "!liquidityPools");
        _setLiquidityPoolToAdapter(_pool, _adapter);
    }

    /**
     * @inheritdoc IRegistry
     */
    function setSwapPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external override onlyOperator {
        for (uint256 _i; _i < _poolAdapters.length; _i++) {
            require(swapPools[_poolAdapters[_i].pool].isLiquidityPool, "!swapPools");
            _setSwapPoolToAdapter(_poolAdapters[_i].pool, _poolAdapters[_i].adapter);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function setSwapPoolToAdapter(address _pool, address _adapter) external override onlyOperator {
        require(swapPools[_pool].isLiquidityPool, "!swapPools");
        _setSwapPoolToAdapter(_pool, _adapter);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveTokenAndMapToTokensHash(DataTypes.TokensHashDetail[] memory _tokensHashesDetails)
        external
        override
        onlyOperator
    {
        for (uint256 _i; _i < _tokensHashesDetails.length; _i++) {
            for (uint256 _j; _j < _tokensHashesDetails[_i].tokens.length; _j++) {
                _approveToken(_tokensHashesDetails[_i].tokens[_j]);
            }
            _setTokensHashToTokens(_tokensHashesDetails[_i].tokensHash, _tokensHashesDetails[_i].tokens);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveTokenAndMapToTokensHash(bytes32 _tokensHash, address[] memory _tokens)
        external
        override
        onlyOperator
    {
        for (uint256 _i; _i < _tokens.length; _i++) {
            _approveToken(_tokens[_i]);
        }
        _setTokensHashToTokens(_tokensHash, _tokens);
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTokensHashToTokens(DataTypes.TokensHashDetail[] memory _tokensHashesDetails)
        external
        override
        onlyOperator
    {
        for (uint256 _i; _i < _tokensHashesDetails.length; _i++) {
            require(_areTokensApproved(_tokensHashesDetails[_i].tokens), "!tokens");
            _setTokensHashToTokens(_tokensHashesDetails[_i].tokensHash, _tokensHashesDetails[_i].tokens);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTokensHashToTokens(bytes32 _tokensHash, address[] memory _tokens) external override onlyOperator {
        require(_areTokensApproved(_tokens), "!tokens");
        _setTokensHashToTokens(_tokensHash, _tokens);
    }

    /**
     * @inheritdoc IRegistry
     */
    function addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) external override onlyRiskOperator {
        _addRiskProfile(_riskProfileCode, _name, _symbol, _poolRatingRange);
    }

    /**
     * @inheritdoc IRegistry
     */
    function addRiskProfile(
        uint256[] memory _riskProfileCodes,
        string[] memory _names,
        string[] memory _symbols,
        DataTypes.PoolRatingsRange[] memory _poolRatingRanges
    ) external override onlyRiskOperator {
        require(_riskProfileCodes.length > 0, "!length>0");
        require(_riskProfileCodes.length == _poolRatingRanges.length, "!RP_PoolRatingsLength");
        require(_riskProfileCodes.length == _names.length, "!RP_namesLength");
        require(_riskProfileCodes.length == _symbols.length, "!RP_symbolsLength");

        for (uint256 _i; _i < _riskProfileCodes.length; _i++) {
            _addRiskProfile(_riskProfileCodes[_i], _names[_i], _symbols[_i], _poolRatingRanges[_i]);
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        external
        override
        onlyRiskOperator
    {
        _updateRPPoolRatings(_riskProfileCode, _poolRatingRange);
    }

    /**
     * @inheritdoc IRegistry
     */
    function removeRiskProfile(uint256 _index) external override onlyRiskOperator {
        _removeRiskProfile(_index);
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokenHashes() public view override returns (bytes32[] memory) {
        return tokensHashIndexes;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashToTokenList(bytes32 _tokensHash) public view override returns (address[] memory) {
        return tokensHashToTokens[_tokensHash].tokens;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskProfileList() public view override returns (uint256[] memory) {
        return riskProfilesArray;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashIndexByHash(bytes32 _tokensHash) public view override returns (uint256) {
        return tokensHashToTokens[_tokensHash].index;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashByIndex(uint256 _index) public view override returns (bytes32) {
        return tokensHashIndexes[_index];
    }

    /**
     * @inheritdoc IRegistry
     */
    function isApprovedToken(address _token) public view override returns (bool) {
        return tokens[_token];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyProvider() public view override returns (address) {
        return strategyProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskProfile(uint256 _riskProfileCode) public view override returns (DataTypes.RiskProfile memory) {
        return riskProfiles[_riskProfileCode];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskManager() public view override returns (address) {
        return riskManager;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getOPTYDistributor() public view override returns (address) {
        return optyDistributor;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getODEFIVaultBooster() external view override returns (address) {
        return odefiVaultBooster;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getGovernance() public view override returns (address) {
        return governance;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getFinanceOperator() public view override returns (address) {
        return financeOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskOperator() public view override returns (address) {
        return riskOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyOperator() public view override returns (address) {
        return strategyOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getOperator() public view override returns (address) {
        return operator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getHarvestCodeProvider() public view override returns (address) {
        return harvestCodeProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getLiquidityPool(address _pool) public view override returns (DataTypes.LiquidityPool memory) {
        return liquidityPools[_pool];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getLiquidityPoolToAdapter(address _pool) public view override returns (address) {
        return liquidityPoolToAdapter[_pool];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getSwapPool(address _pool) public view override returns (DataTypes.LiquidityPool memory) {
        return swapPools[_pool];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getSwapPoolToAdapter(address _pool) public view override returns (address) {
        return swapPoolToAdapter[_pool];
    }

    function _approveToken(address _token) internal {
        tokens[_token] = true;
        emit LogToken(_token, tokens[_token], msg.sender);
    }

    function _revokeToken(address _token) internal {
        tokens[_token] = false;
        emit LogToken(_token, tokens[_token], msg.sender);
    }

    function _approveLiquidityPool(address _pool) internal {
        liquidityPools[_pool].isLiquidityPool = true;
        emit LogLiquidityPool(_pool, liquidityPools[_pool].isLiquidityPool, msg.sender);
    }

    function _revokeLiquidityPool(address _pool) internal {
        liquidityPools[_pool].isLiquidityPool = false;
        emit LogLiquidityPool(_pool, liquidityPools[_pool].isLiquidityPool, msg.sender);
    }

    function _rateLiquidityPool(address _pool, uint8 _rate) internal {
        require(liquidityPools[_pool].isLiquidityPool, "!liquidityPools");
        liquidityPools[_pool].rating = _rate;
        emit LogRateLiquidityPool(_pool, liquidityPools[_pool].rating, msg.sender);
    }

    function _approveSwapPool(address _pool) internal {
        swapPools[_pool].isLiquidityPool = true;
        emit LogSwapPool(_pool, swapPools[_pool].isLiquidityPool, msg.sender);
    }

    function _revokeSwapPool(address _pool) internal {
        swapPools[_pool].isLiquidityPool = false;
        emit LogSwapPool(_pool, swapPools[_pool].isLiquidityPool, msg.sender);
    }

    function _rateSwapPool(address _pool, uint8 _rate) internal {
        require(swapPools[_pool].isLiquidityPool, "!swapPools");
        swapPools[_pool].rating = _rate;
        emit LogRateSwapPool(_pool, swapPools[_pool].rating, msg.sender);
    }

    function _setLiquidityPoolToAdapter(address _pool, address _adapter) internal {
        require(IContractRegistry(_adapter).registryContract() == address(this), "!registryContract");
        liquidityPoolToAdapter[_pool] = _adapter;
        emit LogLiquidityPoolToAdapter(_pool, _adapter, msg.sender);
    }

    function _setSwapPoolToAdapter(address _pool, address _adapter) internal {
        require(IContractRegistry(_adapter).registryContract() == address(this), "!registryContract");
        swapPoolToAdapter[_pool] = _adapter;
        emit LogSwapPoolToAdapter(_pool, _adapter, msg.sender);
    }

    function _setTokensHashToTokens(bytes32 _tokensHash, address[] memory _tokens) internal {
        require(_isNewTokensHash(_tokensHash), "!_isNewTokensHash");
        tokensHashIndexes.push(_tokensHash);
        tokensHashToTokens[_tokensHash].index = tokensHashIndexes.length - 1;
        tokensHashToTokens[_tokensHash].tokens = _tokens;
        emit LogTokensToTokensHash(_tokensHash, msg.sender);
    }

    function _addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) internal {
        require(!riskProfiles[_riskProfileCode].exists, "RP_already_exists");
        require(bytes(_name).length > 0, "RP_name_empty");
        require(bytes(_symbol).length > 0, "RP_symbol_empty");
        riskProfilesArray.push(_riskProfileCode);
        riskProfiles[_riskProfileCode].name = _name;
        riskProfiles[_riskProfileCode].symbol = _symbol;
        riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit = _poolRatingRange.lowerLimit;
        riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit = _poolRatingRange.upperLimit;
        riskProfiles[_riskProfileCode].index = riskProfilesArray.length - 1;
        riskProfiles[_riskProfileCode].exists = true;

        emit LogRiskProfile(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].exists,
            false,
            msg.sender
        );
        emit LogRPPoolRatings(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit,
            riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit,
            msg.sender
        );
    }

    function _updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        internal
    {
        require(riskProfiles[_riskProfileCode].exists, "!Rp_Exists");
        riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit = _poolRatingRange.lowerLimit;
        riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit = _poolRatingRange.upperLimit;
        emit LogRPPoolRatings(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit,
            riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit,
            msg.sender
        );
    }

    function _removeRiskProfile(uint256 _index) internal {
        require(_index <= riskProfilesArray.length, "Invalid_Rp_index");
        uint256 _riskProfileCode = riskProfilesArray[_index];
        require(riskProfiles[_riskProfileCode].exists, "!Rp_Exists");
        riskProfiles[_riskProfileCode].exists = false;
        emit LogRiskProfile(_index, riskProfiles[_riskProfileCode].exists, false, msg.sender);
    }

    /**
     * @dev Checks duplicate tokensHash
     * @param _hash Hash of the token address/addresses
     * @return A boolean value indicating whether duplicate _hash exists or not
     */
    function _isNewTokensHash(bytes32 _hash) internal view returns (bool) {
        if (tokensHashIndexes.length == 0) {
            return true;
        }
        return (tokensHashIndexes[tokensHashToTokens[_hash].index] != _hash);
    }

    /**
     * @dev Checks approved tokens
     * @param _tokens List of the token addresses
     */
    function _areTokensApproved(address[] memory _tokens) internal view returns (bool) {
        for (uint256 _i; _i < _tokens.length; _i++) {
            if (!tokens[_tokens[_i]]) {
                return false;
            }
        }
        return true;
    }
}