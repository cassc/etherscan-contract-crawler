// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IERC4626Minimal.sol";
import "./SuperAdminControl.sol";

abstract contract ApyFlowVault is IERC4626Minimal, ERC20, ERC165, SuperAdminControl {
    using SafeERC20 for IERC20Metadata;
    using Math for uint256;

    IERC20Metadata private immutable _asset;
    uint8 private immutable _decimals;

    constructor(IERC20Metadata asset_) {
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function _totalAssets() internal view virtual returns (uint256);

    function totalAssets() public view override returns (uint256) {
        return _totalAssets() + _asset.balanceOf(address(this));
    }

    function _convertToAssets(uint256 shares, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 assets)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? shares : shares.mulDiv(totalAssets_, totalSupply_);
    }

    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        return _convertToAssets(shares, totalAssets(), totalSupply());
    }

    function _convertToShares(uint256 assets, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 shares)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? assets : assets.mulDiv(totalSupply_, totalAssets_);
    }

    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return _convertToShares(assets, totalAssets(), totalSupply());
    }

    function pricePerToken() public view returns (uint256) {
        return convertToAssets(10 ** decimals());
    }

    function _deposit(uint256 assets) internal virtual;

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        if (assets == 0) {
            return 0;
        }
        uint256 totalAssetsBefore = totalAssets();
        _asset.safeTransferFrom(_msgSender(), address(this), assets);
        _deposit(assets);
        uint256 totalAssetsAfter = totalAssets();
        shares = _convertToShares(totalAssetsAfter - totalAssetsBefore, totalAssetsBefore, totalSupply());
        _mint(receiver, shares);

        emit Deposit(_msgSender(), receiver, assets, shares);
    }

    function _redeem(uint256 shares) internal virtual returns (uint256 assets);

    function _performRedeem(uint256 shares) internal virtual returns (uint256 assets) {
        assets = _asset.balanceOf(address(this)).mulDiv(shares, totalSupply());
        assets += _redeem(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        if (_msgSender() != owner) {
            _spendAllowance(owner, _msgSender(), shares);
        }

        assets = _performRedeem(shares);
        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);

        emit Withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    function previewRedeemHelper(uint256 shares) external {
        require(msg.sender == address(this));
        uint256 assets = _performRedeem(shares);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, assets)
            revert(ptr, 32)
        }
    }

    function previewRedeem(uint256 shares) external returns (uint256 assets) {
        try this.previewRedeemHelper(shares) {}
        catch (bytes memory reason) {
            if (reason.length != 32) {
                if (reason.length < 68) revert("Unexpected error");
                assembly {
                    reason := add(reason, 0x04)
                }
                revert(abi.decode(reason, (string)));
            }
            return abi.decode(reason, (uint256));
        }
    }
}