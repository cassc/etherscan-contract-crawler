// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface IMinter is IAllowList, IAnnotated {
    event SetTokens(address oldTokens, address newTokens);

    /// @notice Mint `amount` tokens with ID `id` to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}