// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract EarlySaleReceiver is ERC165 {
    /**
     * @notice Deposits a previous purchase (buy order) of $SPAACE
     * @param _investor, address of the investor
     * @param _eth, amount of ETH spent
     * @param _tokens, amount of $SPAACE reserved
     */
    function earlyDeposit(
        address _investor,
        uint128 _eth,
        uint128 _tokens
    ) external virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(EarlySaleReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}