// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IWrappedUsdPlusToken.sol";
import "./interfaces/IUsdPlusToken.sol";
import "./libraries/WadRayMath.sol";


contract WrappedUsdPlusToken is IWrappedUsdPlusToken, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using WadRayMath for uint256;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IUsdPlusToken public asset;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address usdPlusTokenAddress, string calldata name, string calldata symbol) initializer public {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        asset = IUsdPlusToken(usdPlusTokenAddress);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}

    function _convertToSharesUp(uint256 assets) internal view returns (uint256) {
        return assets.rayDiv(asset.liquidityIndex());
    }

    function _convertToAssetsUp(uint256 shares) internal view returns (uint256) {
        return shares.rayMul(asset.liquidityIndex());
    }

    function _convertToSharesDown(uint256 assets) internal view returns (uint256) {
        return assets.rayDivDown(asset.liquidityIndex());
    }

    function _convertToAssetsDown(uint256 shares) internal view returns (uint256) {
        return shares.rayMulDown(asset.liquidityIndex());
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public view override(ERC20Upgradeable) returns (uint8) {
        return 6;
    }

    /// @inheritdoc IERC4626
    function totalAssets() external view override returns (uint256) {
        return _convertToAssetsDown(totalSupply());
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets) external view override returns (uint256) {
        return _convertToSharesDown(assets);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) external view override returns (uint256) {
        return _convertToAssetsDown(shares);
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address receiver) external view override returns (uint256) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 assets) external view override returns (uint256) {
        return _convertToSharesDown(assets);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) external override returns (uint256) {
        require(assets != 0, "Zero assets not allowed");
        require(receiver != address(0), "Zero address for receiver not allowed");

        asset.transferFrom(msg.sender, address(this), assets);

        uint256 shares = _convertToSharesDown(assets);

        if (shares != 0) {
            _mint(receiver, shares);
        }

        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function maxMint(address receiver) external view override returns (uint256) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewMint(uint256 shares) external view override returns (uint256) {
        return _convertToAssetsUp(shares);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) external override returns (uint256) {
        require(shares != 0, "Zero shares not allowed");
        require(receiver != address(0), "Zero address for receiver not allowed");

        uint256 assets = _convertToAssetsUp(shares);

        if (assets != 0) {
            asset.transferFrom(msg.sender, address(this), assets);
        }

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) external view override returns (uint256) {
        return _convertToAssetsDown(balanceOf(owner));
    }

    /// @inheritdoc IERC4626
    function previewWithdraw(uint256 assets) external view override returns (uint256) {
        return _convertToSharesUp(assets);
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256) {
        require(assets != 0, "Zero assets not allowed");
        require(receiver != address(0), "Zero address for receiver not allowed");
        require(owner != address(0), "Zero address for owner not allowed");

        uint256 shares = _convertToSharesUp(assets);

        if (owner != msg.sender) {
            uint256 currentAllowance = allowance(owner, msg.sender);
            require(currentAllowance >= shares, "Withdraw amount exceeds allowance");
            _approve(owner, msg.sender, currentAllowance - shares);
        }

        if (shares != 0) {
            _burn(owner, shares);
        }

        asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner) external view override returns (uint256) {
        return balanceOf(owner);
    }

    /// @inheritdoc IERC4626
    function previewRedeem(uint256 shares) external view override returns (uint256) {
        return _convertToAssetsDown(shares);
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256) {
        require(shares != 0, "Zero shares not allowed");
        require(receiver != address(0), "Zero address for receiver not allowed");
        require(owner != address(0), "Zero address for owner not allowed");

        if (owner != msg.sender) {
            uint256 currentAllowance = allowance(owner, msg.sender);
            require(currentAllowance >= shares, "Redeem amount exceeds allowance");
            _approve(owner, msg.sender, currentAllowance - shares);
        }

        _burn(owner, shares);

        uint256 assets = _convertToAssetsDown(shares);

        if (assets != 0) {
            asset.transfer(receiver, assets);
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /// @inheritdoc IWrappedUsdPlusToken
    function rate() external view override returns (uint256) {
        return asset.liquidityIndex();
    }

}