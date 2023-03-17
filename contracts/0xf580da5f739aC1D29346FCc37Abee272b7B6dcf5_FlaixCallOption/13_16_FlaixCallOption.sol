// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IFlaixOption.sol";
import "./interfaces/IFlaixVault.sol";

/// @title FlaixCallOption Contract
/// @notice This is the contract for FlaixCallOptions. Call options are used to
/// buy an underlying asset on behalf of the vault. If call options are
/// issued, the issuer transfers a certain amount of underlying assets to
/// the options contract. After that, the options contract holds
/// the underlying assets until the option matures. If the option is
/// exercised upon maturity, the options owner receives an equal amount
/// of shares as the exercised amount of options, while the vault receives
/// the assets corresponding to the options owner's share of the total
/// supply of the options (pro rata). If instead the option owner decides
/// to revoke the option, the pro rata amount of the underlying assets
/// is transferred to the option owner, and no shares are minted.
contract FlaixCallOption is ERC20Upgradeable, IFlaixOption, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    address public asset;

    address public vault;

    uint public maturityTimestamp;

    modifier onlyWhenMatured() {
        //slither-disable-next-line timestamp
        if (block.timestamp < maturityTimestamp) revert IFlaixOption.OptionNotMaturedYet();
        _;
    }

    /// @param name The name of the options.
    /// @param symbol The symbol of the options.
    /// @param asset_ The address of the underlying asset.
    /// @param minter_ The address of the minter.
    /// @param vault_ The address of the vault.
    /// @param totalSupply_ The total supply of the options.
    /// @param maturityTimestamp_ The timestamp at which the options mature.
    function initialize(
        string memory name,
        string memory symbol,
        address asset_,
        address minter_,
        address vault_,
        uint256 totalSupply_,
        uint maturityTimestamp_
    ) public initializer {
        ERC20Upgradeable.__ERC20_init(name, symbol);
        //slither-disable-next-line timestamp
        require(maturityTimestamp_ >= block.timestamp, "FlaixCallOption: maturity in the past");
        require(asset_ != address(0), "FlaixPutOption: asset is zero address");
        require(vault_ != address(0), "FlaixPutOption: vault is zero address");
        maturityTimestamp = maturityTimestamp_;
        asset = asset_;
        vault = vault_;
        _mint(minter_, totalSupply_);
        emit Issue(minter_, totalSupply_, maturityTimestamp_);
    }

    /// @notice This function exercises the given amount of options and transfers the
    /// result to the recipient. The specified amount of options is burned, while
    /// an equivalent amount of shares is minted for the recipient. Subsequently,
    /// a corresponding amount of the underlying assets is transferred from the
    /// options contract to the vault.
    /// @param recipient The address to which the result is transferred.
    /// @param amount The amount of options to exercise.
    function exercise(uint256 amount, address recipient) public onlyWhenMatured nonReentrant {
        uint256 assetAmount = convertToAssets(amount);
        _burn(msg.sender, amount);
        emit Exercise(recipient, amount, assetAmount);
        IFlaixVault(vault).mint(amount, recipient);
        IERC20Upgradeable(asset).safeTransfer(vault, assetAmount);
    }

    /// @notice Returns the amount of underlying assets for the given amount of
    ///         options when the option is exercised.
    /// @param amount The amount of options to exercise.
    /// @return The amount of underlying assets.
    function convertToAssets(uint256 amount) public view returns (uint256) {
        return IERC20(asset).balanceOf(address(this)).mulDiv(amount, totalSupply());
    }

    /// @notice This function revokes the specified amount of options by burning them.
    /// Subsequently, a corresponding amount of the underlying assets is
    /// transferred from the options contract to the recipient. This function
    /// can be used to reverse the effect of issuing options or to remove options
    /// from the market.
    /// @param recipient The address to which the underlying assets are transferred.
    /// @param amount The amount of options to revoke.
    function revoke(uint256 amount, address recipient) public onlyWhenMatured nonReentrant {
        uint256 assetAmount = convertToAssets(amount);
        emit Revoke(recipient, amount);
        _burn(msg.sender, amount);
        IFlaixVault(vault).mint(amount, address(this));
        IFlaixVault(vault).burn(amount);
        IERC20Upgradeable(asset).safeTransfer(recipient, assetAmount);
    }
}