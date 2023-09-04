// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interfaces/IERC721.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";

contract MultipleTransfer {
    using SafeMath for uint256;

    function transfer(
        address[] memory tokens,
        address[] memory tos,
        uint256[] memory amounts
    ) external {
        for (uint256 i = 0; i < tos.length; i++) {
            TransferHelper.safeTransferFrom(
                tokens[i],
                msg.sender,
                tos[i],
                amounts[i]
            );
        }
    }

    function transferByTokenAmount(
        address token,
        address[] memory tos,
        uint256 amount
    ) external {
        for (uint256 i = 0; i < tos.length; i++) {
            TransferHelper.safeTransferFrom(token, msg.sender, tos[i], amount);
        }
    }

    function transferByToken(
        address token,
        address[] memory tos,
        uint256[] memory amounts
    ) external {
        for (uint256 i = 0; i < tos.length; i++) {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                tos[i],
                amounts[i]
            );
        }
    }

    function transferEth(
        address[] memory tos,
        uint256[] memory amounts
    ) external payable {
        uint256 maxAmount = msg.value;
        uint256 current;
        for (uint256 i = 0; i < tos.length; i++) {
            current = current.add(amounts[i]);
            require(maxAmount > current, "Min Amount");
            TransferHelper.safeTransferETH(tos[i], amounts[i]);
        }
        if (current < maxAmount) {
            TransferHelper.safeTransferETH(msg.sender, maxAmount - current);
        }
    }

    function transferEthByAmount(
        address[] memory tos,
        uint256 amount
    ) external payable {
        uint256 maxAmount = msg.value;
        uint256 current;
        for (uint256 i = 0; i < tos.length; i++) {
            current = current.add(amount);
            require(maxAmount >= current, "Min Amount");
            TransferHelper.safeTransferETH(tos[i], amount);
        }
        if (current < maxAmount) {
            TransferHelper.safeTransferETH(msg.sender, maxAmount - current);
        }
    }

    function transferNft(
        address token,
        address[] memory tos,
        uint256[] memory tokenIds
    ) external {
        for (uint256 i = 0; i < tos.length; i++) {
            IERC721(token).transferFrom(msg.sender, tos[i], tokenIds[i]);
        }
    }

    function transferNftByTo(
        address token,
        address to,
        uint256[] memory tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).transferFrom(msg.sender, to, tokenIds[i]);
        }
    }
}