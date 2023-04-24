// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Permissions.sol";
import "./ICore.sol";
import "../chi/Chi.sol";
import "../zen/Zen.sol";

/// @title Source of truth for Essence Finance
/// @notice maintains roles, access control, CHI, ZEN, and the ZEN treasury
contract Core is ICore, Permissions, Initializable {
    /// @notice the address of the CHI contract
    IChi public override chi;

    /// @notice the address of the ZEN contract
    IERC20 public override zen;

    function init() external override initializer {
        _setupGovernor(msg.sender);

        Chi _chi = new Chi(address(this));
        _setChi(address(_chi));

        // Zen _zen = new Zen(address(this), msg.sender);
        // _setZen(address(_zen));
    }

    /// @notice sets CHI address to a new address
    /// @param token new chi address
    function setChi(address token) external override onlyGovernor {
        _setChi(token);
    }

    /// @notice sets ZEN address to a new address
    /// @param token new zen address
    function setZen(address token) external override onlyGovernor {
        _setZen(token);
    }

    /// @notice sends ZEN tokens from treasury to an address
    /// @param to the address to send ZEN to
    /// @param amount the amount of ZEN to send
    function allocateZen(address to, uint256 amount) external override onlyGovernor {
        IERC20 _zen = zen;
        require(_zen.balanceOf(address(this)) >= amount, "Core: Not enough Zen");

        _zen.transfer(to, amount);

        emit ZenAllocation(to, amount);
    }

    function _setChi(address token) internal {
        chi = IChi(token);
        emit ChiUpdate(token);
    }

    function _setZen(address token) internal {
        zen = IERC20(token);
        emit ZenUpdate(token);
    }
}