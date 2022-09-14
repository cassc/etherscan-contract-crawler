pragma solidity ^0.8.17;

import "./IBEP20.sol";

// SPDX-License-Identifier: MIT
interface IBEP20MetaData is IBEP20 {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
}