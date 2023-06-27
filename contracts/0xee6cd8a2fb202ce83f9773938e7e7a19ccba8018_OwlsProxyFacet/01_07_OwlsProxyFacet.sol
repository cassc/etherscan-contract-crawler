// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibOwls } from "../libraries/LibOwls.sol";
import { IOwls } from "../interfaces/IOwls.sol";
import { IOwlDescriptor } from "../interfaces/IOwlDescriptor.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

/**
 * @title OwlsProxyFacet
 * @author CodinCowboy
 * @notice Proxy to enable the diamond to take ownership and proxy ownership 
 *         requests to the Owls Contract. Note: name changes are to ensure the function
 *         hashes do not conflict with other functions in the facets.
 */
contract OwlsProxyFacet {
    function owlsSetMinting(bool value) external {
        LibDiamond.enforceIsContractOwner();
        IOwls(LibOwls.owlsStorage().owlsContract).setMinting(value);
    }

    function owlsUpdateSeed(uint256 tokenId, uint256 seed) external {
        LibDiamond.enforceIsContractOwner();
        IOwls(LibOwls.owlsStorage().owlsContract).updateSeed(tokenId, seed);
    }

    function owlsSetDescriptor(IOwlDescriptor newDescriptor) external {
        LibDiamond.enforceIsContractOwner();
        IOwls(LibOwls.owlsStorage().owlsContract).setDescriptor(newDescriptor);
    }

    function owlsWithdraw() external payable {
        LibDiamond.enforceIsContractOwner();
        IOwls(LibOwls.owlsStorage().owlsContract).withdraw();
    }

    /// @notice function to withdraw the funds from the diamond once owlsWithdraw is called
    function withdraw() external payable {
        LibDiamond.enforceIsContractOwner();
        (bool os,)= payable(LibDiamond.contractOwner()).call{value: address(this).balance}("");
        require(os);
    }

    function owlsDisableSeedUpdate() external {
        LibDiamond.enforceIsContractOwner();
        IOwls(LibOwls.owlsStorage().owlsContract).disableSeedUpdate();
    }

    function owlsTransferOwnership(address newOwner) external {
        LibDiamond.enforceIsContractOwner();
        IERC173(LibOwls.owlsStorage().owlsContract).transferOwnership(newOwner);
    }
}