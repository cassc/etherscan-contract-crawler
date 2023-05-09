// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import { IERC165 } from "./IERC165.sol";
import { IERC20Metadata } from "../../common/interfaces/IERC20Metadata.sol";

/**
 * @dev Interface of the Omnichain ERC20 standard
 */
interface IOERC20 is IERC165, IERC20Metadata {
    /**
     * @dev send _amount amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * @param _bridgeAddress - the Ax-assigned bridge ID, which dictates the message passing protocol to use
     * @param _from - the owner of token
     * @param _dstChainId - the destination chain identifier
     * @param _toAddress - can be any size depending on the `dstChainId`
     * @param _amount - the quantity of tokens in wei
     */
    function sendFrom(
        address _bridgeAddress,
        address payable _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount
    ) external payable returns (uint64 sequence);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);
}