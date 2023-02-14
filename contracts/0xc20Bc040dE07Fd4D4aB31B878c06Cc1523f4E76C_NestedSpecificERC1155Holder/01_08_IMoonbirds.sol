// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
@dev A minimal interface for interaction with the Moonbirds contract.
 */
interface IMoonbirds is IERC721 {
    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        );
}