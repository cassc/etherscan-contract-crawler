// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LibDiamond.sol";

abstract contract BaseFacet {
    LibDiamond.AppStorage internal s;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(LibDiamond.isContractOwner(), "Ownable: caller is not the owner");
        _;
    }

}