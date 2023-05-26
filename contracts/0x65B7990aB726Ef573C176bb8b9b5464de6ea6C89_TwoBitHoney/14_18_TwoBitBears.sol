// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interfaces/IBearDetail.sol";

/// Represents a deployed TwoBitBears contract
abstract contract TwoBitBears is IBearDetail, IERC721Enumerable {

    /// The only public non-interface function declared usable for any caller
    /// @dev This call will fail for the official mainnet contract because TwoBitBears are sold out
    function createBear(uint256 quantity) public payable virtual;
}