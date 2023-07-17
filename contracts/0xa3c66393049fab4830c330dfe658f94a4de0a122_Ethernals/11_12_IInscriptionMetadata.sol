// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IInscription.sol";

interface IInscriptionMetadata is IInscription {
    /**
     * @dev Returns the inscription name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the inscription symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `inscriptionId` inscription.
     */
    function tokenURI(uint256 inscriptionId) external view returns (string memory);

    /**
     * @dev Returns the Inscription Uniform Resource Locator (URL) for `inscriptionId` inscription.
     */
    function inscriptionURL(uint256 inscriptionId) external view returns (string memory);
}