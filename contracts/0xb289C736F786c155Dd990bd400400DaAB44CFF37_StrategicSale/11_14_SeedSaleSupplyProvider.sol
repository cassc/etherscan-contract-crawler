// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract SeedSaleSupplyProvider is ERC165 {
    /**
     * @notice Reduces the available token supply of the sale
     * @param _tokens, amount of $SPAACE reserved
     */
    function reduceSupply(uint128 _tokens) external virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(SeedSaleSupplyProvider).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}