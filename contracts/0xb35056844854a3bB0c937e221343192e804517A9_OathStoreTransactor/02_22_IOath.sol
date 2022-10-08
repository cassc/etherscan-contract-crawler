// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../erc1238/IERC1238.sol";

/**

Faction Names:
    1- Toar
    2- Genn
    3- Dalar
    4- Kuzal
    5- Vettiri

 */
interface IOath is IERC1238 {
    function MINTER_ROLE() external view returns (bytes32);

    function PAUSER_ROLE() external view returns (bytes32);

    function TOTAL_MAX_PER_ADDRESS() external view returns (uint256);

    function MAX_FACTION_ID() external view returns (uint256);

    function totalBalanceOf(address account) external view returns (uint256);

    function totalSupplyOf(uint256 id) external view returns (uint256);

    function setBaseURI(string calldata newBaseURI) external;

    function mint(
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function burn(uint256 id) external;

    function totalSupply() external view returns (uint256 total);

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /** Events */

    event BaseURIUpdated(string indexed oldBaseUri, string indexed newBaseUri);
}