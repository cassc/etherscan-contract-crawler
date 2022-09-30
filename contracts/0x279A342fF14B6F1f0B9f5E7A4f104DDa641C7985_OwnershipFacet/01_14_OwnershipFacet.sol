// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibDiamond} from "../libs/LibDiamond.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";
import {IOwnershipFacet} from "../interfaces/IOwnershipFacet.sol";

/// @title meTokens Ownership Facet
/// @author @cartercarlson, @zgorizzo69, @parv3213
/// @notice This contract provides access control for meTokens Protocol
contract OwnershipFacet is Modifiers, IOwnershipFacet {
    /// @inheritdoc IOwnershipFacet
    function setDiamondController(address newController)
        external
        onlyDiamondController
    {
        _sameAsPreviousError(s.diamondController, newController);
        s.diamondController = newController;
    }

    /// @inheritdoc IOwnershipFacet
    function setTrustedForwarder(address forwarder)
        external
        onlyDiamondController
    {
        _sameAsPreviousError(s.trustedForwarder, forwarder);
        s.trustedForwarder = forwarder;
    }

    /// @inheritdoc IOwnershipFacet
    function setFeesController(address newController)
        external
        onlyFeesController
    {
        _sameAsPreviousError(s.feesController, newController);
        s.feesController = newController;
    }

    /// @inheritdoc IOwnershipFacet
    function setDurationsController(address newController)
        external
        onlyDurationsController
    {
        _sameAsPreviousError(s.durationsController, newController);
        s.durationsController = newController;
    }

    /// @inheritdoc IOwnershipFacet
    function setRegisterController(address newController)
        external
        onlyRegisterController
    {
        _sameAsPreviousError(s.registerController, newController);
        s.registerController = newController;
    }

    /// @inheritdoc IOwnershipFacet
    function setDeactivateController(address newController)
        external
        onlyDeactivateController
    {
        _sameAsPreviousError(s.deactivateController, newController);
        s.deactivateController = newController;
    }

    /// @inheritdoc IOwnershipFacet
    function trustedForwarder() external view returns (address) {
        return s.trustedForwarder;
    }

    /// @inheritdoc IOwnershipFacet
    function diamondController() external view returns (address) {
        return s.diamondController;
    }

    /// @inheritdoc IOwnershipFacet
    function feesController() external view returns (address) {
        return s.feesController;
    }

    /// @inheritdoc IOwnershipFacet
    function durationsController() external view returns (address) {
        return s.durationsController;
    }

    /// @inheritdoc IOwnershipFacet
    function registerController() external view returns (address) {
        return s.registerController;
    }

    /// @inheritdoc IOwnershipFacet
    function deactivateController() external view returns (address) {
        return s.deactivateController;
    }

    function _sameAsPreviousError(address _old, address _new) internal pure {
        require(_old != _new, "same");
    }
}