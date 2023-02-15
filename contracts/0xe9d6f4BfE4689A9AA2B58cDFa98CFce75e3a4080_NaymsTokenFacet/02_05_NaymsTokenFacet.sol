// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { INaymsTokenFacet } from "../interfaces/INaymsTokenFacet.sol";
import { LibNaymsToken } from "../libs/LibNaymsToken.sol";

/**
 * @title Nayms token facet.
 * @notice Use it to access and manipulate Nayms token.
 * @dev Use it to access and manipulate Nayms token.
 */
contract NaymsTokenFacet is INaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256) {
        return LibNaymsToken._totalSupply();
    }

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balanceOf(address addr) external view returns (uint256) {
        return LibNaymsToken._balanceOf(addr);
    }
}