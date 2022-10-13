// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IComptroller, ICToken} from "@contracts/compound/interfaces/compound/ICompound.sol";
import {IMorpho} from "@contracts/compound/interfaces/IMorpho.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20, SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {CompoundMath} from "@morpho-labs/morpho-utils/math/CompoundMath.sol";
import {Types} from "@contracts/compound/libraries/Types.sol";

import {ERC4626UpgradeableSafe, ERC20Upgradeable} from "../ERC4626UpgradeableSafe.sol";

/// @title SupplyVaultBase.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice ERC4626-upgradeable Tokenized Vault abstract implementation for Morpho-Compound.
abstract contract SupplyVaultBase is ERC4626UpgradeableSafe, OwnableUpgradeable {
    using CompoundMath for uint256;
    using SafeTransferLib for ERC20;

    /// ERRORS ///

    /// @notice Thrown when the zero address is passed as input.
    error ZeroAddress();

    /// STORAGE ///

    IMorpho public immutable morpho; // The main Morpho contract.
    address public immutable wEth; // The address of WETH token.
    ERC20 public immutable comp; // The COMP token.

    address public poolToken; // The pool token corresponding to the market to supply to through this vault.

    /// CONSTRUCTOR ///

    /// @dev Initializes network-wide immutables.
    /// @param _morpho The address of the main Morpho contract.
    constructor(address _morpho) {
        morpho = IMorpho(_morpho);
        wEth = morpho.wEth();
        comp = ERC20(morpho.comptroller().getCompAddress());
    }

    /// INITIALIZER ///

    /// @dev Initializes the vault.
    /// @param _poolToken The address of the pool token corresponding to the market to supply through this vault.
    /// @param _name The name of the ERC20 token associated to this tokenized vault.
    /// @param _symbol The symbol of the ERC20 token associated to this tokenized vault.
    /// @param _initialDeposit The amount of the initial deposit used to prevent pricePerShare manipulation.
    function __SupplyVaultBase_init(
        address _poolToken,
        string calldata _name,
        string calldata _symbol,
        uint256 _initialDeposit
    ) internal onlyInitializing returns (bool isEth) {
        ERC20 underlyingToken;
        (isEth, underlyingToken) = __SupplyVaultBase_init_unchained(_poolToken);

        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC4626UpgradeableSafe_init(ERC20Upgradeable(address(underlyingToken)), _initialDeposit);
    }

    /// @dev Initializes the vault whithout initializing parent contracts (avoid the double initialization problem).
    /// @param _poolToken The address of the pool token corresponding to the market to supply through this vault.
    function __SupplyVaultBase_init_unchained(address _poolToken)
        internal
        onlyInitializing
        returns (bool isEth, ERC20 underlyingToken)
    {
        if (_poolToken == address(0)) revert ZeroAddress();

        poolToken = _poolToken;

        isEth = _poolToken == morpho.cEth();

        underlyingToken = ERC20(isEth ? wEth : ICToken(_poolToken).underlying());
        underlyingToken.safeApprove(address(morpho), type(uint256).max);
    }

    /// EXTERNAL ///

    function transferTokens(
        address _asset,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        ERC20(_asset).safeTransfer(_to, _amount);
    }

    /// PUBLIC ///

    /// @dev The indexes used by this function might not be up-to-date.
    ///      As a consequence, view functions (like `maxWithdraw`) could underestimate the withdrawable amount.
    ///      To redeem all their assets, users are encouraged to use the `redeem` function passing their vault tokens balance.
    function totalAssets() public view override returns (uint256) {
        address poolTokenMem = poolToken;
        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(
            poolTokenMem,
            address(this)
        );

        return
            supplyBalance.onPool.mul(morpho.lastPoolIndexes(poolTokenMem).lastSupplyPoolIndex) +
            supplyBalance.inP2P.mul(morpho.p2pSupplyIndex(poolTokenMem));
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        // Update the indexes to get the most up-to-date total assets balance.
        morpho.updateP2PIndexes(poolToken);
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        // Update the indexes to get the most up-to-date total assets balance.
        morpho.updateP2PIndexes(poolToken);
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        // Update the indexes to get the most up-to-date total assets balance.
        morpho.updateP2PIndexes(poolToken);
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        // Update the indexes to get the most up-to-date total assets balance.
        morpho.updateP2PIndexes(poolToken);
        return super.redeem(shares, receiver, owner);
    }

    /// INTERNAL ///

    function _deposit(
        address _caller,
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal virtual override {
        super._deposit(_caller, _receiver, _assets, _shares);
        morpho.supply(poolToken, address(this), _assets);
    }

    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares
    ) internal virtual override {
        morpho.withdraw(poolToken, _assets);
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;
}