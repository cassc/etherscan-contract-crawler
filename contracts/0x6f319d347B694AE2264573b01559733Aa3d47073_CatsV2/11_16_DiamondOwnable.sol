//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { ACLStorage } from "./ACLStorage.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

abstract contract DiamondOwnable is IERC173 {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() public view returns (address) {
        return LibDiamond.contractOwner();
    }

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external onlyOwner {
        LibDiamond.setContractOwner(account);
    }
}