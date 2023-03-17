// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IFlaixVault.sol";
import "./interfaces/IFlaixOption.sol";

/// @title FlaixPutOption Contract
/// @notice This is the contract for FlaixPutOptions. Put options are used to
/// sell an underlying asset on behalf of the vault. If put options are
/// issued, the issuer transfers a certain amount of shares to the options
/// contract, and the vault transfers a certain amount of the underlying asset.
/// After that, the options contract burns the shares and holds the underlying
/// assets until the option matures. If the option is exercised upon maturity,
/// the options owner receives the underlying assets pro rata to the amount of
/// options exercised. If instead, the option owner decides to revoke the
/// options, she receives an equal amount of shares to the amount of options
/// revoked, and the vault receives the underlying assets from the options
/// contract pro rata to the amount of options revoked. Revoking options is
/// meant as a reverse operation to exercising options.
contract FlaixPutOption is ERC20Upgradeable, IFlaixOption, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    /// @notice The address of the vault which issued the options.
    address public vault;

    /// @notice The address of the underlying asset.
    address public asset;

    /// @notice The timestamp at which the options mature.
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
        require(maturityTimestamp_ >= block.timestamp, "FlaixPutOption: maturity in the past");
        require(asset_ != address(0), "FlaixPutOption: asset is zero address");
        require(vault_ != address(0), "FlaixPutOption: vault is zero address");

        maturityTimestamp = maturityTimestamp_;
        asset = asset_;
        vault = vault_;
        _mint(minter_, totalSupply_);
        emit Issue(minter_, totalSupply_, maturityTimestamp_);
    }

    /// @notice This function exercises the specified amount of options, which are burned,
    /// along with an equivalent amount of vault shares. The recipient receives
    /// the underlying assets pro rata to the amount of options exercised.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of options to exercise.
    function exercise(uint256 amount, address recipient) public onlyWhenMatured nonReentrant {
        uint256 assetAmount = convertToAssets(amount);
        emit Exercise(recipient, amount, assetAmount);
        IERC20Upgradeable(asset).safeTransfer(recipient, assetAmount);
        IFlaixVault(vault).mint(amount, address(this));
        IFlaixVault(vault).burn(amount);
        _burn(msg.sender, amount);
    }

    /// @notice Returns the amount of underlying assets for the given amount of
    ///         options when exercised.
    /// @param amount The amount of options to exercise.
    /// @return The amount of underlying assets.
    function convertToAssets(uint256 amount) public view returns (uint256) {
        return IERC20Upgradeable(asset).balanceOf(address(this)).mulDiv(amount, totalSupply());
    }

    /// @notice This function revokes the specified amount of options and transfers
    /// an equivalent amount of vault shares to the recipient. Additionally,
    /// it transfers a pro rata amount of underlying assets from the options
    /// contract to the vault.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of options to revoke.
    function revoke(uint256 amount, address recipient) public onlyWhenMatured nonReentrant {
        emit Revoke(recipient, amount);
        IFlaixVault(vault).mint(amount, recipient);
        IERC20Upgradeable(asset).safeTransfer(vault, convertToAssets(amount));
        _burn(msg.sender, amount);
    }
}