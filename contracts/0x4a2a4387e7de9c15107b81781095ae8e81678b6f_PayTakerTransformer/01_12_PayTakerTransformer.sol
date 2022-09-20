// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0xPlasma/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0xPlasma/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0xPlasma/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0xPlasma/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";


/// @dev A transformer that transfers tokens to the taker.
contract PayTakerTransformer is
    Transformer
{
    // solhint-disable no-empty-blocks
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // The tokens to transfer to the taker.
        IERC20TokenV06[] tokens;
        // Amount of each token in `tokens` to transfer to the taker.
        // `uint(-1)` will transfer the entire balance.
        uint256[] amounts;
    }

    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Create this contract.
    constructor()
        public
        Transformer()
    {}

    /// @dev Forwards tokens to the taker.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context)
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(context.data, (TransformData));

        // Transfer tokens directly to the taker.
        for (uint256 i = 0; i < data.tokens.length; ++i) {
            // The `amounts` array can be shorter than the `tokens` array.
            // Missing elements are treated as `uint256(-1)`.
            uint256 amount = data.amounts.length > i ? data.amounts[i] : uint256(-1);
            if (amount == MAX_UINT256) {
                amount = data.tokens[i].getTokenBalanceOf(address(this));
            }
            if (amount != 0) {
                data.tokens[i].transformerTransfer(context.recipient, amount);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}