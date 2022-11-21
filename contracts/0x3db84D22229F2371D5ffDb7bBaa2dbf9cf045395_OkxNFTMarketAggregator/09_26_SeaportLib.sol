// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {TradeType} from "./TradeType.sol";
import "../../common/TokenTransferrerConstants.sol";


library SeaportLib {

    using SafeERC20 for IERC20;

    //conduit 0x1E0049783F008A0085193E00003D00cd54003c71;
    address constant private OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;

    //opensea seaport 0x00000000006c3852cbEf3e08E8dF289169EdE581
    address constant private OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;


    function buyAssetForETH(
        bytes memory _calldata,
        uint256 payAmount
    ) internal {
        address payable seaport = payable(
            OPENSEA_SEAPORT
        );
        (bool success, ) =  seaport.call{value: payAmount}(_calldata);

        require(success, "Seaport buy failed");
    }


    function buyAssetForERC20(
        bytes memory _calldata,
        address payToken,
        uint256 payAmount
    )internal {
        IERC20(payToken).safeTransferFrom(msg.sender,
            address(this),
            payAmount
        );
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, payAmount);
        //IERC721(tokenAddress).setApprovalForAll(address(0x1E0049783F008A0085193E00003D00cd54003c71),true);
        address payable seaport = payable(
            OPENSEA_SEAPORT
        );

        (bool success, ) =  seaport.call(_calldata);

        require(success, "Seaport buy failed");
        // revoke approval
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, 0);
    }


    function takeOfferForERC20(
        bytes memory _calldata,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 tradeType
    ) internal {

        address payable seaport = payable(
            OPENSEA_SEAPORT
        );

        _tranferNFT(tokenAddress, msg.sender, address(this), tokenId, amount,TradeType(tradeType));
        // both ERC721 and ERC1155 share the same `setApprovalForAll` method.
        IERC721(tokenAddress).setApprovalForAll(OPENSEA_CONDUIT, true);
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, type(uint256).max);

        (bool success, ) = seaport.call(_calldata);

        require(success, "Seaport accept offer failed");

        SafeERC20.safeTransfer(
            IERC20(payToken),
            msg.sender,
            IERC20(payToken).balanceOf(address(this))
        );

        // revoke approval.
        IERC721(tokenAddress).setApprovalForAll(OPENSEA_CONDUIT, false);
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, 0);

    }

    function _tranferNFT(
        address tokenAddress,
        address from,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        TradeType tradeType
    ) internal {

        if (TradeType.ERC1155 == tradeType) {
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId,
                amount,
                ""
            );
        }else if (TradeType.ERC721 == tradeType) {
/*            IERC721(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId
            );*/

            _performERC721Transfer(tokenAddress,from,recipient,tokenId);
        } else {
            revert("Unsupported interface");
        }
    }

    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal {
        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
        // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

        // The free memory pointer memory slot will be used when populating
        // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

        // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

        // Perform the call, ignoring return data.
            let success := call(
            gas(),
            token,
            0,
            ERC721_transferFrom_sig_ptr,
            ERC721_transferFrom_length,
            0,
            0
            )

        // If the transfer reverted:
            if iszero(success) {
            // If it returned a message, bubble it up as long as sufficient
            // gas remains to do so:
                if returndatasize() {
                // Ensure that sufficient gas is available to copy
                // returndata while expanding memory where necessary. Start
                // by computing word size of returndata & allocated memory.
                // Round up to the nearest full word.
                    let returnDataWords := div(
                    add(returndatasize(), AlmostOneWord),
                    OneWord
                    )

                // Note: use the free memory pointer in place of msize() to
                // work around a Yul warning that prevents accessing msize
                // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                        cost,
                        add(
                        mul(
                        sub(returnDataWords, msizeWords),
                        CostPerWord
                        ),
                        div(
                        sub(
                        mul(returnDataWords, returnDataWords),
                        mul(msizeWords, msizeWords)
                        ),
                        MemoryExpansionCoefficient
                        )
                        )
                        )
                    }

                // Finally, add a small constant and compare to gas
                // remaining; bubble up the revert data if enough gas is
                // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                    // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

            // Otherwise revert with a generic error message.
                mstore(
                TokenTransferGenericFailure_error_sig_ptr,
                TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                TokenTransferGenericFailure_error_sig_ptr,
                TokenTransferGenericFailure_error_length
                )
            }

        // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

        // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

}