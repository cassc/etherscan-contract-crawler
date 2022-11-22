// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import "./facets/DiamondCutAndLoupeFacet.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract DaoDonDiamond is Ownable {
    constructor(
        string memory baseTokenURI,
        address multisigWallet,
        address daodonCardAddress,
        address _diamondCutAndLoupeFacetAddress,
        address methodsExposureFacetAddress
    ) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = baseTokenURI;
        _as.royaltiesBasisPoints = 650;
        _as.royaltiesRecipient = multisigWallet;
        _as.maxSupply = 885;
        _as.daodonCardAddress = daodonCardAddress; //0xf0873Dea4a3d2D08586F0Dd94fa5cd2d1A28EC01;
        _as.methodsExposureFacetAddress = methodsExposureFacetAddress;
        _as.seaportAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Upgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721MetadataUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC2981).interfaceId] = true;

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = DiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = DiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = DiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = DiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = DiamondCutAndLoupeFacet.facetAddress.selector;
        selectors[5] = DiamondCutAndLoupeFacet.supportsInterface.selector;

        LibDiamond.addFunctions(_diamondCutAndLoupeFacetAddress, selectors);
    }

    function implementation() public view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.methodsExposureFacetAddress;
    }

    // =========== Lifecycle ===========

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // To learn more about this implementation read EIP 2535
    fallback() external payable {
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}