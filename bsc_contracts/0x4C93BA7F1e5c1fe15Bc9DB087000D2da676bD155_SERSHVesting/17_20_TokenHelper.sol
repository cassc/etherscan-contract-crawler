// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TokenHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TokenHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TokenHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TokenHelper::transferFrom: transferFrom failed");
    }

    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call{value: value}(new bytes(0));
    //     require(success, "TokenHelper::safeTransferETH: ETH transfer failed");
    // }

    // function safeTransferAsset(
    //     address token,
    //     address to,
    //     uint256 value
    // ) internal {
    //     if (token == address(0)) {
    //         safeTransferETH(to, value);
    //     } else {
    //         safeTransfer(token, to, value);
    //     }
    // }

    // function safeNFTApproveForAll(
    //     address nft,
    //     address operator,
    //     bool approved
    // ) internal {
    //     // bytes4(keccak256(bytes('setApprovalForAll(address,bool)')));
    //     (bool success, ) = nft.call(abi.encodeWithSelector(0xa22cb465, operator, approved));
    //     require(success, "TokenHelper::safeNFTApproveForAll: Failed");
    // }

    // function safeTransferNFT(
    //     address _nft,
    //     address _from,
    //     address _to,
    //     bool isERC721,
    //     uint256 _tokenId
    // ) internal {
    //     if (isERC721) {
    //         IERC721(_nft).safeTransferFrom(_from, _to, _tokenId);
    //     } else {
    //         IERC1155(_nft).safeTransferFrom(_from, _to, _tokenId, 1, "0x00");
    //     }
    // }

    /**
     * @dev this function calculates expected price of NFT based on created LTV and fund amount,
     * LTV: 10000 = 100%; _slippage: 10000 = 100%
     */
    // function getExpectedPrice(
    //     uint256 _fundAmount,
    //     uint256 _percentage,
    //     uint256 _slippage
    // ) internal pure returns (uint256) {
    //     require(_percentage != 0, "TokenHelper: percentage should not be 0");
    //     return (_fundAmount * (10000 + _slippage)) / _percentage;
    // }
}