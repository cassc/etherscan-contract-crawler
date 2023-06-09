// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// inherited contracts
import {BaseOptionsVault} from "./BaseOptionsVault.sol";

// interfaces
import {IMarginEngineCash} from "../../../../interfaces/IMarginEngine.sol";

// libraries
import {StructureLib} from "../../../../libraries/StructureLib.sol";

import "../../../../config/errors.sol";
import "../../../../config/types.sol";

abstract contract CashOptionsVault is BaseOptionsVault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice marginAccount is the options protocol collateral pool
    IMarginEngineCash public immutable marginEngine;

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) BaseOptionsVault(_share) {
        if (_marginEngine == address(0)) revert BadAddress();

        marginEngine = IMarginEngineCash(_marginEngine);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function overrides
    //////////////////////////////////////////////////////////////*/

    function _getMarginAccount()
        internal
        view
        virtual
        override
        returns (Position[] memory, Position[] memory, Balance[] memory)
    {
        return marginEngine.marginAccounts(address(this));
    }

    function _setAuctionMarginAccountAccess(uint256 _allowedExecutions) internal virtual override {
        marginEngine.setAccountAccess(auction, _allowedExecutions);
    }

    function _marginEngineAddr() internal view virtual override returns (address) {
        return address(marginEngine);
    }

    function _settleOptions() internal virtual override {
        StructureLib.settleOptions(marginEngine);
    }

    function _withdrawCollateral(Collateral[] memory _collaterals, uint256[] memory _amounts, address _recipient)
        internal
        virtual
        override
    {
        StructureLib.withdrawCollaterals(marginEngine, _collaterals, _amounts, _recipient);
    }

    function _depositCollateral(Collateral[] memory _collaterals) internal virtual override {
        StructureLib.depositCollateral(marginEngine, _collaterals);
    }

    function _withdrawWithShares(uint256 _totalSupply, uint256 _shares, address _pauser)
        internal
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return StructureLib.withdrawWithShares(marginEngine, _totalSupply, _shares, _pauser);
    }
}