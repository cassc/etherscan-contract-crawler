// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable RestrictApprove with contract-allow-list
 * @author 0xedy
 * 
 */

import "../AntiScamInitializable.sol";
import "./storage/RestrictApproveStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/IERC721RestrictApprove.sol";
import "../AntiScamAbstract.sol";

abstract contract RestrictApprove is AntiScamAbstract, AntiScamInitializable, IERC721RestrictApprove {
    using RestrictApproveStorage for RestrictApproveStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override {
        RestrictApproveStorage.layout().CALLevel = 1;
        RestrictApproveStorage.layout().restrictEnabled = true;
    }
    */
    function __RestrictApprove_init() internal onlyInitializingAntiScam {
        __RestrictApprove_init_unchained();
    }

    function __RestrictApprove_init_unchained() internal onlyInitializingAntiScam {
        RestrictApproveStorage.layout().CALLevel = 1;
        RestrictApproveStorage.layout().restrictEnabled = true;
    }

    // =============================================================
    //                        IERC721RestrictApprove
    // =============================================================
    function CAL() public view virtual  returns (IContractAllowListProxy) {
        return RestrictApproveStorage.layout().CAL;
    }

    function CALLevel() public view virtual  returns (uint256) {
        return RestrictApproveStorage.layout().CALLevel;
    }

    function restrictEnabled() public view virtual returns (bool) {
        return RestrictApproveStorage.layout().restrictEnabled;
    }

    // =============================================================
    //                        Internal setter functions
    // =============================================================
    function _addLocalContractAllowList(address transferer)
        internal
        virtual
    {
        RestrictApproveStorage.layout().localAllowedAddresses.add(transferer);
        emit LocalCalAdded(msg.sender, transferer);
    }

    function _removeLocalContractAllowList(address transferer)
        internal
        virtual
    {
        RestrictApproveStorage.layout().localAllowedAddresses.remove(transferer);
        emit LocalCalRemoved(msg.sender, transferer);
    }

    function _setCALLevel(uint256 value)
        internal
        virtual
    {
        RestrictApproveStorage.layout().CALLevel = value;
        emit CalLevelChanged(msg.sender, value);
    }

    function _setCAL(address calAddress)
        internal
        virtual
    {
        RestrictApproveStorage.layout().CAL = IContractAllowListProxy(calAddress);
    }

    function _setRestrictEnabled(bool enabled)
        internal
        virtual
    {
        RestrictApproveStorage.layout().restrictEnabled = enabled;
    }
    // =============================================================
    //                        IERC721RestrictApprove
    // =============================================================
    function getLocalContractAllowList()
        public
        virtual
        view
        returns(address[] memory)
    {
        return RestrictApproveStorage.layout().localAllowedAddresses.values();
    }

    // =============================================================
    //                        Allowed status
    // =============================================================
    function isLocalAllowed(address transferer)
        public
        view
        virtual
        returns (bool)
    {
        return RestrictApproveStorage.layout().localAllowedAddresses.contains(transferer);
    }

    function isAllowed(address transferer)
        public
        view
        virtual
        returns (bool)
    {
        if (!RestrictApproveStorage.layout().restrictEnabled) {
            return true;
        }

        return isLocalAllowed(transferer) || RestrictApproveStorage.layout().CAL.isAllowed(
                transferer, 
                RestrictApproveStorage.layout().CALLevel
        );
    }

    // =============================================================
    //      AntiScam Approve logic function
    // =============================================================

    function _isTokenApprovable(address transferer, uint256 /*tokenId*/)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return isAllowed(transferer);
    }

    function _isWalletApprovable(address transferer, address /*holder*/)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return isAllowed(transferer);
    }

}