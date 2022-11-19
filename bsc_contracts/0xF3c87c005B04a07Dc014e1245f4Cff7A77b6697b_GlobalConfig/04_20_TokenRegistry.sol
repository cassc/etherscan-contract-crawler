// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../lib/Utils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

import "../../governance/InitializableGovernable.sol";
import "../interfaces/IGlobalConfig.sol";
import "../config/Constant.sol";

/**
 * @dev Token Info Registry to manage Token information
 *      The Owner of the contract allowed to update the information
 */
contract TokenRegistry is InitializableGovernable, Constant {
    using SafeMath for uint256;
    using SafeCast for int256;

    // no initialization for constants per pool
    uint256 public constant DEFAULT_BORROW_LTV = 60;
    uint256 public constant MAX_TOKENS = 128;
    uint256 public constant MAX_BORROW_LTV = 90;
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable EXPIRE_DURATION;

    /**
     * @dev TokenInfo struct stores Token Information, this includes:
     *      ERC20 Token address, Compound Token address, ChainLink Aggregator address etc.
     * @notice This struct will consume 5 storage locations
     */
    struct TokenInfo {
        // Token index, can store upto 255
        uint8 index;
        // ERC20 Token decimal
        uint8 decimals;
        // If token is enabled / disabled
        bool enabled;
        // Is Token supported on Compound
        bool isSupportedOnCompound;
        // cToken address on Compound
        address cToken;
        // Chain Link Aggregator address for TOKEN/ETH pair
        address chainLinkOracle;
        // Borrow LTV, by default 60%
        uint256 borrowLTV;
    }

    // globalConfig should be initialized per pool
    IGlobalConfig public globalConfig;
    address public poolRegistry;

    // TokenAddress to TokenInfo mapping
    mapping(address => TokenInfo) public tokenInfo;

    // mining speeds
    mapping(address => uint256) public depositeMiningSpeeds;
    mapping(address => uint256) public borrowMiningSpeeds;

    // TokenAddress array
    address[] public tokens;

    // Events
    event TokenAdded(address indexed token);

    event TokenBorrowLTVUpdated(address indexed token, uint256 borrowLTV);
    event TokenChainlinkAggregatorUpdated(address indexed token, address oldAggregator, address newAggregator);
    event TokenEnableUpdate(address indexed token, bool enabled);
    event TokenUpdated(address indexed token);

    modifier whenTokenExists(address _token) {
        require(isTokenExist(_token), "Token not exists");
        _;
    }

    modifier onlyPoolRegistry() {
        require(msg.sender == poolRegistry, "not called from PoolRegistry");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == poolRegistry || msg.sender == governor(), "not authorized");
        _;
    }

    constructor(uint256 _expireDuration) {
        EXPIRE_DURATION = _expireDuration;
    }

    /**
     *  initializes the symbols structure
     * @notice This only initializes once, as 'initializer' modifier is used in parent contract
     */
    function initialize(
        address _gemGlobalConfig,
        address _poolRegistry,
        IGlobalConfig _globalConfig
    ) external {
        _initialize(_gemGlobalConfig);
        poolRegistry = _poolRegistry;
        globalConfig = _globalConfig;
    }

    function addTokenByPoolRegistry(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) external onlyPoolRegistry {
        _addToken(_token, _isSupportedOnCompound, _cToken, _chainLinkOracle, _borrowLTV);
    }

    function addToken(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle
    ) external onlyGov {
        _addToken(_token, _isSupportedOnCompound, _cToken, _chainLinkOracle, DEFAULT_BORROW_LTV);
    }

    /**
     * @dev Add a new token to registry
     * @param _token ERC20 Token address
     * @param _isSupportedOnCompound Is token supported on Compound
     * @param _cToken cToken contract address
     * @param _chainLinkOracle Chain Link Aggregator address to get TOKEN/ETH rate
     * @param _borrowLTV borrow LTV (Loan to value ratio)
     */
    function _addToken(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) internal {
        require(_token != address(0), "Token address is zero");
        require(!isTokenExist(_token), "Token already exist");
        require(_chainLinkOracle != address(0), "ChainLinkAggregator address is zero");
        require(tokens.length < MAX_TOKENS, "Max token limit reached");
        require(_borrowLTV <= MAX_BORROW_LTV, "Borrow LTV must be <= 90");

        TokenInfo storage storageTokenInfo = tokenInfo[_token];
        storageTokenInfo.index = uint8(tokens.length);
        storageTokenInfo.decimals = (_token == ETH_ADDR) ? 18 : IERC20Metadata(_token).decimals();
        storageTokenInfo.enabled = true;
        storageTokenInfo.isSupportedOnCompound = _isSupportedOnCompound;
        storageTokenInfo.cToken = _cToken;
        storageTokenInfo.chainLinkOracle = _chainLinkOracle;
        // Default values
        storageTokenInfo.borrowLTV = _borrowLTV;

        tokens.push(_token);
        emit TokenAdded(_token);
    }

    function updateBorrowLTV(address _token, uint256 _borrowLTV) external onlyGov whenTokenExists(_token) {
        if (tokenInfo[_token].borrowLTV == _borrowLTV) return;

        // require(_borrowLTV != 0, "Borrow LTV is zero");
        require(_borrowLTV <= MAX_BORROW_LTV, "Borrow LTV must be <= 90");
        // require(liquidationThreshold > _borrowLTV, "Liquidation threshold must be greater than Borrow LTV");

        tokenInfo[_token].borrowLTV = _borrowLTV;
        emit TokenBorrowLTVUpdated(_token, _borrowLTV);
    }

    /**
     */
    function updateTokenSupportedOnCompoundFlag(address _token, bool _isSupportedOnCompound)
        external
        onlyGov
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].isSupportedOnCompound == _isSupportedOnCompound) return;

        tokenInfo[_token].isSupportedOnCompound = _isSupportedOnCompound;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateCToken(address _token, address _cToken) external onlyGov whenTokenExists(_token) {
        if (tokenInfo[_token].cToken == _cToken) return;

        tokenInfo[_token].cToken = _cToken;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateChainLinkAggregator(address _token, address _chainLinkOracle)
        external
        onlyGov
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].chainLinkOracle == _chainLinkOracle) return;

        address oldAggregator = tokenInfo[_token].chainLinkOracle;
        tokenInfo[_token].chainLinkOracle = _chainLinkOracle;
        emit TokenChainlinkAggregatorUpdated(_token, oldAggregator, _chainLinkOracle);
    }

    function enableToken(address _token) external onlyGov whenTokenExists(_token) {
        require(!tokenInfo[_token].enabled, "Token already enabled");

        tokenInfo[_token].enabled = true;
        emit TokenEnableUpdate(_token, true);
    }

    function disableToken(address _token) external onlyGov whenTokenExists(_token) {
        require(tokenInfo[_token].enabled, "Token already disabled");

        tokenInfo[_token].enabled = false;
        emit TokenEnableUpdate(_token, false);
    }

    // =====================
    //      GETTERS
    // =====================

    /**
     * @dev Is token address is registered
     * @param _token token address
     * @return isExist Returns `true` when token registered, otherwise `false`
     */
    function isTokenExist(address _token) public view returns (bool isExist) {
        isExist = tokenInfo[_token].chainLinkOracle != address(0);
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getTokenIndex(address _token) external view returns (uint8) {
        return tokenInfo[_token].index;
    }

    function isTokenEnabled(address _token) external view returns (bool) {
        return tokenInfo[_token].enabled;
    }

    /**
     */
    function getCTokens() external view returns (address[] memory cTokens) {
        uint256 len = tokens.length;
        cTokens = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            cTokens[i] = tokenInfo[tokens[i]].cToken;
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8) {
        return tokenInfo[_token].decimals;
    }

    function isSupportedOnCompound(address _token) external view returns (bool) {
        return tokenInfo[_token].isSupportedOnCompound;
    }

    function getCToken(address _token) external view returns (address) {
        return tokenInfo[_token].cToken;
    }

    function getChainLinkAggregator(address _token) external view returns (address) {
        return tokenInfo[_token].chainLinkOracle;
    }

    function getBorrowLTV(address _token) external view returns (uint256) {
        return tokenInfo[_token].borrowLTV;
    }

    function getCoinLength() public view returns (uint256 length) {
        return tokens.length;
    }

    function addressFromIndex(uint256 index) public view returns (address) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        return tokens[index];
    }

    function _getChainlinkLatestAnswer(address _chainlinkOracle) internal view returns (uint256) {
        AggregatorInterface aggregator = AggregatorInterface(_chainlinkOracle);
        uint256 latestTimestamp = aggregator.latestTimestamp();
        require(latestTimestamp > block.timestamp - EXPIRE_DURATION, "Oracle data is expired");

        return aggregator.latestAnswer().toUint256();
    }

    function priceFromIndex(uint256 index) public view returns (uint256) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        address tokenAddress = tokens[index];
        if (Utils._isETH(tokenAddress)) {
            return 1e18;
        }
        return _getChainlinkLatestAnswer(tokenInfo[tokenAddress].chainLinkOracle);
    }

    function priceFromAddress(address tokenAddress) public view returns (uint256) {
        if (Utils._isETH(tokenAddress)) {
            return 1e18;
        }
        return _getChainlinkLatestAnswer(tokenInfo[tokenAddress].chainLinkOracle);
    }

    function _priceFromAddress(address _token) internal view returns (uint256) {
        return _token != ETH_ADDR ? _getChainlinkLatestAnswer(tokenInfo[_token].chainLinkOracle) : INT_UNIT;
    }

    function _tokenDivisor(address _token) internal view returns (uint256) {
        return _token != ETH_ADDR ? 10**uint256(tokenInfo[_token].decimals) : INT_UNIT;
    }

    function getTokenInfoFromIndex(uint256 index)
        external
        view
        whenTokenExists(addressFromIndex(index))
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        address token = tokens[index];
        return (token, _tokenDivisor(token), _priceFromAddress(token), tokenInfo[token].borrowLTV);
    }

    function getTokenInfoFromAddress(address _token)
        external
        view
        whenTokenExists(_token)
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        return (tokenInfo[_token].index, _tokenDivisor(_token), _priceFromAddress(_token), tokenInfo[_token].borrowLTV);
    }

    function updateMiningSpeed(
        address _token,
        uint256 _depositeMiningSpeed,
        uint256 _borrowMiningSpeed
    ) public onlyAuthorized {
        require(isTokenExist(_token), "token doesn't exists");
        depositeMiningSpeeds[_token] = _depositeMiningSpeed;
        borrowMiningSpeeds[_token] = _borrowMiningSpeed;
        emit TokenUpdated(_token);
    }
}