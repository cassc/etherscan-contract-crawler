// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/NAV.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IVaultController.sol";

/// @title Vault token
/// @notice Contains logic for index's asset management
contract vToken is IvToken, Initializable, ReentrancyGuardUpgradeable, ERC165Upgradeable {
    using NAV for NAV.Data;
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Oracle role
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Orderer role
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IvToken
    address public override vaultController;
    /// @inheritdoc IvToken
    address public override asset;
    /// @inheritdoc IvToken
    address public override registry;

    /// @inheritdoc IvToken
    uint public override deposited;

    /// @notice NAV library used to track contract shares between indexes
    NAV.Data internal _NAV;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "vToken: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IvToken
    /// @dev also sets initial values for public variables
    function initialize(address _asset, address _registry) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "vToken: INTERFACE");
        require(_asset != address(0), "vToken: ZERO");

        __ERC165_init();
        __ReentrancyGuard_init();

        asset = _asset;
        registry = _registry;
    }

    /// @inheritdoc IvToken
    function transferAsset(address _recipient, uint _amount) external override nonReentrant {
        require(msg.sender == IIndexRegistry(registry).orderer(), "vToken: FORBIDDEN");

        _transferAsset(_recipient, _amount);
    }

    /// @inheritdoc IvToken
    function setController(address _vaultController) external override onlyRole(RESERVE_MANAGER_ROLE) {
        if (vaultController != address(0)) {
            IVaultController(vaultController).withdraw();
            _updateDeposited(0);
        }

        if (_vaultController != address(0)) {
            require(_vaultController.supportsInterface(type(IVaultController).interfaceId), "vToken: INTERFACE");
        }

        vaultController = _vaultController;
        emit SetVaultController(_vaultController);
    }

    /// @inheritdoc IvToken
    function withdraw() external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vaultController != address(0), "vToken: ZERO");

        IVaultController(vaultController).withdraw();
        _updateDeposited(0);
    }

    /// @inheritdoc IvToken
    function deposit() external override onlyRole(ORACLE_ROLE) {
        require(vaultController != address(0), "vToken: ZERO");

        uint _currentDepositedPercentageInBP = currentDepositedPercentageInBP();
        IVaultController(vaultController).withdraw();
        uint amount = IVaultController(vaultController).calculatedDepositAmount(_currentDepositedPercentageInBP);
        IERC20(asset).safeTransfer(vaultController, amount);
        IVaultController(vaultController).deposit();
        _updateDeposited(amount);
    }

    /// @inheritdoc IvToken
    function transfer(address _recipient, uint _amount) external override nonReentrant {
        _transfer(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IvToken
    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external override nonReentrant onlyRole(ORDERER_ROLE) {
        _transfer(_from, _to, _shares);
    }

    /// @inheritdoc IvToken
    function mint() external override nonReentrant onlyRole(INDEX_ROLE) returns (uint shares) {
        return _mint(msg.sender);
    }

    /// @inheritdoc IvToken
    function burn(address _recipient) external override nonReentrant onlyRole(INDEX_ROLE) returns (uint amount) {
        return _burn(_recipient);
    }

    /// @inheritdoc IvToken
    function mintFor(address _recipient) external override nonReentrant onlyRole(ORDERER_ROLE) returns (uint) {
        return _mint(_recipient);
    }

    /// @inheritdoc IvToken
    function burnFor(address _recipient) external override nonReentrant onlyRole(ORDERER_ROLE) returns (uint) {
        return _burn(_recipient);
    }

    /// @inheritdoc IvToken
    function sync() external override nonReentrant {
        _NAV.sync(totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function virtualTotalAssetSupply() external view override returns (uint) {
        if (vaultController == address(0)) {
            return IERC20(asset).balanceOf(address(this));
        }

        return IERC20(asset).balanceOf(address(this)) + IVaultController(vaultController).expectedWithdrawableAmount();
    }

    /// @inheritdoc IvToken
    function balanceOf(address _account) external view override returns (uint) {
        return _NAV.balanceOf[_account];
    }

    /// @inheritdoc IvToken
    function lastAssetBalance() external view override returns (uint) {
        return _NAV.lastAssetBalance;
    }

    /// @inheritdoc IvToken
    function mintableShares(uint _amount) external view override returns (uint) {
        return _NAV.mintableShares(_amount);
    }

    /// @inheritdoc IvToken
    function totalSupply() external view override returns (uint) {
        return _NAV.totalSupply;
    }

    /// @inheritdoc IvToken
    function lastAssetBalanceOf(address _account) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_NAV.balanceOf[_account], _NAV.lastAssetBalance);
    }

    /// @inheritdoc IvToken
    function assetBalanceOf(address _account) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_NAV.balanceOf[_account], totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function assetDataOf(address _account, uint _shares) external view override returns (AssetData memory) {
        _shares = Math.min(_shares, _NAV.balanceOf[_account]);
        return
            AssetData({ maxShares: _shares, amountInAsset: _NAV.assetBalanceForShares(_shares, totalAssetSupply()) });
    }

    /// @inheritdoc IvToken
    function assetBalanceForShares(uint _shares) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_shares, totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function shareChange(address _account, uint _amountInAsset)
        external
        view
        override
        returns (uint newShares, uint oldShares)
    {
        oldShares = _NAV.balanceOf[_account];
        uint _totalSupply = _NAV.totalSupply;
        if (_totalSupply > 0) {
            uint _balance = _NAV.balanceOf[_account];
            uint _assetBalance = totalAssetSupply();
            uint availableAssets = (_balance * _assetBalance) / _totalSupply;
            newShares = (_amountInAsset * (_totalSupply - oldShares)) / (_assetBalance - availableAssets);
        } else {
            newShares = _amountInAsset < NAV.INITIAL_QUANTITY ? 0 : _amountInAsset - NAV.INITIAL_QUANTITY;
        }
    }

    /// @inheritdoc IvToken
    function currentDepositedPercentageInBP() public view override returns (uint) {
        if (vaultController == address(0)) {
            return 0;
        }

        uint total = IERC20(asset).balanceOf(address(this)) + deposited;
        if (total > 0) {
            return (deposited * BP.DECIMAL_FACTOR) / total;
        }

        return 0;
    }

    /// @inheritdoc IvToken
    function totalAssetSupply() public view override returns (uint) {
        return IERC20(asset).balanceOf(address(this)) + deposited;
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IvToken).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Mints shares to `_recipient` address
    /// @param _recipient Shares recipient
    /// @return shares Amount of minted shares
    function _mint(address _recipient) internal returns (uint shares) {
        uint _totalAssetSupply = totalAssetSupply();
        shares = _NAV.mint(_totalAssetSupply, _recipient);
        _NAV.sync(_totalAssetSupply);
    }

    /// @notice Burns shares from `_recipient` address
    /// @param _recipient Recipient of assets from burnt shares
    /// @return amount Amount of asset for burnt shares
    function _burn(address _recipient) internal returns (uint amount) {
        amount = _NAV.burn(totalAssetSupply());
        _transferAsset(_recipient, amount);
        _NAV.sync(totalAssetSupply());
    }

    /// @notice Transfers `_amount` of shares from one address to another
    /// @param _from Address to transfer shares from
    /// @param _to Address to transfer shares to
    /// @param _amount Amount of shares to transfer
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal {
        _NAV.transfer(_from, _to, _amount);
    }

    /// @notice Transfers `_amount` of asset to `_recipient` address
    /// @param _recipient Recipient of assets
    /// @param _amount Amount of assets to transfer
    function _transferAsset(address _recipient, uint _amount) internal {
        uint balance = IERC20(asset).balanceOf(address(this));
        if (balance < _amount && vaultController != address(0)) {
            IVaultController(vaultController).withdraw();
            _updateDeposited(0);
            balance = IERC20(asset).balanceOf(address(this));
        }

        IERC20(asset).safeTransfer(_recipient, Math.min(_amount, balance));
    }

    /// @notice Updates deposited value
    function _updateDeposited(uint _deposited) internal {
        deposited = _deposited;
        _NAV.sync(totalAssetSupply());
        emit UpdateDeposit(msg.sender, deposited);
    }

    uint256[42] private __gap;
}