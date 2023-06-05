// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IERC721A } from "erc721a/contracts/ERC721A.sol";

interface IERC721AMintable is IERC721A {
    /// @notice Mints a `amount` of tokens and assigns them to `to`.
    /// @param to Address of the receiver.
    /// @param amount Amount of the tokens to mint.
    function mint(address to, uint256 amount) external;
}