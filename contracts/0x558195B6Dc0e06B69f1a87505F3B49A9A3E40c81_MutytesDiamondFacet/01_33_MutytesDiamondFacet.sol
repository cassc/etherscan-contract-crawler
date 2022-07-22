// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Diamond } from "../../diamond/Diamond.sol";
import { IDiamondWritable } from "../../diamond/writable/IDiamondWritable.sol";
import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { IERC165 } from "../../core/introspection/IERC165.sol";
import { IERC721 } from "../../core/token/ERC721/IERC721.sol";

bytes constant DIAMOND_SELECTORS = abi.encode(1, IDiamondWritable.diamondCut.selector);
bytes constant ERC165_SELECTORS = abi.encode(1, IERC165.supportsInterface.selector);
bytes constant SUPPORTED_INTERFACES = abi.encode(
    2,
    type(IERC165).interfaceId,
    type(IERC721).interfaceId
);

/**
 * @title Mutytes diamond facet
 */
contract MutytesDiamondFacet is Diamond, ERC165Controller {
    /**
     * @notice Initialize the diamond proxy
     * @param facetAddress The diamond facet address
     */
    function init(address facetAddress) external virtual onlyOwner {
        FacetCut[] memory facetCuts = new FacetCut[](2);
        facetCuts[0] = FacetCut(facetAddress, FacetCutAction.Add, _diamodSelectors());
        facetCuts[1] = FacetCut(address(this), FacetCutAction.Add, _erc165Selectors());
        _setSupportedInterfaces(_supportedInterfaces(), true);
        diamondCut_(facetCuts, address(0), "");
    }

    function _diamodSelectors()
        internal
        pure
        virtual
        returns (bytes4[] memory selectors)
    {
        return _ptrToBytes4Array(DIAMOND_SELECTORS);
    }

    function _erc165Selectors()
        internal
        pure
        virtual
        returns (bytes4[] memory selectors)
    {
        return _ptrToBytes4Array(ERC165_SELECTORS);
    }

    function _supportedInterfaces() internal pure virtual returns (bytes4[] memory) {
        return _ptrToBytes4Array(SUPPORTED_INTERFACES);
    }

    function _ptrToBytes4Array(bytes memory ptr)
        private
        pure
        returns (bytes4[] memory selectors)
    {
        assembly {
            selectors := add(ptr, 0x20)
        }
    }
}