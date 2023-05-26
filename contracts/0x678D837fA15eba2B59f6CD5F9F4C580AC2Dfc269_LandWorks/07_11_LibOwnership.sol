// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./LibDiamond.sol";

library LibOwnership {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        address previousOwner = ds.contractOwner;
        require(previousOwner != _newOwner, "Previous owner and new owner must be different");

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamond.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == LibDiamond.diamondStorage().contractOwner, "Must be contract owner");
    }
}