// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/INFTransfersFeature.sol";
import "../../fixins/FixinERC721Spender.sol";

contract NFTransfersFeature is INFTransfersFeature, FixinERC721Spender {

    using Address for address;

    function transferItems(address to, TransferItem[] calldata items) external override {
        unchecked {
            address from = msg.sender;
            uint256 length = items.length;
            if (to.isContract()) {
                for (uint256 i = 0; i < length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            _safeTransferERC721AssetFrom(token, from, to, ids[j]);
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        IERC1155(item.token).safeBatchTransferFrom(from, to, item.ids, item.amounts, "");
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            } else {
                for (uint256 i = 0; i < length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            _transferERC721AssetFrom(token, from, to, ids[j]);
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        IERC1155(item.token).safeBatchTransferFrom(from, to, item.ids, item.amounts, "");
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            }
        }
    }

    function transferERC721s(address to, address[] calldata tokens, uint256[][] calldata tokenIds) external override {
        uint256 length = tokens.length;
        require(length == tokenIds.length, "ARRAY_LENGTH_MISMATCH");

        unchecked {
            address from = msg.sender;
            if (to.isContract()) {
                for (uint256 i = 0; i < length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        _safeTransferERC721AssetFrom(token, from, to, ids[j]);
                    }
                }
            } else {
                for (uint256 i = 0; i < length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        _transferERC721AssetFrom(token, from, to, ids[j]);
                    }
                }
            }
        }
    }
}