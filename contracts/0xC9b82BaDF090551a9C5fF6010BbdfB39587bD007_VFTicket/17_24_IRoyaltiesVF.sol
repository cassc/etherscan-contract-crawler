// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltiesVF {
    /**
     * @dev Update the access control contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `controlContractAddress` must support the IVFAccesControl interface
     */
    function setControlContract(address controlContractAddress) external;

    /**
     * @dev Get royalty information for a contract based on the `salePrice` of a token
     */
    function royaltyInfo(
        uint256,
        address contractAddress,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external;

    /**
     * @dev Sets the royalty information for `contractAddress`.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setContractRoyalties(
        address contractAddress,
        address receiver,
        uint96 feeNumerator
    ) external;

    /**
     * @dev Removes royalty information for `contractAddress`.
     */
    function resetContractRoyalty(address contractAddress) external;
}