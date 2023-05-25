// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenURIGeneratorVF {
    /**
     * @dev Update the access control contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `controlContractAddress` must support the IVFAccesControl interface
     */
    function setControlContract(address controlContractAddress) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}