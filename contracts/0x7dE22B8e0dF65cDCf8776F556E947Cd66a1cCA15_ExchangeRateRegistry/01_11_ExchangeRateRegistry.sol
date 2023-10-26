// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {IBPSFeed} from "../interfaces/IBPSFeed.sol";
import {IBloomPool} from "../interfaces/IBloomPool.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";

/**
 * @title ExchangeRateRegistry
 * @notice Manage tokens and exchange rates
 * @dev This contract stores:
 * 1. Address of all TBYs
 * 2. Exchange rate of each TBY
 * 3. If TBY is active or not
 */
contract ExchangeRateRegistry is IRegistry, Ownable2Step {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _bloomFactory;
    uint256 private constant INITIAL_FEED_RATE = 1e4;
    uint256 private constant BASE_RATE = 1e18;
    uint256 private constant ONE_YEAR = 360 days;
    uint256 private constant SCALER = 1e14;

    /**
     * @notice Mapping of token to TokenInfo
     */
    mapping(address => TokenInfo) public tokenInfos;

    /**
     * @dev Group of active tokens
     */
    EnumerableSet.AddressSet internal _activeTokens;

    /**
     * @dev Group of inactive tokens
     */
    EnumerableSet.AddressSet internal _inactiveTokens;
    
    struct TokenInfo {
        bool registered;
        bool active;
        uint256 createdAt;
    }

    /**
     * @notice Emitted when token is registered
     * @param token The token address to register
     * @param createdAt Timestamp of the token creation
     */
    event TokenRegistered(
        address indexed token,
        uint256 createdAt
    );

    /**
     * @notice Emitted when token is activated
     * @param token The token address
     */
    event TokenActivated(address token);

    /**
     * @notice Emitted when token is inactivated
     * @param token The token address
     */
    event TokenInactivated(address token);

    // Errors
    error TokenAlreadyRegistered();
    error TokenNotRegistered();
    error TokenAlreadyActive();
    error TokenAlreadyInactive();
    error InvalidUser();

    modifier onlyFactoryOrOwner() {
        if (msg.sender != owner() && msg.sender != _bloomFactory) {
            revert InvalidUser();
        }
        _;
    }

    constructor(address owner, address bloomFactory) Ownable2Step() {
        _transferOwnership(owner);
        _bloomFactory = bloomFactory;
    }


    /**
     * @inheritdoc IRegistry
     */
    function registerToken(IBloomPool token) external onlyFactoryOrOwner {
        IBloomPool poolContract = token;
        uint256 createdAt = poolContract.COMMIT_PHASE_END();

        TokenInfo storage info = tokenInfos[address(token)];
        if (info.registered) {
            revert TokenAlreadyRegistered();
        }

        info.registered = true;
        info.active = true;
        info.createdAt = createdAt;

        _activeTokens.add(address(token));

        emit TokenRegistered(address(token), createdAt);
    }

    /**
     * @notice Activate the token
     * @param token The token address to activate
     */
    function activateToken(address token) external onlyFactoryOrOwner {
        TokenInfo storage info = tokenInfos[token];
        if (!info.registered) {
            revert TokenNotRegistered();
        }
        if (info.active) {
            revert TokenAlreadyActive();
        }

        info.active = true;

        _activeTokens.add(token);
        _inactiveTokens.remove(token);

        emit TokenActivated(token);
    }

    /**
     * @notice Inactivate the token
     * @param token The token address to inactivate
     */
    function inactivateToken(address token) external onlyOwner {
        TokenInfo storage info = tokenInfos[token];
        if (!info.registered) {
            revert TokenAlreadyInactive();
        }

        info.active = false;

        _activeTokens.remove(token);
        _inactiveTokens.add(token);

        emit TokenInactivated(token);
    }

    /**
     * @notice Updates the Bloom Factory Address
     * @param factory The new factory address
     */
    function updateBloomFactory(address factory) external onlyOwner {
        _bloomFactory = factory;
    }

    /**
     * @notice Return list of active tokens
     */
    function getActiveTokens() external view returns (address[] memory) {
        return _activeTokens.values();
    }

    /**
     * @notice Return list of inactive tokens
     */
    function getInactiveTokens() external view returns (address[] memory) {
        return _inactiveTokens.values();
    }

    /**
     * @notice Returns the current exchange rate of the given token
     * @param token The token address
     * @return The current exchange rate of the given token
     */
    function getExchangeRate(address token) external view returns (uint256) {
        return _getExchangeRate(token);
    }

    /**
     * @notice Returns the Bloom Factory address 
     */
    function getBloomFactory() external view returns (address) {
        return _bloomFactory;
    }

    function _getExchangeRate(address token) internal view returns (uint256) {
        TokenInfo storage info = tokenInfos[token];
        if (!info.registered) {
            revert TokenNotRegistered();
        }

        IBloomPool pool = IBloomPool(token);
        IBPSFeed bpsFeed = IBPSFeed(pool.LENDER_RETURN_BPS_FEED());
        uint256 duration = pool.POOL_PHASE_DURATION();

        uint256 rate = (bpsFeed.getWeightedRate() - INITIAL_FEED_RATE) * SCALER;
        uint256 timeElapsed = block.timestamp - info.createdAt;
        if (timeElapsed > duration) {
            timeElapsed = duration;
        }
        uint256 adjustedLenderFee = pool.LENDER_RETURN_FEE() * SCALER;
        
        uint256 delta = ((rate * (BASE_RATE - adjustedLenderFee)) * timeElapsed) / 
            ONE_YEAR / 1e18;

        return BASE_RATE + delta;
    }
}