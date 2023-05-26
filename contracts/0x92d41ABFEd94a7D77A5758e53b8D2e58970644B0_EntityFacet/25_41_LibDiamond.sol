// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IACLFacet } from "src/diamonds/nayms/interfaces/IACLFacet.sol";
import { IGovernanceFacet } from "src/diamonds/nayms/interfaces/IGovernanceFacet.sol";
import { AppStorage, LibAppStorage } from "src/diamonds/nayms/AppStorage.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibAdmin } from "src/diamonds/nayms/libs/LibAdmin.sol";
import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] diamondCut, address init, bytes _calldata);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function setRoleGroupsAndAssigners() internal {
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_ENTITY_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_ENTITY_MANAGERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_BROKERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_UNDERWRITERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_INSURED_PARTIES, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_CAPITAL_PROVIDERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_CLAIMS_ADMINS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_TRADER, LibConstants.GROUP_TRADERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SEGREGATED_ACCOUNTS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SERVICE_PROVIDERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_POLICY_HANDLERS, true);
        LibACL._updateRoleGroup(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_POLICY_HANDLERS, true);

        LibACL._updateRoleAssigner(LibConstants.ROLE_SYSTEM_ADMIN, LibConstants.GROUP_SYSTEM_ADMINS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SYSTEM_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_ENTITY_MANAGER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_UNDERWRITER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_INSURED_PARTY, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_CAPITAL_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_CLAIMS_ADMIN, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_TRADER, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SEGREGATED_ACCOUNT, LibConstants.GROUP_SYSTEM_MANAGERS);
        LibACL._updateRoleAssigner(LibConstants.ROLE_SERVICE_PROVIDER, LibConstants.GROUP_SYSTEM_MANAGERS);
    }

    function setSystemAdmin(address _newSystemAdmin) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 userId = LibHelpers._getIdForAddress(_newSystemAdmin);
        s.existingObjects[userId] = true;

        LibACL._assignRole(userId, LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN));
    }

    function setUpgradeExpiration() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        /// @dev We set the upgrade expiration to 7 days from now (604800 seconds)
        s.upgradeExpiration = 1 weeks;
    }

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet,
        address _aclFacet,
        address _governanceFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({ facetAddress: _diamondLoupeFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({ facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](10);
        functionSelectors[0] = IACLFacet.assignRole.selector;
        functionSelectors[1] = IACLFacet.unassignRole.selector;
        functionSelectors[2] = IACLFacet.isInGroup.selector;
        functionSelectors[3] = IACLFacet.isParentInGroup.selector;
        functionSelectors[4] = IACLFacet.canAssign.selector;
        functionSelectors[5] = IACLFacet.getRoleInContext.selector;
        functionSelectors[6] = IACLFacet.isRoleInGroup.selector;
        functionSelectors[7] = IACLFacet.canGroupAssignRole.selector;
        functionSelectors[8] = IACLFacet.updateRoleAssigner.selector;
        functionSelectors[9] = IACLFacet.updateRoleGroup.selector;
        cut[3] = IDiamondCut.FacetCut({ facetAddress: _aclFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](6);
        functionSelectors[0] = IGovernanceFacet.isDiamondInitialized.selector;
        functionSelectors[1] = IGovernanceFacet.createUpgrade.selector;
        functionSelectors[2] = IGovernanceFacet.updateUpgradeExpiration.selector;
        functionSelectors[3] = IGovernanceFacet.cancelUpgrade.selector;
        functionSelectors[4] = IGovernanceFacet.getUpgrade.selector;
        functionSelectors[5] = IGovernanceFacet.getUpgradeExpiration.selector;
        cut[4] = IDiamondCut.FacetCut({ facetAddress: _governanceFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        diamondCut(cut, address(0), "");
    }

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot = (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitializationFunctionReverted(_init, _calldata);
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}