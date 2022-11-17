// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
interface WaverContractCheck {
    function whiteListedAddresses(address _contract) external view returns (uint);
}

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }
    //event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    struct DiamondStorage {
        address waveAddress;
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(address => bool) connectedApps;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    error DIAMOND_ACTION_NOT_FOUND();
     // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            DiamondStorage storage ds = diamondStorage();
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
                ds.connectedApps[_diamondCut[facetIndex].facetAddress] = true;
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                ds.connectedApps[ds.facetAddressAndSelectorPosition[_diamondCut[facetIndex].functionSelectors[0]].facetAddress] = false;
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert DIAMOND_ACTION_NOT_FOUND();
            }
        }
        //emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
    error FUNCTION_SELECTORS_CANNOT_BE_EMPTY();
    error FACET_ADDRESS_CANNOT_BE_EMPTY();
    error FACET_ALREADY_EXISTS();
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
        enforceContractIsWhitelisted(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        if (_facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
        enforceHasContractCode(_facetAddress,"");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this));
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0);
        } else {
            require(_calldata.length > 0);
            if (_init != address(this)) {
                enforceHasContractCode(_init,"");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert();
                }
            }
        }
    }

    error CONTRACT_NOT_WHITELISTED(address contractAddress);

    function enforceContractIsWhitelisted(address contractAddress) internal view {
        DiamondStorage storage ds = diamondStorage();
        WaverContractCheck _wavercContract = WaverContractCheck(ds.waveAddress);
        if (_wavercContract.whiteListedAddresses(contractAddress) == 0) {
            revert CONTRACT_NOT_WHITELISTED(contractAddress);
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