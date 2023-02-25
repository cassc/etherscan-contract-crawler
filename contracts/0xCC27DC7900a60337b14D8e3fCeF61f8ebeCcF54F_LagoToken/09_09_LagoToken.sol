// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interface/ILagoAccess.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @dev error for unauthorized transfers
error NotAllowed();

/// @dev ERC20 for LagoToken supporting allow & deny lists
contract LagoToken is ERC20Upgradeable, OwnableUpgradeable {
    /// @param current the new LagoAccess address
    /// @param previous the previous LagoAccess address
    /// @dev logged when updating LagoAccess contract
    event LagoAccessUpdated(address current, address previous);

    /// @dev the LagoAccess contract, use for allow/deny lists.
    ILagoAccess public lagoAccess;

    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        address tokenHolder_,
        uint256 supply_,
        ILagoAccess lagoAccess_
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();

        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        ERC20Upgradeable.__ERC20_init(name_, symbol_);

        _mint(tokenHolder_, supply_);

        _updateLagoAccess(lagoAccess_);
    }

    /// @dev revert if from/to is not allowed
    modifier enforceLagoAccess(address from, address to) {
        if (address(lagoAccess) != address(0)) {
            if (!lagoAccess.isAllowed(from, to)) {
                revert NotAllowed();
            }
        }
        _;
    }

    /// @inheritdoc ERC20Upgradeable
    /// @dev enforces that the `to` address is permitted via `LagoAccess`
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
        enforceLagoAccess(from, to)
    {}

    /// update the LagoAccess contract (external version)
    /// @param lagoAccess_ new LagoAccess contract
    /// @dev sets the `lagoAccess` state variable. Restricted by `onlyOwner`.
    function updateLagoAccess(ILagoAccess lagoAccess_) external onlyOwner {
        _updateLagoAccess(lagoAccess_);
    }

    /// update the LagoAccess contract (internal version)
    /// @param lagoAccess_ new LagoAccess contract
    /// @dev sets the `lagoAccess` state variable. Internal use only.
    function _updateLagoAccess(ILagoAccess lagoAccess_) internal {
        emit LagoAccessUpdated(address(lagoAccess_), address(lagoAccess));
        lagoAccess = lagoAccess_;
    }
}