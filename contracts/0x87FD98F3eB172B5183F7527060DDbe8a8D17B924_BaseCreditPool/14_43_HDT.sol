// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20MetadataUpgradeable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IHDT.sol";
import "./HDTStorage.sol";
import "../Errors.sol";

/**
 * @title Huma Distribution Token
 * @notice HDT tracks the principal, earnings and losses associated with a token.
 */
contract HDT is ERC20Upgradeable, OwnableUpgradeable, HDTStorage, IHDT {
    event PoolChanged(address pool);

    constructor() {
        _disableInitializers();
    }

    /**
     * @param name the name of the token
     * @param symbol the symbol of the token
     * @param underlyingToken the address of the underlying token used for the pool
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingToken
    ) external initializer {
        if (underlyingToken == address(0)) revert Errors.zeroAddressProvided();
        _assetToken = underlyingToken;

        __ERC20_init(name, symbol);
        // HDT uses the same decimal as the underlyingToken
        _decimals = IERC20MetadataUpgradeable(underlyingToken).decimals();

        __Ownable_init();
    }

    /**
     * @notice Associates the HDT with the pool
     * @dev Pool and HDT references each other. This call is expected to be called once at setup.
     */
    function setPool(address poolAddress) external onlyOwner {
        _pool = IPool(poolAddress);
        emit PoolChanged(poolAddress);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Returns the toal value of the pool, in the units of underlyingToken
     */
    function totalAssets() public view returns (uint256) {
        return _pool.totalPoolValue();
    }

    /**
     * @notice Mints HDTs when LPs contribute capital to the pool
     * @param account the address of the account to mint
     * @param amount the number of underlyingTokens used to mint HDTs
     */
    function mintAmount(address account, uint256 amount)
        external
        override
        onlyPool
        returns (uint256 shares)
    {
        shares = convertToShares(amount);
        if (shares == 0) revert Errors.zeroAmountProvided();
        _mint(account, shares);
    }

    /**
     * @notice Burns HDTs when LPs withdraw from the pool
     * @param account the address of the account to burn
     * @param amount the amount of underlyingTokens used to burn HDTs with equivalent value
     */
    function burnAmount(address account, uint256 amount)
        external
        override
        onlyPool
        returns (uint256 shares)
    {
        shares = convertToShares(amount);
        if (shares == 0) revert Errors.zeroAmountProvided();
        _burn(account, shares);
    }

    function convertToShares(uint256 assets) internal view virtual returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();

        return ta == 0 ? assets : (assets * ts) / ta;
    }

    function convertToAssets(uint256 shares) internal view virtual returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();

        return ts == 0 ? shares : (shares * ta) / ts;
    }

    /**
     * @notice Gets the amount of funds (in units of underlyingToken) that an address can withdraw
     * @param account The address of a token holder.
     * @return The amount funds that the account can withdraw.
     */
    function withdrawableFundsOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(balanceOf(account));
    }

    /**
     * @notice the underlying token used in the associated pool
     */
    function assetToken() external view override returns (address) {
        return _assetToken;
    }

    /**
     * @notice the associated pool
     */
    function pool() external view returns (address) {
        return address(_pool);
    }

    /**
     * @notice Only the pool contract itself can call the functions.
     */
    modifier onlyPool() {
        if (msg.sender != address(_pool)) revert Errors.notPool();
        _;
    }
}