// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {TradeType} from "./TradeType.sol";


library OKXSeaportLib {

    using SafeERC20 for IERC20;

    address constant private OKX_CONDUIT = 0x97cf28FfEcBACC60E2b6983d3508d4F3c9A3207d;

    address constant private OKX_SEAPORT = 0x90A77DD8AE0525e08b1C2930eb2Eb650E78c6725;

    function buyAssetForETH (
        bytes memory _calldata,
        uint256 payAmount
    ) internal {
        address payable seaport = payable(
            OKX_SEAPORT
        );
        (bool success, ) =  seaport.call{value: payAmount}(_calldata);

        require(success, "Seaport buy failed");
    }


    function buyAssetForERC20(
        bytes memory _calldata,
        address payToken,
        uint256 payAmount
    ) internal {
        IERC20(payToken).safeTransferFrom(msg.sender,
            address(this),
            payAmount
        );
        IERC20(payToken).safeApprove(OKX_CONDUIT, payAmount);
        //IERC721(tokenAddress).setApprovalForAll(address(0x1E0049783F008A0085193E00003D00cd54003c71),true);
        address payable seaport = payable(
            OKX_SEAPORT
        );

        (bool success, ) =  seaport.call(_calldata);
        require(success, "Seaport buy failed");
        // revoke approval
        IERC20(payToken).safeApprove(OKX_CONDUIT, 0);
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
            OKX_SEAPORT
        );

        _tranferNFT(tokenAddress, msg.sender, address(this), tokenId, amount,TradeType(tradeType));

        // both ERC721 and ERC1155 share the same `setApprovalForAll` method.
        IERC721(tokenAddress).setApprovalForAll(OKX_CONDUIT, true);
        IERC20(payToken).safeApprove(OKX_CONDUIT, type(uint256).max);

        (bool success, ) = seaport.call(_calldata);

        require(success, "Seaport accept offer failed");

        SafeERC20.safeTransfer(
            IERC20(payToken),
            msg.sender,
            IERC20(payToken).balanceOf(address(this))
        );

        // revoke approval.
        IERC721(tokenAddress).setApprovalForAll(OKX_CONDUIT, false);
        IERC20(payToken).safeApprove(OKX_CONDUIT, 0);

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
            IERC721(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId
            );
        } else {
            revert("Unsupported interface");
        }
    }

}