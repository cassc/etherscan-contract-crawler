// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {ERC20WithPermit} from "./ERC20WithPermit.sol";
import {ERC20WithPermit} from "./ERC20WithPermit.sol";
import {StringV1} from "../libraries/StringV1.sol";

abstract contract RenAssetStateV2 {
    uint8 internal _decimals;

    // Leave a gap so that storage values added in future upgrages don't corrupt
    // the storage of contracts that inherit from this contract.
    uint256[49] private __gap;
}

/// RenAsset represents a digital asset that has been bridged by RenVM. It
/// exposes mint and burn functions that can only be called by it's associated
/// MintGateway contract.
contract RenAssetV2 is Initializable, OwnableUpgradeable, ERC20Upgradeable, ERC20WithPermit, RenAssetStateV2 {
    string public constant NAME = "RenAsset";

    // If these parameters are changed, RenAssetFactory must be updated as well.
    function __RenAsset_init(
        uint256 chainId,
        string calldata version_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        address contractOwner
    ) external initializer {
        require(StringV1.isValidString(version_), "RenAsset: invalid version");
        require(StringV1.isValidString(name_), "RenAsset: invalid name");
        require(StringV1.isValidString(symbol_), "RenAsset: invalid symbol");

        __Ownable_init();
        __ERC20_init(name_, symbol_);
        __ERC20WithPermit_init(chainId, version_, name_, symbol_);

        RenAssetStateV2._decimals = decimals_;

        if (owner() != contractOwner) {
            transferOwnership(contractOwner);
        }
    }

    function decimals() public view override returns (uint8) {
        return RenAssetStateV2._decimals;
    }

    /// @notice mint can only be called by the tokens' associated Gateway
    /// contract. See Gateway's mint function instead.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice burn can only be called by the tokens' associated Gateway
    /// contract. See Gateway's burn functions instead.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // Disallow sending tokens to the ERC20 contract address - a common
        // mistake caused by the Ethereum transaction's `to` needing to be
        // the token's address.
        require(recipient != address(this), "RenERC20: can't transfer to token address");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // Disallow sending tokens to the ERC20 contract address (see comment
        // in `transfer`).
        require(recipient != address(this), "RenERC20: can't transfer to token address");
        return super.transferFrom(sender, recipient, amount);
    }
}